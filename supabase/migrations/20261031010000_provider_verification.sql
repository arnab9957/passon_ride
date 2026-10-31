-- Provider verification: trusted admin check, private submissions, private documents,
-- and a database-level rule that only verified providers can publish new listings.

-- 1. Admin check. profiles.role is user-editable, so it must never grant admin.
CREATE TABLE IF NOT EXISTS public.platform_admins (email TEXT PRIMARY KEY);
ALTER TABLE public.platform_admins ENABLE ROW LEVEL SECURITY;
INSERT INTO public.platform_admins (email) VALUES ('passion.ride26@gmail.com')
ON CONFLICT DO NOTHING;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.platform_admins
        WHERE email = lower(COALESCE(auth.jwt() ->> 'email', ''))
    );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

DROP POLICY IF EXISTS "Admins manage host profiles" ON public.host_profiles;
CREATE POLICY "Admins manage host profiles" ON public.host_profiles
FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 2. Only admins may change the outcome of a review.
CREATE OR REPLACE FUNCTION public.protect_host_verification()
RETURNS TRIGGER AS $$
BEGIN
    IF public.is_admin() OR auth.role() = 'service_role' THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' THEN
        NEW.is_verified := FALSE;
        NEW.verification_status := 'pending';
        NEW.verification_notes := '';
        NEW.verified_at := NULL;
        NEW.verified_by := '';
        RETURN NEW;
    END IF;

    NEW.is_verified := OLD.is_verified;
    NEW.verified_at := OLD.verified_at;
    NEW.verified_by := OLD.verified_by;
    NEW.verification_notes := OLD.verification_notes;
    -- A provider may only resubmit, which moves an unverified review back to pending.
    IF OLD.is_verified OR NEW.verification_status <> 'pending' THEN
        NEW.verification_status := OLD.verification_status;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_protect_host_verification ON public.host_profiles;
CREATE TRIGGER trg_protect_host_verification
BEFORE INSERT OR UPDATE ON public.host_profiles
FOR EACH ROW EXECUTE FUNCTION public.protect_host_verification();

-- 3. Private submission details, readable only by the provider and admins.
CREATE TABLE IF NOT EXISTS public.provider_verifications (
    user_id TEXT PRIMARY KEY,
    provider_types TEXT[] NOT NULL DEFAULT '{}',
    full_name TEXT NOT NULL DEFAULT '',
    address TEXT NOT NULL DEFAULT '',
    id_type TEXT NOT NULL DEFAULT '',
    id_number TEXT NOT NULL DEFAULT '',
    payout_details TEXT NOT NULL DEFAULT '',
    documents JSONB NOT NULL DEFAULT '{}'::jsonb,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.provider_verifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Provider or admin reads verification" ON public.provider_verifications;
CREATE POLICY "Provider or admin reads verification" ON public.provider_verifications
FOR SELECT TO authenticated USING (user_id = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS "Provider submits verification" ON public.provider_verifications;
CREATE POLICY "Provider submits verification" ON public.provider_verifications
FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid()::text);

DROP POLICY IF EXISTS "Provider updates verification" ON public.provider_verifications;
CREATE POLICY "Provider updates verification" ON public.provider_verifications
FOR UPDATE TO authenticated
USING (user_id = auth.uid()::text) WITH CHECK (user_id = auth.uid()::text);

-- Existing ID details leave the publicly readable host_profiles table.
INSERT INTO public.provider_verifications (user_id, full_name, id_type, id_number, documents)
SELECT id, display_name, COALESCE(government_id_type, ''), COALESCE(government_id_number, ''),
       CASE WHEN COALESCE(document_url, '') <> ''
            THEN jsonb_build_object('legacy_document_url', document_url)
            ELSE '{}'::jsonb END
FROM public.host_profiles
ON CONFLICT (user_id) DO NOTHING;

UPDATE public.host_profiles
SET government_id_number = '', document_url = ''
WHERE COALESCE(government_id_number, '') <> '' OR COALESCE(document_url, '') <> '';

-- 4. Private document storage; files live under <user id>/...
INSERT INTO storage.buckets (id, name, public)
VALUES ('provider-documents', 'provider-documents', FALSE)
ON CONFLICT (id) DO UPDATE SET public = FALSE;

DROP POLICY IF EXISTS "Provider uploads own documents" ON storage.objects;
CREATE POLICY "Provider uploads own documents" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'provider-documents' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "Provider replaces own documents" ON storage.objects;
CREATE POLICY "Provider replaces own documents" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'provider-documents' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "Provider or admin reads documents" ON storage.objects;
CREATE POLICY "Provider or admin reads documents" ON storage.objects
FOR SELECT TO authenticated
USING (bucket_id = 'provider-documents'
       AND ((storage.foldername(name))[1] = auth.uid()::text OR public.is_admin()));

-- 5. Publishing gate. Saves of existing rows pass, because customers update them too
-- (availability, ratings) and because existing listings stay live.
CREATE OR REPLACE FUNCTION public.require_verified_provider()
RETURNS TRIGGER AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    IF public.is_admin() OR auth.role() = 'service_role' THEN
        RETURN NEW;
    END IF;

    EXECUTE format('SELECT EXISTS (SELECT 1 FROM public.%I WHERE id = $1)', TG_TABLE_NAME)
    INTO v_exists USING NEW.id;
    IF v_exists THEN
        RETURN NEW;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.host_profiles
        WHERE id = auth.uid()::text AND is_verified
    ) THEN
        RAISE EXCEPTION 'Provider verification is required before publishing a listing'
            USING ERRCODE = '42501';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_require_verified_provider ON public.vehicles;
CREATE TRIGGER trg_require_verified_provider BEFORE INSERT ON public.vehicles
FOR EACH ROW EXECUTE FUNCTION public.require_verified_provider();

DROP TRIGGER IF EXISTS trg_require_verified_provider ON public.hotels;
CREATE TRIGGER trg_require_verified_provider BEFORE INSERT ON public.hotels
FOR EACH ROW EXECUTE FUNCTION public.require_verified_provider();

DROP TRIGGER IF EXISTS trg_require_verified_provider ON public.tours;
CREATE TRIGGER trg_require_verified_provider BEFORE INSERT ON public.tours
FOR EACH ROW EXECUTE FUNCTION public.require_verified_provider();
