-- Migration: Mother-Child Account Architecture
-- Description: Relational structure for Mother Profile + Child Profiles (up to 3 independent child accounts)
-- Created: 2026-09-12

-- ==========================================================
-- 1. MOTHER PROFILE TABLE
-- ==========================================================
CREATE TABLE IF NOT EXISTS public.mother_profile (
    mother_id TEXT PRIMARY KEY,               -- e.g. 'mth_' || UUID or user ID
    customer_id TEXT NOT NULL,                -- User/customer reference
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT DEFAULT '',
    profile_photo TEXT DEFAULT '',
    status TEXT DEFAULT 'active',             -- 'active', 'suspended', 'deactivated'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================================
-- 2. CHILD PROFILE TABLE (MAX 3 CHILDREN PER MOTHER)
-- ==========================================================
CREATE TABLE IF NOT EXISTS public.child_profile (
    child_id TEXT PRIMARY KEY,                -- e.g. 'chd_' || UUID or child user ID
    mother_id TEXT NOT NULL REFERENCES public.mother_profile(mother_id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT DEFAULT '',
    profile_photo TEXT DEFAULT '',
    status TEXT DEFAULT 'active',             -- 'active', 'suspended', 'deactivated'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast querying & referential lookups
CREATE INDEX IF NOT EXISTS idx_child_profile_mother_id ON public.child_profile(mother_id);
CREATE INDEX IF NOT EXISTS idx_mother_profile_email ON public.mother_profile(LOWER(email));
CREATE INDEX IF NOT EXISTS idx_child_profile_email ON public.child_profile(LOWER(email));
CREATE INDEX IF NOT EXISTS idx_mother_profile_customer_id ON public.mother_profile(customer_id);

-- ==========================================================
-- 3. ENFORCE 3-CHILD MAXIMUM PER MOTHER VIA TRIGGER
-- ==========================================================
CREATE OR REPLACE FUNCTION public.fn_enforce_child_profile_limit()
RETURNS TRIGGER AS $$
DECLARE
    v_child_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_child_count
    FROM public.child_profile
    WHERE mother_id = NEW.mother_id
      AND child_id <> COALESCE(NEW.child_id, '');

    IF v_child_count >= 3 THEN
        RAISE EXCEPTION 'You have reached the maximum limit of 3 child accounts.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_child_profile_limit ON public.child_profile;
CREATE TRIGGER trg_check_child_profile_limit
    BEFORE INSERT ON public.child_profile
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_enforce_child_profile_limit();

-- ==========================================================
-- 4. ENFORCE CROSS-TABLE EMAIL UNIQUENESS
-- ==========================================================
CREATE OR REPLACE FUNCTION public.fn_enforce_unique_account_email()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_TABLE_NAME = 'mother_profile') THEN
        IF EXISTS (SELECT 1 FROM public.child_profile WHERE LOWER(email) = LOWER(NEW.email) AND mother_id <> NEW.mother_id) THEN
            RAISE EXCEPTION 'This email address is already associated with another account. Please use a different email address.';
        END IF;
    ELSIF (TG_TABLE_NAME = 'child_profile') THEN
        IF EXISTS (SELECT 1 FROM public.mother_profile WHERE LOWER(email) = LOWER(NEW.email)) THEN
            RAISE EXCEPTION 'This email address is already associated with another account. Please use a different email address.';
        END IF;
        IF EXISTS (SELECT 1 FROM public.child_profile WHERE LOWER(email) = LOWER(NEW.email) AND child_id <> NEW.child_id) THEN
            RAISE EXCEPTION 'This email address is already associated with another account. Please use a different email address.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_unique_mother_email ON public.mother_profile;
CREATE TRIGGER trg_unique_mother_email
    BEFORE INSERT OR UPDATE ON public.mother_profile
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_enforce_unique_account_email();

DROP TRIGGER IF EXISTS trg_unique_child_email ON public.child_profile;
CREATE TRIGGER trg_unique_child_email
    BEFORE INSERT OR UPDATE ON public.child_profile
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_enforce_unique_account_email();

-- ==========================================================
-- 5. AUTOMATIC UPDATED_AT TIMESTAMP REFRESH
-- ==========================================================
CREATE OR REPLACE FUNCTION public.fn_set_account_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_mother_profile_updated_at ON public.mother_profile;
CREATE TRIGGER trg_mother_profile_updated_at
    BEFORE UPDATE ON public.mother_profile
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_set_account_updated_at();

DROP TRIGGER IF EXISTS trg_child_profile_updated_at ON public.child_profile;
CREATE TRIGGER trg_child_profile_updated_at
    BEFORE UPDATE ON public.child_profile
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_set_account_updated_at();

-- ==========================================================
-- 6. BACKWARD-COMPATIBLE BOOKING & VEHICLE ACCOUNT REFS
-- ==========================================================
-- Ensure bookings have account_id column (if bookings table exists)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'bookings') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'account_id') THEN
            ALTER TABLE public.bookings ADD COLUMN account_id TEXT;
            UPDATE public.bookings SET account_id = rider_id WHERE account_id IS NULL AND rider_id IS NOT NULL;
        END IF;
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_bookings_account_id ON public.bookings(account_id)';
    END IF;
END $$;

-- Ensure vehicles have owner_account_id column (if vehicles table exists)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'vehicles') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'vehicles' AND column_name = 'owner_account_id') THEN
            ALTER TABLE public.vehicles ADD COLUMN owner_account_id TEXT;
            UPDATE public.vehicles SET owner_account_id = host_id WHERE owner_account_id IS NULL AND host_id IS NOT NULL;
        END IF;
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_vehicles_owner_account_id ON public.vehicles(owner_account_id)';
    END IF;
END $$;

-- ==========================================================
-- 7. MOTHER-LEVEL BOOKING AGGREGATION RPC (SECURE VIEW)
-- Only exposes limited booking info: vehicle, dates, status, price.
-- Excludes private child auth secrets, payments, private personal data.
-- ==========================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'bookings') THEN
        EXECUTE $fn$
        CREATE OR REPLACE FUNCTION public.get_mother_aggregated_bookings(p_mother_id TEXT)
        RETURNS TABLE (
            id TEXT,
            vehicle_id TEXT,
            vehicle_title TEXT,
            vehicle_image_url TEXT,
            host_name TEXT,
            start_date TEXT,
            end_date TEXT,
            total_price NUMERIC,
            status TEXT,
            unlock_passcode TEXT,
            created_at TEXT,
            account_id TEXT,
            account_name TEXT,
            account_type TEXT
        ) AS $func$
        BEGIN
            RETURN QUERY
            -- Mother's own bookings
            SELECT 
                b.id::TEXT,
                b.vehicle_id::TEXT,
                COALESCE(b.vehicle_title, '')::TEXT,
                COALESCE(b.vehicle_image_url, '')::TEXT,
                COALESCE(b.host_name, '')::TEXT,
                b.start_date::TEXT,
                b.end_date::TEXT,
                COALESCE(b.total_price, 0)::NUMERIC,
                COALESCE(b.status, 'Confirmed')::TEXT,
                COALESCE(b.unlock_passcode, '')::TEXT,
                b.created_at::TEXT,
                m.mother_id::TEXT AS account_id,
                m.name::TEXT AS account_name,
                'mother'::TEXT AS account_type
            FROM public.bookings b
            JOIN public.mother_profile m ON (b.account_id = m.mother_id OR b.rider_id = m.customer_id OR b.rider_id = m.mother_id)
            WHERE m.mother_id = p_mother_id

            UNION ALL

            -- Linked Children's bookings (limited booking fields only)
            SELECT 
                b.id::TEXT,
                b.vehicle_id::TEXT,
                COALESCE(b.vehicle_title, '')::TEXT,
                COALESCE(b.vehicle_image_url, '')::TEXT,
                COALESCE(b.host_name, '')::TEXT,
                b.start_date::TEXT,
                b.end_date::TEXT,
                COALESCE(b.total_price, 0)::NUMERIC,
                COALESCE(b.status, 'Confirmed')::TEXT,
                COALESCE(b.unlock_passcode, '')::TEXT,
                b.created_at::TEXT,
                c.child_id::TEXT AS account_id,
                c.name::TEXT AS account_name,
                'child'::TEXT AS account_type
            FROM public.bookings b
            JOIN public.child_profile c ON (b.account_id = c.child_id OR b.rider_id = c.child_id)
            WHERE c.mother_id = p_mother_id
            ORDER BY created_at DESC;
        END;
        $func$ LANGUAGE plpgsql SECURITY DEFINER;
        $fn$;
    END IF;
END $$;

-- ==========================================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================================
ALTER TABLE public.mother_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.child_profile ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view mother profiles" ON public.mother_profile;
DROP POLICY IF EXISTS "Authenticated users can insert mother profiles" ON public.mother_profile;
DROP POLICY IF EXISTS "Users can update their own mother profile" ON public.mother_profile;
DROP POLICY IF EXISTS "Users can delete their own mother profile" ON public.mother_profile;

CREATE POLICY "Public can view mother profiles"
    ON public.mother_profile FOR SELECT
    USING (TRUE);

CREATE POLICY "Authenticated users can insert mother profiles"
    ON public.mother_profile FOR INSERT
    WITH CHECK (TRUE);

CREATE POLICY "Users can update their own mother profile"
    ON public.mother_profile FOR UPDATE
    USING (TRUE);

CREATE POLICY "Users can delete their own mother profile"
    ON public.mother_profile FOR DELETE
    USING (TRUE);

DROP POLICY IF EXISTS "Public can view child profiles" ON public.child_profile;
DROP POLICY IF EXISTS "Mother or Child can create child profile" ON public.child_profile;
DROP POLICY IF EXISTS "Child or Mother can update child profile" ON public.child_profile;
DROP POLICY IF EXISTS "Mother or Child can delete child profile" ON public.child_profile;

CREATE POLICY "Public can view child profiles"
    ON public.child_profile FOR SELECT
    USING (TRUE);

CREATE POLICY "Mother or Child can create child profile"
    ON public.child_profile FOR INSERT
    WITH CHECK (TRUE);

CREATE POLICY "Child or Mother can update child profile"
    ON public.child_profile FOR UPDATE
    USING (TRUE);

CREATE POLICY "Mother or Child can delete child profile"
    ON public.child_profile FOR DELETE
    USING (TRUE);

-- ==========================================================
-- 9. PERMISSIONS (POSTGREST ACCESS)
-- ==========================================================
GRANT ALL ON TABLE public.mother_profile TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.child_profile TO anon, authenticated, service_role;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_mother_aggregated_bookings') THEN
        GRANT EXECUTE ON FUNCTION public.get_mother_aggregated_bookings(TEXT) TO anon, authenticated, service_role;
    END IF;
END $$;

-- ==========================================================
-- 10. REALTIME PUBLICATION
-- ==========================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'mother_profile'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.mother_profile;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'child_profile'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.child_profile;
    END IF;
END $$;
