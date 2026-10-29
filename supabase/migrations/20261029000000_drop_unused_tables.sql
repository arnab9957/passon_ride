-- Drop tables the app no longer reads or writes.
-- No CASCADE: if anything still depends on one of these, the migration fails
-- instead of silently dropping the dependent object.
--
-- Kept on purpose:
--   chat_threads / chat_messages: still used for booking chats, whose thread ids
--     ('c_b_<booking id>') aren't UUIDs and so can't go into conversations/messages.
--   approved_emails: exempt_hosts may be a view over it (20260927134800).
--   user_accounts: conversations and messages have foreign keys to it.

DROP VIEW IF EXISTS public.provider_profiles;
DROP TABLE IF EXISTS public.renter_profiles;
DROP TABLE IF EXISTS public.notification_delivery_logs;
DROP TABLE IF EXISTS public.host_earnings;
DROP TABLE IF EXISTS public.irsargo_chat_logs;
