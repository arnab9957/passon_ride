-- Payout requests from providers, settled manually by admins.
CREATE TABLE IF NOT EXISTS public.provider_payouts (
    id TEXT PRIMARY KEY,
    host_id TEXT NOT NULL,
    amount NUMERIC NOT NULL CHECK (amount > 0),
    status TEXT NOT NULL DEFAULT 'requested' CHECK (status IN ('requested', 'paid', 'rejected')),
    payout_details TEXT NOT NULL DEFAULT '',
    reference TEXT NOT NULL DEFAULT '',
    admin_note TEXT NOT NULL DEFAULT '',
    requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    settled_at TIMESTAMPTZ
);
ALTER TABLE public.provider_payouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Provider or admin reads payouts" ON public.provider_payouts;
CREATE POLICY "Provider or admin reads payouts" ON public.provider_payouts
FOR SELECT TO authenticated USING (host_id = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS "Provider requests payout" ON public.provider_payouts;
CREATE POLICY "Provider requests payout" ON public.provider_payouts
FOR INSERT TO authenticated
WITH CHECK (host_id = auth.uid()::text AND status = 'requested' AND reference = '' AND settled_at IS NULL);

DROP POLICY IF EXISTS "Admin settles payouts" ON public.provider_payouts;
CREATE POLICY "Admin settles payouts" ON public.provider_payouts
FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
