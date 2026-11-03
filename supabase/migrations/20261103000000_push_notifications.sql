-- Push notifications (FCM): device tokens + trigger that forwards every new
-- notification row to the `send-push` edge function.
--
-- One-off setup (SQL editor, once per project):
--   select vault.create_secret('https://<project-ref>.supabase.co', 'project_url');
--   select vault.create_secret('<random-long-string>', 'push_webhook_secret');
-- and set the same random string as the edge-function secret PUSH_WEBHOOK_SECRET.

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- ---------------------------------------------------------------------------
-- Device tokens
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.device_tokens (
    token       TEXT PRIMARY KEY,
    user_id     TEXT NOT NULL,
    platform    TEXT NOT NULL DEFAULT 'unknown', -- android | ios | web
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS device_tokens_user_id_idx ON public.device_tokens (user_id);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own device tokens" ON public.device_tokens;
CREATE POLICY "Users can read their own device tokens" ON public.device_tokens
FOR SELECT TO authenticated USING (user_id = auth.uid()::text);

-- Writes go through these functions so a device that switches accounts moves its
-- token to the new user (a plain upsert would be blocked by RLS on the old row).
CREATE OR REPLACE FUNCTION public.register_device_token(p_token TEXT, p_platform TEXT)
RETURNS VOID AS $$
BEGIN
    IF auth.uid() IS NULL OR coalesce(p_token, '') = '' THEN
        RETURN;
    END IF;
    INSERT INTO public.device_tokens (token, user_id, platform, updated_at)
    VALUES (p_token, auth.uid()::text, coalesce(p_platform, 'unknown'), now())
    ON CONFLICT (token) DO UPDATE
        SET user_id = EXCLUDED.user_id, platform = EXCLUDED.platform, updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.unregister_device_token(p_token TEXT)
RETURNS VOID AS $$
    DELETE FROM public.device_tokens WHERE token = p_token AND user_id = auth.uid()::text;
$$ LANGUAGE sql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.register_device_token(TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.unregister_device_token(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.register_device_token(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.unregister_device_token(TEXT) TO authenticated;

-- Tokens for a notification recipient. Notifications may be addressed to a
-- mother or child account id, so resolve those back to the login (customer) id.
CREATE OR REPLACE FUNCTION public.push_tokens_for(p_user_id TEXT)
RETURNS TABLE (token TEXT, platform TEXT) AS $$
    WITH ids AS (
        SELECT p_user_id AS id
        UNION
        SELECT customer_id FROM public.mother_profile WHERE mother_id = p_user_id
        UNION
        SELECT m.customer_id
        FROM public.child_profile c
        JOIN public.mother_profile m ON m.mother_id = c.mother_id
        WHERE c.child_id = p_user_id
    )
    SELECT d.token, d.platform FROM public.device_tokens d WHERE d.user_id IN (SELECT id FROM ids);
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.push_tokens_for(TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.push_tokens_for(TEXT) TO service_role;

-- ---------------------------------------------------------------------------
-- notifications INSERT → send-push edge function
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_push_on_notification()
RETURNS TRIGGER AS $$
DECLARE
    v_url    TEXT;
    v_secret TEXT;
BEGIN
    SELECT decrypted_secret INTO v_url FROM vault.decrypted_secrets WHERE name = 'project_url' LIMIT 1;
    SELECT decrypted_secret INTO v_secret FROM vault.decrypted_secrets WHERE name = 'push_webhook_secret' LIMIT 1;
    IF v_url IS NULL OR v_secret IS NULL THEN
        RETURN NEW; -- push not configured yet; never block the insert
    END IF;

    PERFORM net.http_post(
        url     := rtrim(v_url, '/') || '/functions/v1/send-push',
        headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-secret', v_secret),
        body    := jsonb_build_object('record', to_jsonb(NEW))
    );
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'notify_push_on_notification failed: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

DROP TRIGGER IF EXISTS notifications_send_push ON public.notifications;
CREATE TRIGGER notifications_send_push
AFTER INSERT ON public.notifications
FOR EACH ROW EXECUTE FUNCTION public.notify_push_on_notification();
