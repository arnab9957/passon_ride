// Supabase Edge Function: send-push
// Called by the `notifications_send_push` database trigger for every new
// notification row; delivers it to the recipient's devices via FCM HTTP v1.
//
// Secrets:
//   PUSH_WEBHOOK_SECRET    same value as vault secret `push_webhook_secret`
//   FCM_SERVICE_ACCOUNT    Firebase service-account JSON (Project settings → Service accounts)
//   PUBLIC_SITE_URL        optional, e.g. https://passon-ride-rental-888.web.app (web click link)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { json, requireEnv } from '../_shared/auth.ts';

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

interface NotificationRow {
  id: string;
  user_id: string;
  title: string;
  message: string;
  type?: string;
  related_id?: string | null;
  image_url?: string | null;
  action_nav_index?: number | null;
}

let cachedToken: { value: string; expiresAt: number } | null = null;

function b64url(data: ArrayBuffer | string): string {
  const bytes = typeof data === 'string' ? new TextEncoder().encode(data) : new Uint8Array(data);
  let bin = '';
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/** OAuth2 access token for FCM, from a service-account JWT (RS256). Cached ~55 min. */
async function getAccessToken(sa: ServiceAccount): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60_000) return cachedToken.value;

  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = b64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  );
  const pem = sa.private_key.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    'pkcs8',
    der,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${claims}`));
  const assertion = `${header}.${claims}.${b64url(sig)}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(`Google OAuth failed: ${JSON.stringify(body)}`);
  cachedToken = { value: body.access_token, expiresAt: Date.now() + body.expires_in * 1000 };
  return cachedToken.value;
}

serve(async (req: Request) => {
  try {
    if (req.headers.get('x-push-secret') !== requireEnv('PUSH_WEBHOOK_SECRET')) {
      return json({ error: 'Unauthorized' }, 401);
    }

    const { record } = (await req.json()) as { record?: NotificationRow };
    if (!record?.user_id || !record.title) return json({ skipped: 'no recipient' });

    const supabase = createClient(requireEnv('SUPABASE_URL'), requireEnv('SUPABASE_SERVICE_ROLE_KEY'), {
      auth: { persistSession: false },
    });
    const { data: tokens, error } = await supabase.rpc('push_tokens_for', { p_user_id: record.user_id });
    if (error) throw new Error(`push_tokens_for: ${error.message}`);
    if (!tokens?.length) return json({ sent: 0, reason: 'no devices' });

    const sa = JSON.parse(requireEnv('FCM_SERVICE_ACCOUNT')) as ServiceAccount;
    const accessToken = await getAccessToken(sa);
    const siteUrl = Deno.env.get('PUBLIC_SITE_URL') ?? '';

    // FCM data values must be strings.
    const data: Record<string, string> = {
      notification_id: String(record.id ?? ''),
      type: String(record.type ?? ''),
      related_id: String(record.related_id ?? ''),
      action_nav_index: record.action_nav_index == null ? '' : String(record.action_nav_index),
    };
    const image = record.image_url && record.image_url.startsWith('http') ? record.image_url : undefined;

    let sent = 0;
    const stale: string[] = [];
    await Promise.all(
      (tokens as { token: string }[]).map(async ({ token }) => {
        const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
          method: 'POST',
          headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: record.title, body: record.message, ...(image ? { image } : {}) },
              data,
              android: { priority: 'high', notification: { sound: 'default' } },
              apns: { payload: { aps: { sound: 'default' } } },
              webpush: siteUrl ? { fcm_options: { link: siteUrl } } : undefined,
            },
          }),
        });
        if (res.ok) {
          sent++;
          return;
        }
        const err = await res.text();
        // Token no longer valid (app uninstalled, signed out, expired) → clean it up.
        if (res.status === 404 || err.includes('UNREGISTERED') || err.includes('registration-token-not-registered')) {
          stale.push(token);
        } else {
          console.error('FCM send failed', res.status, err);
        }
      }),
    );

    if (stale.length) await supabase.from('device_tokens').delete().in('token', stale);
    return json({ sent, removed: stale.length });
  } catch (error) {
    console.error('send-push error:', (error as Error).message);
    return json({ error: (error as Error).message }, 500);
  }
});
