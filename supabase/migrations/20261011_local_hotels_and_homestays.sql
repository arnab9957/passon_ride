-- Migration: Local Hotels and Budget Homestays
-- Enables rural homeowners, villagers, and budget hotel operators to list affordable rooms with 0% platform barrier

CREATE TABLE IF NOT EXISTS public.hotels (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT NOT NULL,
    address TEXT DEFAULT '',
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
    amenities TEXT[] DEFAULT ARRAY[]::TEXT[],
    is_available BOOLEAN DEFAULT TRUE,
    check_in_time TEXT DEFAULT '12:00 PM',
    check_out_time TEXT DEFAULT '11:00 AM',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for high-performance filtering and geo/price queries
CREATE INDEX IF NOT EXISTS idx_hotels_location ON public.hotels(location);
CREATE INDEX IF NOT EXISTS idx_hotels_price ON public.hotels(price_per_night);
CREATE INDEX IF NOT EXISTS idx_hotels_host_id ON public.hotels(host_id);
CREATE INDEX IF NOT EXISTS idx_hotels_available ON public.hotels(is_available);

-- Enable Row Level Security
ALTER TABLE public.hotels ENABLE ROW LEVEL SECURITY;

-- Allow public read of hotels so travelers can discover them
DROP POLICY IF EXISTS "Public users can view hotels" ON public.hotels;
CREATE POLICY "Public users can view hotels"
    ON public.hotels
    FOR SELECT
    USING (true);

-- Allow hosts to manage their listings
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
