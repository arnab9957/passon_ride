-- ==============================================================================
-- PASSION RIDE MIGRATION: Fix hotel_bookings columns, notifications RLS & Realtime
-- File: supabase/migrations/20261029_fix_hotel_bookings_and_notifications_rls.sql
-- ==============================================================================

-- 1. EXTEND HOTEL_BOOKINGS: Add missing cancellation tracking columns
ALTER TABLE public.hotel_bookings 
ADD COLUMN IF NOT EXISTS cancelled_by TEXT DEFAULT '';

ALTER TABLE public.hotel_bookings 
ADD COLUMN IF NOT EXISTS cancellation_reason TEXT DEFAULT '';

ALTER TABLE public.hotel_bookings 
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

-- 2. HARDEN & EXPAND NOTIFICATIONS RLS POLICIES
-- Allow cross-user alert delivery (Guest -> Host and Host -> Guest) for bookings & cancellations
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert notifications" ON public.notifications;
DROP POLICY IF EXISTS "Public insert notifications" ON public.notifications;

CREATE POLICY "Public insert notifications"
ON public.notifications FOR INSERT
TO authenticated, anon
WITH CHECK (true);

-- Ensure users can update notifications (e.g. mark as read)
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;

CREATE POLICY "Users can update their own notifications"
ON public.notifications FOR UPDATE
TO authenticated, anon
USING (
    ((SELECT auth.uid()::text) = user_id) OR (auth.uid() IS NULL)
)
WITH CHECK (
    ((SELECT auth.uid()::text) = user_id) OR (auth.uid() IS NULL)
);

-- Ensure users can view their own notifications (including mother-child accounts)
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;

CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
TO authenticated, anon
USING (
    ((SELECT auth.uid()::text) = user_id)
    OR (auth.uid() IS NULL)
    OR user_id IN (
        SELECT mother_id FROM public.mother_profile WHERE customer_id = ((SELECT auth.uid()::text))
    )
    OR user_id IN (
        SELECT child_id FROM public.child_profile WHERE mother_id IN (
            SELECT mother_id FROM public.mother_profile WHERE customer_id = ((SELECT auth.uid()::text))
        )
    )
);

-- Ensure users can delete their own notifications
DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;

CREATE POLICY "Users can delete their own notifications"
ON public.notifications FOR DELETE
TO authenticated, anon
USING (
    ((SELECT auth.uid()::text) = user_id) OR (auth.uid() IS NULL)
);

-- 3. ENABLE SUPABASE REALTIME ON PROFILES & HOST_PROFILES
-- Ensures WebSocket replication streams (code 1006 channelError resolution)
ALTER TABLE IF EXISTS public.profiles REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.host_profiles REPLICA IDENTITY FULL;

DO $$
BEGIN
    -- Add profiles to supabase_realtime publication
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles') THEN
        IF NOT EXISTS (
            SELECT 1 FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'profiles'
        ) THEN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
        END IF;
    END IF;

    -- Add host_profiles to supabase_realtime publication
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'host_profiles') THEN
        IF NOT EXISTS (
            SELECT 1 FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'host_profiles'
        ) THEN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.host_profiles;
        END IF;
    END IF;
END $$;

-- 4. RLS SELECT POLICIES REQUIRED BY REALTIME SUBSCRIBERS
ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view profiles" ON public.profiles;
CREATE POLICY "Public can view profiles"
ON public.profiles FOR SELECT
TO authenticated, anon
USING (true);

DROP POLICY IF EXISTS "Public can view host profiles" ON public.host_profiles;
CREATE POLICY "Public can view host profiles"
ON public.host_profiles FOR SELECT
TO authenticated, anon
USING (true);

-- 5. REFRESH POSTGREST SCHEMA CACHE
NOTIFY pgrst, 'reload schema';
