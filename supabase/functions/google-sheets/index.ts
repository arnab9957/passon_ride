// Supabase Edge Function: google-sheets
// Connects a host's Google account, creates their bookings sheet and appends rows.
// Deploy with --no-verify-jwt: Google's redirect carries no Supabase token, so POST
// requests are authenticated here with getUserId instead.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { corsHeaders, getUserId, json, requireEnv } from '../_shared/auth.ts';

const HEADERS = [
  'Booking ID', 'Category', 'Item / Service', 'Customer Name', 'Customer Phone', 'Customer Email',
  'Start / Check-In', 'End / Check-Out', 'Total (INR)', 'Status', 'Payment', 'Date Recorded',
];
const STATE_LIFETIME_MS = 10 * 60 * 1000;

const db = () => createClient(requireEnv('SUPABASE_URL'), requireEnv('SUPABASE_SERVICE_ROLE_KEY'));
const redirectUri = () => `${requireEnv('SUPABASE_URL')}/functions/v1/google-sheets`;
const hostKey = (id: string) => id.replace(/^mth_/, '');
const day = (value: unknown) => String(value ?? '').split('T')[0];

async function sign(data: string): Promise<string> {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw', enc.encode(requireEnv('GOOGLE_CLIENT_SECRET')), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(data));
  return Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function googleToken(params: Record<string, string>) {
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: requireEnv('GOOGLE_CLIENT_ID'),
      client_secret: requireEnv('GOOGLE_CLIENT_SECRET'),
      ...params,
    }),
  });
  if (!res.ok) throw new Error(`Google token error ${res.status}`);
  return await res.json();
}

async function handleCallback(url: URL): Promise<Response> {
  const finish = (result: string) =>
    Response.redirect(`${requireEnv('APP_URL')}?sheets=${result}`, 302);

  const [uid, expires, signature] = (url.searchParams.get('state') ?? '').split('.');
  const code = url.searchParams.get('code');
  if (!code || !uid || Number(expires) < Date.now() || signature !== (await sign(`${uid}.${expires}`))) {
    return finish('failed');
  }

  const tokens = await googleToken({
    code, redirect_uri: redirectUri(), grant_type: 'authorization_code',
  });
  if (!tokens.refresh_token) return finish('failed');

  const created = await fetch('https://sheets.googleapis.com/v4/spreadsheets', {
    method: 'POST',
    headers: { Authorization: `Bearer ${tokens.access_token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ properties: { title: 'PassionRide Bookings' } }),
  });
  if (!created.ok) return finish('failed');
  const sheet = await created.json();

  await appendRow(tokens.access_token, sheet.spreadsheetId, HEADERS);
  const { error } = await db().from('host_sheet_connections').upsert({
    host_id: uid,
    refresh_token: tokens.refresh_token,
    spreadsheet_id: sheet.spreadsheetId,
    spreadsheet_url: sheet.spreadsheetUrl,
  });
  return finish(error ? 'failed' : 'connected');
}

async function appendRow(accessToken: string, spreadsheetId: string, row: unknown[]) {
  const res = await fetch(
    `https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}/values/A1:append?valueInputOption=RAW`,
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ values: [row] }),
    },
  );
  if (!res.ok) throw new Error(`Sheets append error ${res.status}`);
}

/** Builds the row from the database so callers cannot write arbitrary data to a host's sheet. */
async function loadRow(body: Record<string, any>): Promise<{ hostId: string; bookingId: string; row: unknown[] } | null> {
  const recorded = new Date().toISOString();
  if (body.kind === 'vehicle') {
    const { data: b } = await db().from('bookings').select('*').eq('id', body.bookingId).maybeSingle();
    if (!b) return null;
    return {
      hostId: hostKey(b.host_id), bookingId: b.id,
      row: [b.id, 'Bike / Vehicle Ride', b.vehicle_title, b.customer_name, b.customer_phone, b.customer_email,
        day(b.start_date), day(b.end_date), b.total_price, b.status, b.payment_intent_id, recorded],
    };
  }
  if (body.kind === 'hotel') {
    const { data: b } = await db().from('hotel_bookings').select('*').eq('id', body.bookingId).maybeSingle();
    if (!b) return null;
    return {
      hostId: hostKey(b.host_id), bookingId: b.id,
      row: [b.booking_ref || b.id, 'Hotel / Homestay', b.hotel_name, b.guest_name, b.guest_phone, b.guest_email ?? '',
        day(b.check_in_date), day(b.check_out_date), b.total_price, b.status, b.payment_status, recorded],
    };
  }
  if (body.kind === 'tour') {
    const { data: t } = await db().from('tours').select('title, host_id').eq('id', body.tourId).maybeSingle();
    if (!t) return null;
    return {
      hostId: hostKey(t.host_id), bookingId: String(body.bookingId),
      row: [body.bookingId, 'Guided Tour', `${t.title} (${body.spots} spots)`, body.customerName, body.customerPhone,
        body.customerEmail, body.tourDate, body.tourDate, body.totalPrice, 'Confirmed', 'Online', recorded],
    };
  }
  return null;
}

async function handleSync(body: Record<string, any>): Promise<Response> {
  const item = await loadRow(body);
  if (!item) return json({ synced: false });

  const client = db();
  const { data: link } = await client.from('host_sheet_connections').select('*')
    .eq('host_id', item.hostId).maybeSingle();
  if (!link) return json({ synced: false });

  const { error: duplicate } = await client.from('sheet_synced_bookings')
    .insert({ host_id: item.hostId, booking_id: item.bookingId });
  if (duplicate) return json({ synced: false, duplicate: true });

  try {
    const tokens = await googleToken({ refresh_token: link.refresh_token, grant_type: 'refresh_token' });
    await appendRow(tokens.access_token, link.spreadsheet_id, item.row);
    return json({ synced: true });
  } catch (error) {
    await client.from('sheet_synced_bookings').delete()
      .eq('host_id', item.hostId).eq('booking_id', item.bookingId);
    throw error;
  }
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    if (req.method === 'GET') return await handleCallback(new URL(req.url));

    const uid = await getUserId(req);
    if (!uid) return json({ error: 'Sign in required' }, 401);
    const body = await req.json();

    switch (body.action) {
      case 'auth_url': {
        const expires = Date.now() + STATE_LIFETIME_MS;
        const params = new URLSearchParams({
          client_id: requireEnv('GOOGLE_CLIENT_ID'),
          redirect_uri: redirectUri(),
          response_type: 'code',
          scope: 'https://www.googleapis.com/auth/drive.file',
          access_type: 'offline',
          prompt: 'consent',
          state: `${uid}.${expires}.${await sign(`${uid}.${expires}`)}`,
        });
        return json({ url: `https://accounts.google.com/o/oauth2/v2/auth?${params}` });
      }
      case 'status': {
        const { data } = await db().from('host_sheet_connections').select('spreadsheet_url')
          .eq('host_id', uid).maybeSingle();
        return json({ connected: !!data, url: data?.spreadsheet_url ?? '' });
      }
      case 'disconnect':
        await db().from('host_sheet_connections').delete().eq('host_id', uid);
        await db().from('sheet_synced_bookings').delete().eq('host_id', uid);
        return json({ connected: false });
      case 'sync':
        return await handleSync(body);
      default:
        return json({ error: 'Unknown action' }, 400);
    }
  } catch (error) {
    console.error('google-sheets error:', (error as Error).message);
    return json({ error: 'Google Sheets request failed' }, 500);
  }
});
