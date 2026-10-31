// Supabase Edge Function: verify-razorpay-signature
// Verifies the Razorpay HMAC-SHA256 signature server-side and records the transaction.
// A payment is only accepted with a valid order id + signature; there is no sandbox bypass.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { corsHeaders, getUserId, json, requireEnv } from '../_shared/auth.ts';

async function hmacSha256(key: string, data: string): Promise<string> {
  const enc = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey('raw', enc.encode(key), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const signature = await crypto.subtle.sign('HMAC', cryptoKey, enc.encode(data));
  return Array.from(new Uint8Array(signature)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const userId = await getUserId(req);
    if (!userId) return json({ verified: false, error: 'Sign in required' }, 401);

    const { order_id, payment_id, signature, booking_id, amount, currency = 'INR', payment_method = 'razorpay' } =
      await req.json();

    if (!order_id || !payment_id || !signature) {
      return json({ verified: false, error: 'order_id, payment_id and signature are required' }, 400);
    }

    const generated = await hmacSha256(requireEnv('RAZORPAY_KEY_SECRET'), `${order_id}|${payment_id}`);
    if (generated.toLowerCase() !== String(signature).toLowerCase()) {
      return json({ verified: false, error: 'Signature verification mismatch' }, 400);
    }

    const supabase = createClient(requireEnv('SUPABASE_URL'), requireEnv('SUPABASE_SERVICE_ROLE_KEY'));
    const { error } = await supabase.from('payment_transactions').insert({
      user_id: userId,
      booking_id: booking_id || null,
      razorpay_payment_id: payment_id,
      razorpay_order_id: order_id,
      razorpay_signature: signature,
      amount: Number(amount || 0),
      currency: currency || 'INR',
      status: 'captured',
      payment_method: payment_method || 'razorpay',
      escrow_status: 'held_in_escrow',
    });
    if (error) console.error('payment_transactions insert failed', error);

    return json({ verified: true, payment_id, order_id });
  } catch (error) {
    return json({ verified: false, error: (error as Error).message }, 500);
  }
});
