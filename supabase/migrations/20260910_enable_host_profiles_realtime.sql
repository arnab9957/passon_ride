-- Migration: Enable Realtime for host_profiles
-- Version: 20260910

ALTER PUBLICATION supabase_realtime ADD TABLE public.host_profiles;
