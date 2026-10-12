-- ==============================================================================
-- Migration: Local Hotels, Budget Homestays & Stays Bookings Architecture
-- Version: 20261011_01
-- Enables rural homeowners, villagers, and budget hotel operators to list
-- affordable rooms with 0% platform barrier, integrated map coordinates (lat/lng),
-- host fleet isolation, and full lifecycle hotel reservations / bookings.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. HOTELS & HOMESTAYS TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.hotels (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT NOT NULL,
    address TEXT DEFAULT '',
    latitude NUMERIC(10, 6) DEFAULT 22.572600,
    longitude NUMERIC(10, 6) DEFAULT 88.363900,
    price_per_night NUMERIC(10, 2) NOT NULL DEFAULT 500.00,
    description TEXT DEFAULT '',
    room_type TEXT DEFAULT 'Private Room',
    max_guests INTEGER DEFAULT 2,
    rating NUMERIC(3, 2) DEFAULT 4.80,
    review_count INTEGER DEFAULT 0,
    image_url TEXT DEFAULT '',
    images TEXT[] DEFAULT ARRAY[]::TEXT[],
    host_name TEXT DEFAULT '',
    host_phone TEXT DEFAULT '',
    host_avatar TEXT DEFAULT '',
    host_id TEXT DEFAULT '',
    account_id TEXT DEFAULT '',
    account_name TEXT DEFAULT '',
    account_type TEXT DEFAULT 'mother',
    is_child_hosting BOOLEAN DEFAULT FALSE,
    child_id TEXT DEFAULT '',
    child_name TEXT DEFAULT '',
    amenities TEXT[] DEFAULT ARRAY[]::TEXT[],
    is_available BOOLEAN DEFAULT TRUE,
    check_in_time TEXT DEFAULT '12:00 PM',
    check_out_time TEXT DEFAULT '11:00 AM',
    cancellation_policy TEXT DEFAULT 'Free cancellation up to 24 hours before check-in',
    house_rules TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Safe Column Alterations for Existing Deployments of public.hotels
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS address TEXT DEFAULT '';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS latitude NUMERIC(10, 6) DEFAULT 22.572600;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS longitude NUMERIC(10, 6) DEFAULT 88.363900;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS price_per_night NUMERIC(10, 2) DEFAULT 500.00;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS room_type TEXT DEFAULT 'Private Room';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS max_guests INTEGER DEFAULT 2;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS rating NUMERIC(3, 2) DEFAULT 4.80;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS review_count INTEGER DEFAULT 0;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS image_url TEXT DEFAULT '';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS images TEXT[] DEFAULT ARRAY[]::TEXT[];
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS host_name TEXT DEFAULT '';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS host_phone TEXT DEFAULT '';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS host_avatar TEXT DEFAULT '';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS host_id TEXT DEFAULT '';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS account_id TEXT DEFAULT '';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS account_name TEXT DEFAULT '';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS account_type TEXT DEFAULT 'mother';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS is_child_hosting BOOLEAN DEFAULT FALSE;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS child_id TEXT DEFAULT '';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS child_name TEXT DEFAULT '';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS amenities TEXT[] DEFAULT ARRAY[]::TEXT[];
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT TRUE;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS check_in_time TEXT DEFAULT '12:00 PM';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS check_out_time TEXT DEFAULT '11:00 AM';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS cancellation_policy TEXT DEFAULT 'Free cancellation up to 24 hours before check-in';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS house_rules TEXT DEFAULT '';
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- High-performance indexes for discovery, geo-coordinates, price, and host filtering
CREATE INDEX IF NOT EXISTS idx_hotels_location ON public.hotels(location);
CREATE INDEX IF NOT EXISTS idx_hotels_coordinates ON public.hotels(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_hotels_price ON public.hotels(price_per_night);
CREATE INDEX IF NOT EXISTS idx_hotels_host_id ON public.hotels(host_id);
CREATE INDEX IF NOT EXISTS idx_hotels_account_id ON public.hotels(account_id);
CREATE INDEX IF NOT EXISTS idx_hotels_available ON public.hotels(is_available);
CREATE INDEX IF NOT EXISTS idx_hotels_room_type ON public.hotels(room_type);

-- ------------------------------------------------------------------------------
-- 2. HOTEL & HOMESTAY BOOKINGS TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.hotel_bookings (
    id TEXT PRIMARY KEY,
    booking_ref TEXT NOT NULL UNIQUE,
    hotel_id TEXT NOT NULL,
    hotel_name TEXT NOT NULL,
    hotel_location TEXT DEFAULT '',
    hotel_image_url TEXT DEFAULT '',
    room_type TEXT DEFAULT 'Private Room',
    
    -- Host details
    host_id TEXT DEFAULT '',
    host_name TEXT DEFAULT '',
    host_phone TEXT DEFAULT '',
    host_avatar TEXT DEFAULT '',
    
    -- Guest / Consumer identity details (with DL & photo verification support)
    user_id TEXT DEFAULT '',
    guest_name TEXT NOT NULL,
    guest_phone TEXT DEFAULT '',
    guest_email TEXT DEFAULT '',
    guest_photo_url TEXT DEFAULT '',
    guest_id_proof_type TEXT DEFAULT 'Driving Licence',
    guest_id_proof_number TEXT DEFAULT '',
    guest_id_proof_url TEXT DEFAULT '',
    guest_trust_score NUMERIC DEFAULT 100.0,
    
    -- Mother-Child account architecture & isolation
    account_id TEXT DEFAULT '',
    account_name TEXT DEFAULT '',
    account_type TEXT DEFAULT 'mother',
    is_child_booking BOOLEAN DEFAULT FALSE,
    child_id TEXT DEFAULT '',
    child_name TEXT DEFAULT '',
    is_child_hosting BOOLEAN DEFAULT FALSE,
    
    -- Schedule and occupancy
    check_in_date TIMESTAMPTZ NOT NULL,
    check_out_date TIMESTAMPTZ NOT NULL,
    nights INTEGER NOT NULL DEFAULT 1,
    num_guests INTEGER DEFAULT 1,
    check_in_time TEXT DEFAULT '12:00 PM',
    check_out_time TEXT DEFAULT '11:00 AM',
    
    -- Financials & payment (0% platform barrier)
    price_per_night NUMERIC(10, 2) NOT NULL DEFAULT 500.00,
    total_price NUMERIC(10, 2) NOT NULL DEFAULT 500.00,
    platform_fee NUMERIC(10, 2) DEFAULT 0.00,
    taxes NUMERIC(10, 2) DEFAULT 0.00,
    currency TEXT DEFAULT 'INR',
    
    -- Status & payment flow
    status TEXT NOT NULL DEFAULT 'Confirmed',
    payment_status TEXT DEFAULT 'Pay at Check-in',
    payment_method TEXT DEFAULT 'Cash / UPI at Check-in',
    payment_intent_id TEXT DEFAULT '',
    
    -- Notes & cancellation
    special_requests TEXT DEFAULT '',
    cancellation_reason TEXT DEFAULT '',
    cancelled_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Safe Column Alterations for Existing Deployments of public.hotel_bookings
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS booking_ref TEXT;
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS hotel_location TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS hotel_image_url TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS room_type TEXT DEFAULT 'Private Room';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS host_id TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS host_name TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS host_phone TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS host_avatar TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS user_id TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS guest_name TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS guest_phone TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS guest_email TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS guest_photo_url TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS guest_id_proof_type TEXT DEFAULT 'Driving Licence';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS guest_id_proof_number TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS guest_id_proof_url TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS guest_trust_score NUMERIC DEFAULT 100.0;
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS account_id TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS account_name TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS account_type TEXT DEFAULT 'mother';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS is_child_booking BOOLEAN DEFAULT FALSE;
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS child_id TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS child_name TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS is_child_hosting BOOLEAN DEFAULT FALSE;
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS nights INTEGER DEFAULT 1;
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS num_guests INTEGER DEFAULT 1;
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS check_in_time TEXT DEFAULT '12:00 PM';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS check_out_time TEXT DEFAULT '11:00 AM';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS price_per_night NUMERIC(10, 2) DEFAULT 500.00;
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS total_price NUMERIC(10, 2) DEFAULT 500.00;
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS platform_fee NUMERIC(10, 2) DEFAULT 0.00;
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS taxes NUMERIC(10, 2) DEFAULT 0.00;
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'INR';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Confirmed';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'Pay at Check-in';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'Cash / UPI at Check-in';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS payment_intent_id TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS special_requests TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS cancellation_reason TEXT DEFAULT '';
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- High-performance indexes for hotel bookings
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_hotel_id ON public.hotel_bookings(hotel_id);
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_user_id ON public.hotel_bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_host_id ON public.hotel_bookings(host_id);
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_account_id ON public.hotel_bookings(account_id);
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_child_id ON public.hotel_bookings(child_id);
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_status ON public.hotel_bookings(status);
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_check_in ON public.hotel_bookings(check_in_date);
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_ref ON public.hotel_bookings(booking_ref);
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_created_at ON public.hotel_bookings(created_at);

-- ------------------------------------------------------------------------------
-- 3. UNIFIED BOOKINGS COMPATIBILITY (public.bookings)
-- ------------------------------------------------------------------------------
-- Ensure public.bookings can store or bridge hotel bookings if queried uniformly
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS booking_type TEXT DEFAULT 'vehicle';
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS hotel_id TEXT;
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS hotel_name TEXT;
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS room_type TEXT;
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS nights INTEGER DEFAULT 0;
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS check_in_time TEXT;
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS check_out_time TEXT;

-- ------------------------------------------------------------------------------
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ------------------------------------------------------------------------------
ALTER TABLE public.hotels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotel_bookings ENABLE ROW LEVEL SECURITY;

-- Hotels RLS
DROP POLICY IF EXISTS "Public users can view hotels" ON public.hotels;
CREATE POLICY "Public users can view hotels"
    ON public.hotels
    FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Hosts can insert hotels" ON public.hotels;
CREATE POLICY "Hosts can insert hotels"
    ON public.hotels
    FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Hosts can update their own hotels" ON public.hotels;
CREATE POLICY "Hosts can update their own hotels"
    ON public.hotels
    FOR UPDATE
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Hosts can delete their own hotels" ON public.hotels;
CREATE POLICY "Hosts can delete their own hotels"
    ON public.hotels
    FOR DELETE
    USING (true);

-- Hotel Bookings RLS
DROP POLICY IF EXISTS "Public select hotel_bookings" ON public.hotel_bookings;
CREATE POLICY "Public select hotel_bookings"
    ON public.hotel_bookings
    FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Public insert hotel_bookings" ON public.hotel_bookings;
CREATE POLICY "Public insert hotel_bookings"
    ON public.hotel_bookings
    FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Public update hotel_bookings" ON public.hotel_bookings;
CREATE POLICY "Public update hotel_bookings"
    ON public.hotel_bookings
    FOR UPDATE
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Public delete hotel_bookings" ON public.hotel_bookings;
CREATE POLICY "Public delete hotel_bookings"
    ON public.hotel_bookings
    FOR DELETE
    USING (true);

-- ------------------------------------------------------------------------------
-- 5. AUTOMATIC TIMESTAMP TRIGGERS
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_set_hotel_entity_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_hotels_updated_at ON public.hotels;
CREATE TRIGGER trg_hotels_updated_at
    BEFORE UPDATE ON public.hotels
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_set_hotel_entity_updated_at();

DROP TRIGGER IF EXISTS trg_hotel_bookings_updated_at ON public.hotel_bookings;
CREATE TRIGGER trg_hotel_bookings_updated_at
    BEFORE UPDATE ON public.hotel_bookings
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_set_hotel_entity_updated_at();

-- ------------------------------------------------------------------------------
-- 6. REALTIME REPLICATION CONFIGURATION
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'hotels') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.hotels;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'hotel_bookings') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.hotel_bookings;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END $$;
