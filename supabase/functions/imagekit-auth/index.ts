// Supabase Edge Function: imagekit-auth
// Issues short-lived ImageKit upload signatures so the private key stays on the server.
// The app uploads straight to ImageKit with the public key plus these parameters.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders, getUserId, json, requireEnv } from '../_shared/auth.ts';

async function hmacSha1Hex(key: string, data: string): Promise<string> {
  const enc = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey('raw', enc.encode(key), { name: 'HMAC', hash: 'SHA-1' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', cryptoKey, enc.encode(data));
  return Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    if (!(await getUserId(req))) return json({ error: 'Sign in required' }, 401);

    const token = crypto.randomUUID();
    const expire = Math.floor(Date.now() / 1000) + 600; // 10 minutes
    const signature = await hmacSha1Hex(requireEnv('IMAGEKIT_PRIVATE_KEY'), `${token}${expire}`);

    return json({ token, expire, signature });
  } catch (error) {
    return json({ error: (error as Error).message }, 500);
  }
});
