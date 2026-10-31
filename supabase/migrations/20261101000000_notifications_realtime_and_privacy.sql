-- Deliver notifications live, and stop logged-out visitors reading or changing them.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'notifications'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
    END IF;
END $$;

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications" ON public.notifications
FOR SELECT TO authenticated
USING (
    user_id = auth.uid()::text
    OR user_id IN (SELECT mother_id FROM public.mother_profile WHERE customer_id = auth.uid()::text)
    OR user_id IN (
        SELECT child_id FROM public.child_profile
        WHERE mother_id IN (SELECT mother_id FROM public.mother_profile WHERE customer_id = auth.uid()::text)
    )
);

DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications" ON public.notifications
FOR UPDATE TO authenticated
USING (user_id = auth.uid()::text) WITH CHECK (user_id = auth.uid()::text);

DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;
CREATE POLICY "Users can delete their own notifications" ON public.notifications
FOR DELETE TO authenticated
USING (user_id = auth.uid()::text);
