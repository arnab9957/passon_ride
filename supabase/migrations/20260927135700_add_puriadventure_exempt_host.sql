-- Add puriadventureride@gmail.com to approved_emails
INSERT INTO public.approved_emails (email, reason, is_active)
VALUES ('puriadventureride@gmail.com', 'Authorized Initial Host Account', true)
ON CONFLICT (email) DO UPDATE SET is_active = true, updated_at = NOW();
