// Supabase Edge Function: create-razorpay-order
// Creates a Razorpay order with server-side credentials. Signed-in users only.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders, getUserId, json, requireEnv } from '../_shared/auth.ts';

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const userId = await getUserId(req);
    if (!userId) return json({ error: 'Sign in required' }, 401);

    const { amount, currency = 'INR', receipt, notes } = await req.json();
    if (!amount || amount < 100) {
      return json({ error: 'Invalid amount: minimum 100 paise (₹1.00) required' }, 400);
    }

    const basicAuth = btoa(`${requireEnv('RAZORPAY_KEY_ID')}:${requireEnv('RAZORPAY_KEY_SECRET')}`);
    const response = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: { Authorization: `Basic ${basicAuth}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        amount: Math.round(Number(amount)),
        currency: currency || 'INR',
        receipt: receipt || `rcpt_${Date.now()}`,
        notes: { ...(notes || {}), user_id: userId },
      }),
    });

    const data = await response.json();
    if (!response.ok) {
      return json({ error: data.error || 'Razorpay Order Creation Failed' }, response.status);
    }

    return json({
      id: data.id,
      amount: data.amount,
      currency: data.currency,
      receipt: data.receipt,
      status: data.status,
    });
  } catch (error) {
    return json({ error: (error as Error).message }, 500);
  }
});
