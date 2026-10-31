// Shared helpers for edge functions: CORS, JSON responses, signed-in user, required secrets.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/** Returns the signed-in user's id, or null for anonymous / invalid tokens. */
export async function getUserId(req: Request): Promise<string | null> {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return null;
  const jwt = authHeader.replace(/^Bearer\s+/i, '');
  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  // The token must be passed explicitly: this server-side client holds no session.
  const { data, error } = await supabase.auth.getUser(jwt);
  if (error) console.error('getUserId rejected token:', error.message);
  if (error || !data.user) return null;
  return data.user.id;
}

/** Reads a secret set with `supabase secrets set`. Throws if missing; there are no fallbacks. */
export function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Server is missing the ${name} secret`);
  return value;
}
