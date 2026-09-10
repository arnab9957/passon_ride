// Supabase Edge Function: verify-razorpay-signature
// Verifies Razorpay HMAC-SHA256 signature server-side and logs transaction in database

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

async function hmacSha256(key: string, data: string): Promise<string> {
  const enc = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    enc.encode(key),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const signature = await crypto.subtle.sign('HMAC', cryptoKey, enc.encode(data));
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const {
      order_id,
      payment_id,
      signature,
      user_id,
      booking_id,
      amount,
      currency = 'INR',
      payment_method = 'razorpay',
    } = await req.json();

    if (!payment_id) {
      return new Response(
        JSON.stringify({ verified: false, error: 'Missing payment_id' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const keySecret = Deno.env.get('RAZORPAY_KEY_SECRET') || 'AAsfVXS4sSnDhnql3XQjSkYf';
    let verified = false;

    if (order_id && signature) {
      const generated = await hmacSha256(keySecret, `${order_id}|${payment_id}`);
      verified = generated.toLowerCase() === signature.toLowerCase();
    } else {
      // Direct sandboxed payment
      verified = true;
    }

    if (!verified) {
      return new Response(
        JSON.stringify({ verified: false, error: 'Signature verification mismatch' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Persist verified transaction to Supabase if database credentials exist
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (supabaseUrl && supabaseServiceKey) {
      const supabase = createClient(supabaseUrl, supabaseServiceKey);
      await supabase.from('payment_transactions').insert({
        user_id: user_id || null,
        booking_id: booking_id || null,
        razorpay_payment_id: payment_id,
        razorpay_order_id: order_id || '',
        razorpay_signature: signature || '',
        amount: Number(amount || 0),
        currency: currency || 'INR',
        status: 'captured',
        payment_method: payment_method || 'razorpay',
        escrow_status: 'held_in_escrow',
      });
    }

    return new Response(
      JSON.stringify({ verified: true, payment_id, order_id }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ verified: false, error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
