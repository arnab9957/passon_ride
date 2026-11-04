// ₹10 UPI booking fee: manual UPI Intent + UTR verification by an admin.
//
// Actions (POST JSON { action, ... }, user JWT required):
//   create      { booking_kind, booking_id }        → payment + upi:// intent URI (idempotent)
//   submit_utr  { payment_id, utr }                 → customer submits the 12-digit UPI ref
//   status      { payment_id }                      → current payment row
//   review      { payment_id, decision, reason? }   → ADMIN: 'approve' | 'reject'
//   refund      { payment_id, reason, reference }   → ADMIN: record a manual refund
//   pending     {}                                  → ADMIN: payments awaiting review
//
// The fee amount is decided here, never by the client. A future acquirer
// webhook can call the same `markSuccess` path.
//
// Secrets: UPI_MERCHANT_VPA (e.g. passionride@okhdfcbank), UPI_MERCHANT_NAME (optional).
import { checkScreenshot, ocrImage, sha256Hex } from './screenshot_check.ts';
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { corsHeaders, getUserId, json, requireEnv } from '../_shared/auth.ts';

const BOOKING_FEE = 10; // ₹, non-refundable PassionRide fee (refunded only if the provider rejects)
const KINDS = { vehicle: 'bookings', tour: 'bookings', stay: 'hotel_bookings' } as const;
type Kind = keyof typeof KINDS;

function admin(): SupabaseClient {
  return createClient(requireEnv('SUPABASE_URL'), requireEnv('SUPABASE_SERVICE_ROLE_KEY'), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

async function logEvent(db: SupabaseClient, paymentId: string, type: string, actor: string | null, details = {}) {
  const { error } = await db.from('payment_events').insert({ payment_id: paymentId, event_type: type, actor_id: actor, details });
  if (error) console.error('payment_events insert failed', error.message);
}

const ADMIN_EMAILS = ['passion.ride26@gmail.com', 'passon.ride26@gmail.com', 'admin@passionride.com'];

async function isAdmin(db: SupabaseClient, uid: string): Promise<boolean> {
  // Mirrors AppState.isAdmin: role 'admin' (any case) or an owner email.
  const { data } = await db.from('profiles').select('role').eq('id', uid).maybeSingle();
  if (String(data?.role ?? '').toLowerCase() === 'admin') return true;
  const { data: u } = await db.auth.admin.getUserById(uid);
  const email = (u?.user?.email ?? '').trim().toLowerCase();
  return ADMIN_EMAILS.includes(email);
}

/** All id variants a user's bookings may be stored under (mother/child accounts). */
function idVariants(uid: string): string[] {
  return [uid, `mth_${uid}`];
}

function ownsBooking(row: Record<string, unknown>, uid: string): boolean {
  const ids = new Set(idVariants(uid));
  for (const col of ['user_id', 'rider_id', 'customer_id', 'account_id']) {
    const v = row[col];
    if (typeof v === 'string' && ids.has(v)) return true;
  }
  return false;
}

function upiUri(vpa: string, name: string, ref: string, bookingId: string): string {
  const q = new URLSearchParams({
    pa: vpa,
    pn: name,
    am: BOOKING_FEE.toFixed(2),
    cu: 'INR',
    tr: ref,
    tn: `PassionRide booking ${bookingId}`.slice(0, 50),
  });
  return `upi://pay?${q.toString()}`;
}

async function notify(db: SupabaseClient, userId: string, title: string, message: string, relatedId: string) {
  if (!userId) return;
  await db.from('notifications').insert({
    id: `n_fee_${relatedId}_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
    user_id: userId,
    title,
    message,
    type: 'booking',
    timestamp: new Date().toISOString(),
    is_read: false,
    related_id: relatedId,
    action_nav_index: 19,
  });
}

/** Marks a SUBMITTED payment as paid, confirms the booking and notifies both sides. */
async function confirmPayment(
  db: SupabaseClient,
  p: Record<string, any>,
  actor: string | null,
  method: 'admin' | 'ocr_auto',
) {
  const now = new Date().toISOString();
  const { data: updated, error } = await db
    .from('booking_fee_payments')
    .update({ payment_status: 'SUCCESS', verified_by: actor, verified_at: now, updated_at: now, verification_method: method })
    .eq('id', p.id)
    .eq('payment_status', 'SUBMITTED') // guards double approval
    .select()
    .single();
  if (error) throw error;
  await db.from(KINDS[p.booking_kind as Kind]).update({ fee_payment_status: 'PAID', status: 'Confirmed' }).eq('id', p.booking_id);
  await logEvent(db, p.id, method === 'ocr_auto' ? 'PAYMENT_AUTO_VERIFIED' : 'PAYMENT_SUCCESS', actor, { utr: p.utr });
  await notify(db, p.user_id, '✅ Booking confirmed', `Your ₹${p.amount} booking fee was verified. Pay the remaining amount directly to the provider.`, p.booking_id);
  if (p.host_id) {
    await notify(db, String(p.host_id).replace(/^mth_/, ''), '🛎️ New confirmed booking', `Booking ${p.booking_id}: booking fee paid. Collect the full rental amount from the customer.`, p.booking_id);
  }
  return updated;
}

const MAX_SCREENSHOT_BYTES = 1024 * 1024; // OCR.space free tier limit

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  const uid = await getUserId(req);
  if (!uid) return json({ error: 'Sign in required' }, 401);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Invalid JSON' }, 400);
  }

  const db = admin();
  const action = String(body.action ?? '');

  try {
    // ------------------------------------------------------------------ create
    if (action === 'create') {
      const kind = String(body.booking_kind ?? '') as Kind;
      const bookingId = String(body.booking_id ?? '').trim();
      if (!(kind in KINDS) || !bookingId) return json({ error: 'booking_kind and booking_id required' }, 400);

      const { data: booking } = await db.from(KINDS[kind]).select('*').eq('id', bookingId).maybeSingle();
      if (!booking) return json({ error: 'Booking not found' }, 404);
      if (!ownsBooking(booking, uid)) return json({ error: 'Not your booking' }, 403);
      const bStatus = String(booking.status ?? '').toLowerCase();
      if (bStatus === 'cancelled') return json({ error: 'Booking is cancelled' }, 409);

      // Idempotent: reuse a live payment for this booking.
      const { data: live } = await db
        .from('booking_fee_payments')
        .select('*')
        .eq('booking_kind', kind)
        .eq('booking_id', bookingId)
        .in('payment_status', ['CREATED', 'PENDING', 'SUBMITTED', 'SUCCESS'])
        .maybeSingle();

      const vpa = requireEnv('UPI_MERCHANT_VPA');
      const name = Deno.env.get('UPI_MERCHANT_NAME') ?? 'PassionRide';

      if (live) {
        // Expire stale unpaid sessions so a fresh one can be issued.
        if (live.payment_status === 'PENDING' && new Date(live.expires_at) < new Date()) {
          await db.from('booking_fee_payments').update({ payment_status: 'EXPIRED', updated_at: new Date().toISOString() }).eq('id', live.id);
          await logEvent(db, live.id, 'PAYMENT_EXPIRED', uid);
        } else {
          return json({ success: true, payment: live, upi_uri: upiUri(live.payee_vpa, name, live.payment_ref, bookingId) });
        }
      }

      const ref = `PR${Date.now().toString(36).toUpperCase()}${Math.random().toString(36).slice(2, 6).toUpperCase()}`;
      const { data: payment, error } = await db
        .from('booking_fee_payments')
        .insert({
          payment_ref: ref,
          booking_kind: kind,
          booking_id: bookingId,
          user_id: uid,
          host_id: booking.host_id ?? null,
          amount: BOOKING_FEE,
          payee_vpa: vpa,
          payment_status: 'PENDING',
        })
        .select()
        .single();
      if (error) throw error;

      const total = Number(booking.total_price ?? booking.totalPrice ?? 0) || null;
      await db.from(KINDS[kind]).update({
        booking_fee: BOOKING_FEE,
        remaining_amount: total, // fee is on top: provider collects the full price
        fee_payment_status: 'PENDING',
      }).eq('id', bookingId);
      await logEvent(db, payment.id, 'PAYMENT_CREATED', uid, { amount: BOOKING_FEE });

      return json({ success: true, payment, upi_uri: upiUri(vpa, name, ref, bookingId) });
    }

    // -------------------------------------------------------------- submit_utr
    if (action === 'submit_utr') {
      const paymentId = String(body.payment_id ?? '');
      const utr = String(body.utr ?? '').replace(/\s+/g, '');
      if (!/^[0-9]{12}$/.test(utr)) return json({ error: 'UTR must be the 12-digit UPI reference number' }, 400);

      const { data: p } = await db.from('booking_fee_payments').select('*').eq('id', paymentId).maybeSingle();
      if (!p || p.user_id !== uid) return json({ error: 'Payment not found' }, 404);
      if (!['PENDING', 'SUBMITTED', 'FAILED'].includes(p.payment_status)) {
        return json({ error: `Payment is ${p.payment_status}` }, 409);
      }

      const { data: dup } = await db.from('booking_fee_payments').select('id').eq('utr', utr).neq('id', paymentId).maybeSingle();
      if (dup) return json({ error: 'This UTR was already used for another payment' }, 409);

      const { data: updated, error } = await db
        .from('booking_fee_payments')
        .update({ utr, payment_status: 'SUBMITTED', failure_reason: null, updated_at: new Date().toISOString() })
        .eq('id', paymentId)
        .select()
        .single();
      if (error) throw error;
      await db.from(KINDS[p.booking_kind as Kind]).update({ fee_payment_status: 'SUBMITTED' }).eq('id', p.booking_id);
      await logEvent(db, paymentId, 'UTR_SUBMITTED', uid, { utr });
      return json({ success: true, payment: updated });
    }

    // -------------------------------------------------------- submit_screenshot
    if (action === 'submit_screenshot') {
      const paymentId = String(body.payment_id ?? '');
      const mime = String(body.mime ?? 'image/jpeg');
      if (!/^image\/(png|jpe?g|webp)$/.test(mime)) return json({ error: 'Upload a PNG or JPG screenshot' }, 400);
      const b64 = String(body.image_base64 ?? '');
      let bytes: Uint8Array;
      try {
        bytes = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
      } catch {
        return json({ error: 'Invalid image' }, 400);
      }
      if (bytes.length < 5_000) return json({ error: 'Image is too small to be a payment screenshot' }, 400);
      if (bytes.length > MAX_SCREENSHOT_BYTES) return json({ error: 'Screenshot must be under 1 MB' }, 413);

      const { data: p } = await db.from('booking_fee_payments').select('*').eq('id', paymentId).maybeSingle();
      if (!p || p.user_id !== uid) return json({ error: 'Payment not found' }, 404);
      if (p.payment_status === 'SUCCESS') return json({ success: true, payment: p, report: p.verification });
      if (!['PENDING', 'SUBMITTED', 'FAILED'].includes(p.payment_status)) {
        return json({ error: `Payment is ${p.payment_status}` }, 409);
      }

      const hash = await sha256Hex(bytes);
      const { data: sameImage } = await db.from('booking_fee_payments').select('id').eq('screenshot_sha256', hash).neq('id', paymentId).maybeSingle();
      if (sameImage) return json({ error: 'This screenshot was already used for another booking' }, 409);

      const text = await ocrImage(b64, mime, requireEnv('OCR_SPACE_API_KEY'));
      const report = checkScreenshot(text, {
        payeeName: requireEnv('UPI_PAYEE_LEGAL_NAME'),
        payeeVpa: p.payee_vpa,
        amount: Number(p.amount),
        createdAt: new Date(p.created_at),
        now: new Date(),
      });

      // UTR: screenshot wins; must match a UTR the user typed earlier, and be unused.
      const utr = report.utr ?? p.utr ?? null;
      if (report.utr && p.utr && report.utr !== p.utr) {
        report.checks.push({ key: 'utr_match', label: 'UTR matches the one you entered', ok: false, detail: `Entered ${p.utr}, screenshot shows ${report.utr}` });
        report.passed = false;
      }
      if (utr) {
        const { data: dup } = await db.from('booking_fee_payments').select('id').eq('utr', utr).neq('id', paymentId).maybeSingle();
        if (dup) return json({ error: 'This UTR was already used for another payment' }, 409);
      }

      const path = `${p.booking_kind}/${paymentId}/${hash.slice(0, 16)}.${mime.split('/')[1].replace('jpeg', 'jpg')}`;
      const up = await db.storage.from('payment-proofs').upload(path, bytes, { contentType: mime, upsert: true });
      if (up.error) console.error('screenshot upload failed', up.error.message);

      const now = new Date().toISOString();
      const { data: saved, error } = await db
        .from('booking_fee_payments')
        .update({
          utr,
          payment_status: utr ? 'SUBMITTED' : p.payment_status,
          failure_reason: null,
          screenshot_path: up.error ? p.screenshot_path : path,
          screenshot_sha256: hash,
          ocr_text: text.slice(0, 4000),
          verification: report,
          updated_at: now,
        })
        .eq('id', paymentId)
        .select()
        .single();
      if (error) throw error;
      if (utr) await db.from(KINDS[p.booking_kind as Kind]).update({ fee_payment_status: 'SUBMITTED' }).eq('id', p.booking_id);
      await logEvent(db, paymentId, 'SCREENSHOT_CHECKED', uid, { passed: report.passed, failed: report.checks.filter((c) => !c.ok).map((c) => c.key) });

      if (report.passed && saved.payment_status === 'SUBMITTED') {
        return json({ success: true, payment: await confirmPayment(db, saved, null, 'ocr_auto'), report });
      }
      return json({ success: true, payment: saved, report });
    }

    // ------------------------------------------------------------------ status
    if (action === 'status') {
      const { data: p } = await db.from('booking_fee_payments').select('*').eq('id', String(body.payment_id ?? '')).maybeSingle();
      if (!p || (p.user_id !== uid && !(await isAdmin(db, uid)))) return json({ error: 'Payment not found' }, 404);
      return json({ success: true, payment: p });
    }

    // ---------------------------------------------------------- admin actions
    if (['review', 'refund', 'pending'].includes(action)) {
      if (!(await isAdmin(db, uid))) return json({ error: 'Admin only' }, 403);

      if (action === 'pending') {
        const { data } = await db
          .from('booking_fee_payments')
          .select('*')
          .in('payment_status', ['SUBMITTED', 'PENDING', 'REFUND_PENDING'])
          .order('created_at', { ascending: false })
          .limit(200);
        const payments = await Promise.all((data ?? []).map(async (row) => {
          if (!row.screenshot_path) return row;
          const { data: signed } = await db.storage.from('payment-proofs').createSignedUrl(row.screenshot_path, 60 * 60);
          return { ...row, screenshot_url: signed?.signedUrl ?? null };
        }));
        return json({ success: true, payments });
      }

      const paymentId = String(body.payment_id ?? '');
      const { data: p } = await db.from('booking_fee_payments').select('*').eq('id', paymentId).maybeSingle();
      if (!p) return json({ error: 'Payment not found' }, 404);
      const table = KINDS[p.booking_kind as Kind];
      const now = new Date().toISOString();

      if (action === 'review') {
        const decision = String(body.decision ?? '');
        if (p.payment_status === 'SUCCESS' && decision === 'approve') return json({ success: true, payment: p }); // idempotent
        if (p.payment_status !== 'SUBMITTED') return json({ error: `Payment is ${p.payment_status}` }, 409);

        if (decision === 'approve') {
          return json({ success: true, payment: await confirmPayment(db, p, uid, 'admin') });
        }

        if (decision === 'reject') {
          const reason = String(body.reason ?? 'UTR could not be matched with a received payment');
          const { data: updated, error } = await db
            .from('booking_fee_payments')
            .update({ payment_status: 'FAILED', failure_reason: reason, verified_by: uid, verified_at: now, updated_at: now })
            .eq('id', paymentId)
            .select()
            .single();
          if (error) throw error;
          await db.from(table).update({ fee_payment_status: 'FAILED' }).eq('id', p.booking_id);
          await logEvent(db, paymentId, 'PAYMENT_VERIFICATION_FAILED', uid, { reason });
          await notify(db, p.user_id, '⚠️ Booking fee not verified', `${reason}. Please check the UTR and submit again.`, p.booking_id);
          return json({ success: true, payment: updated });
        }
        return json({ error: "decision must be 'approve' or 'reject'" }, 400);
      }

      if (action === 'refund') {
        if (!['SUCCESS', 'REFUND_PENDING'].includes(p.payment_status)) return json({ error: `Payment is ${p.payment_status}` }, 409);
        const reason = String(body.reason ?? 'Provider rejected the booking');
        const reference = String(body.reference ?? '').trim();
        const done = reference.length > 0;
        const { error: rErr } = await db.from('payment_refunds').upsert({
          payment_id: paymentId,
          refund_amount: p.amount,
          refund_reason: reason,
          refund_status: done ? 'COMPLETED' : 'PENDING',
          refund_reference: reference || null,
          created_by: uid,
          updated_at: now,
        }, { onConflict: 'payment_id' });
        if (rErr) throw rErr;
        const status = done ? 'REFUNDED' : 'REFUND_PENDING';
        await db.from('booking_fee_payments').update({ payment_status: status, updated_at: now }).eq('id', paymentId);
        await db.from(table).update({ fee_payment_status: status }).eq('id', p.booking_id);
        await logEvent(db, paymentId, done ? 'PAYMENT_REFUNDED' : 'REFUND_INITIATED', uid, { reason, reference });
        if (done) await notify(db, p.user_id, '💸 Booking fee refunded', `₹${p.amount} refunded (ref ${reference}).`, p.booking_id);
        return json({ success: true, status });
      }
    }

    return json({ error: 'Unknown action' }, 400);
  } catch (e) {
    console.error('upi-booking-fee error', e);
    return json({ error: e instanceof Error ? e.message : String(e) }, 500);
  }
});
