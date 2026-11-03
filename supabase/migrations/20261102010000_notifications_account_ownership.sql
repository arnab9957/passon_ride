-- Notifications can be addressed to a user's mother or child account id, not only their login id.
CREATE OR REPLACE FUNCTION public.owns_notification(p_user_id TEXT)
RETURNS BOOLEAN AS $$
    SELECT p_user_id = auth.uid()::text
        OR p_user_id IN (SELECT mother_id FROM public.mother_profile WHERE customer_id = auth.uid()::text)
        OR p_user_id IN (
            SELECT child_id FROM public.child_profile
            WHERE mother_id IN (SELECT mother_id FROM public.mother_profile WHERE customer_id = auth.uid()::text)
        );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications" ON public.notifications
FOR UPDATE TO authenticated
USING (public.owns_notification(user_id)) WITH CHECK (public.owns_notification(user_id));

DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;
CREATE POLICY "Users can delete their own notifications" ON public.notifications
FOR DELETE TO authenticated
USING (public.owns_notification(user_id));
