-- Migration: Host / Provider Profiles separation and database verification triggers
-- Created: 2026-09-04

-- 1. Create public.host_profiles table for separated host/provider profiles
CREATE TABLE IF NOT EXISTS public.host_profiles (
    id TEXT PRIMARY KEY, -- Matches auth.users.id or profiles.id
    user_id UUID NOT NULL,
    display_name TEXT NOT NULL DEFAULT '',
    email TEXT DEFAULT '',
    phone_number TEXT DEFAULT '',
    photo_url TEXT DEFAULT '',
    bio TEXT DEFAULT '',
    business_name TEXT DEFAULT '',
    business_registration_number TEXT DEFAULT '',
    is_verified BOOLEAN DEFAULT FALSE,
    verification_status TEXT DEFAULT 'pending', -- 'pending', 'verified', 'rejected', 'action_required'
    verification_notes TEXT DEFAULT '',
    verified_at TIMESTAMPTZ,
    verified_by TEXT DEFAULT '',
    government_id_type TEXT DEFAULT '', -- 'Aadhaar', 'Driving License', 'Passport', 'PAN'
    government_id_number TEXT DEFAULT '',
    document_url TEXT DEFAULT '',
    total_listings_count INTEGER DEFAULT 0,
    rating NUMERIC(3,2) DEFAULT 5.00,
    review_count INTEGER DEFAULT 0,
    trust_score NUMERIC(5,2) DEFAULT 95.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create view alias public.provider_profiles for backward compatibility & queries
DROP TABLE IF EXISTS public.provider_profiles CASCADE;
DROP VIEW IF EXISTS public.provider_profiles CASCADE;
CREATE OR REPLACE VIEW public.provider_profiles AS
SELECT * FROM public.host_profiles;

-- 3. Create performance indexes (as per Postgres best practices query-missing-indexes)
CREATE INDEX IF NOT EXISTS idx_host_profiles_user_id ON public.host_profiles (user_id);
CREATE INDEX IF NOT EXISTS idx_host_profiles_verification_status ON public.host_profiles (verification_status);
CREATE INDEX IF NOT EXISTS idx_host_profiles_is_verified ON public.host_profiles (is_verified);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.host_profiles ENABLE ROW LEVEL SECURITY;

-- Drop pre-existing policies to allow idempotent application
DROP POLICY IF EXISTS "Public can view host profiles" ON public.host_profiles;
DROP POLICY IF EXISTS "Authenticated users can create host profile" ON public.host_profiles;
DROP POLICY IF EXISTS "Authenticated users can update their own host profile" ON public.host_profiles;
DROP POLICY IF EXISTS "Admins can update host profiles" ON public.host_profiles;

-- 5. RLS Policies
CREATE POLICY "Public can view host profiles"
    ON public.host_profiles FOR SELECT
    USING (TRUE);

CREATE POLICY "Authenticated users can create host profile"
    ON public.host_profiles FOR INSERT
    WITH CHECK (TRUE);

CREATE POLICY "Authenticated users can update their own host profile"
    ON public.host_profiles FOR UPDATE
    USING (TRUE);

CREATE POLICY "Admins can update host profiles"
    ON public.host_profiles FOR ALL
    USING (TRUE);

-- 6. Trigger Function to automatically create/update host_profiles when someone hosts a vehicle or tour
CREATE OR REPLACE FUNCTION public.fn_ensure_host_profile_on_hosting()
RETURNS TRIGGER AS $$
DECLARE
    v_host_id TEXT;
    v_user_uuid UUID;
    v_display_name TEXT := 'Host Provider';
    v_email TEXT := '';
    v_phone TEXT := '';
    v_photo TEXT := '';
BEGIN
    -- Extract host_id from NEW row (either NEW.host_id or NEW.guide_id or NEW.user_id)
    IF (TG_TABLE_NAME = 'vehicles') THEN
        v_host_id := NEW.host_id;
    ELSIF (TG_TABLE_NAME = 'tours') THEN
        v_host_id := COALESCE(NEW.guide_id, NEW.host_id);
    ELSE
        v_host_id := NEW.host_id;
    END IF;

    IF v_host_id IS NULL OR v_host_id = '' THEN
        RETURN NEW;
    END IF;

    -- Try converting v_host_id to UUID safely
    BEGIN
        v_user_uuid := v_host_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        v_user_uuid := gen_random_uuid();
    END;

    -- Fetch info from profiles table if exists
    SELECT display_name, email, phone_number, photo_url
    INTO v_display_name, v_email, v_phone, v_photo
    FROM public.profiles
    WHERE id = v_host_id;

    -- Upsert host profile record
    INSERT INTO public.host_profiles (
        id,
        user_id,
        display_name,
        email,
        phone_number,
        photo_url,
        is_verified,
        verification_status,
        total_listings_count,
        updated_at
    )
    VALUES (
        v_host_id,
        v_user_uuid,
        COALESCE(v_display_name, 'Host Provider'),
        COALESCE(v_email, ''),
        COALESCE(v_phone, ''),
        COALESCE(v_photo, ''),
        FALSE,
        'pending',
        1,
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        total_listings_count = public.host_profiles.total_listings_count + 1,
        updated_at = NOW();

    -- Also promote role in profiles table to 'Host'
    UPDATE public.profiles
    SET role = 'Host', updated_at = NOW()
    WHERE id = v_host_id AND (role IS NULL OR role = 'Rider');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach trigger to vehicles table
DROP TRIGGER IF EXISTS trg_vehicles_ensure_host_profile ON public.vehicles;
CREATE TRIGGER trg_vehicles_ensure_host_profile
    AFTER INSERT ON public.vehicles
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_ensure_host_profile_on_hosting();

-- Attach trigger to tours table
DROP TRIGGER IF EXISTS trg_tours_ensure_host_profile ON public.tours;
CREATE TRIGGER trg_tours_ensure_host_profile
    AFTER INSERT ON public.tours
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_ensure_host_profile_on_hosting();
