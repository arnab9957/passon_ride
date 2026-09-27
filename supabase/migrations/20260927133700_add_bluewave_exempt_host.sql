-- Add bluewaverental11@gmail.com to exempt_hosts
INSERT INTO public.exempt_hosts (email, reason, is_active)
VALUES ('bluewaverental11@gmail.com', 'Authorized Initial Host Account', true)
ON CONFLICT (email) DO UPDATE SET is_active = true, updated_at = NOW();
