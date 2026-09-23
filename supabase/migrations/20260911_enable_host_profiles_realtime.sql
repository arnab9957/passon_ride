-- Migration: Enable Realtime for host_profiles
-- Version: 20260910

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'host_profiles'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.host_profiles;
    END IF;
END $$;
