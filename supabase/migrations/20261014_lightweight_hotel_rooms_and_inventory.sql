-- ==============================================================================
-- Migration: Lightweight Hotel Rooms, Blocked Ranges & Availability Engine
-- Version: 20261014_lightweight_hotel_rooms_and_inventory.sql
-- ==============================================================================

-- 1. HOTEL ROOMS TABLE
CREATE TABLE IF NOT EXISTS public.hotel_rooms (
    id TEXT PRIMARY KEY,
    hotel_id TEXT NOT NULL REFERENCES public.hotels(id) ON DELETE CASCADE,
    name TEXT NOT NULL,                                       -- e.g. "Deluxe Mountain View Room"
    room_type TEXT NOT NULL DEFAULT 'Private Room',           -- 'Private Room', 'Dorm Bed', 'Entire Cottage'
    base_price NUMERIC(10, 2) NOT NULL DEFAULT 500.00,
    weekend_price NUMERIC(10, 2),                             -- Optional peak/weekend rate
    extra_guest_fee NUMERIC(10, 2) DEFAULT 0.00,
    capacity INTEGER NOT NULL DEFAULT 2,
    quantity INTEGER NOT NULL DEFAULT 1,                      -- Total inventory count for this room category
    amenities TEXT[] DEFAULT ARRAY[]::TEXT[],
    images TEXT[] DEFAULT ARRAY[]::TEXT[],
    status TEXT NOT NULL DEFAULT 'clean',                     -- 'clean', 'dirty', 'maintenance', 'occupied'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hotel_rooms_hotel_id ON public.hotel_rooms(hotel_id);
CREATE INDEX IF NOT EXISTS idx_hotel_rooms_status ON public.hotel_rooms(status);

-- 2. BLOCKED RANGES TABLE (Store blackout dates / host holds without date bloat)
CREATE TABLE IF NOT EXISTS public.hotel_blocked_ranges (
    id TEXT PRIMARY KEY,
    room_id TEXT NOT NULL REFERENCES public.hotel_rooms(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT DEFAULT 'Host Hold / Maintenance',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_range CHECK (end_date >= start_date)
);

CREATE INDEX IF NOT EXISTS idx_blocked_ranges_lookup ON public.hotel_blocked_ranges(room_id, start_date, end_date);

-- 3. EXTEND HOTEL_BOOKINGS WITH ROOM REFERENCES & TIMESTAMPS
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS room_id TEXT;
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS room_count INTEGER DEFAULT 1;
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS checked_in_at TIMESTAMPTZ;
ALTER TABLE public.hotel_bookings ADD COLUMN IF NOT EXISTS checked_out_at TIMESTAMPTZ;

-- Composite index for fast date-overlap checks
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_room_overlap 
ON public.hotel_bookings(room_id, check_in_date, check_out_date)
WHERE status NOT IN ('Cancelled', 'Rejected');

-- 4. ATOMIC AVAILABILITY RPC FUNCTION (Compute, Don't Store)
CREATE OR REPLACE FUNCTION public.get_room_availability(
    p_room_id TEXT,
    p_check_in TIMESTAMPTZ,
    p_check_out TIMESTAMPTZ
)
RETURNS TABLE (
    total_quantity INT,
    booked_count INT,
    blocked_count INT,
    available_count INT
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_total_qty INT;
    v_booked_count INT;
    v_has_block BOOLEAN;
BEGIN
    SELECT COALESCE(quantity, 0) INTO v_total_qty
    FROM public.hotel_rooms
    WHERE id = p_room_id;

    -- Sum up booked rooms overlapping with the selected dates
    SELECT COALESCE(SUM(room_count), 0) INTO v_booked_count
    FROM public.hotel_bookings
    WHERE room_id = p_room_id
      AND status NOT IN ('Cancelled', 'Rejected')
      AND (check_in_date < p_check_out AND check_out_date > p_check_in);

    -- Check if host has an active block on this room during that date range
    SELECT EXISTS (
        SELECT 1 FROM public.hotel_blocked_ranges
        WHERE room_id = p_room_id
          AND (start_date < p_check_out::date AND end_date > p_check_in::date)
    ) INTO v_has_block;

    RETURN QUERY SELECT 
        v_total_qty,
        v_booked_count,
        CASE WHEN v_has_block THEN v_total_qty ELSE 0 END,
        CASE 
            WHEN v_has_block THEN 0
            ELSE GREATEST(0, v_total_qty - v_booked_count)
        END;
END;
$$;

-- 5. ROW-LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.hotel_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotel_blocked_ranges ENABLE ROW LEVEL SECURITY;

-- Public read for discovery & booking
DROP POLICY IF EXISTS "Public read hotel rooms" ON public.hotel_rooms;
CREATE POLICY "Public read hotel rooms" 
ON public.hotel_rooms FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read blocked ranges" ON public.hotel_blocked_ranges;
CREATE POLICY "Public read blocked ranges" 
ON public.hotel_blocked_ranges FOR SELECT USING (true);

-- Host write permissions
DROP POLICY IF EXISTS "Host manage rooms" ON public.hotel_rooms;
CREATE POLICY "Host manage rooms" 
ON public.hotel_rooms FOR ALL 
USING (auth.uid() IS NOT NULL) 
WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Host manage blocked ranges" ON public.hotel_blocked_ranges;
CREATE POLICY "Host manage blocked ranges" 
ON public.hotel_blocked_ranges FOR ALL 
USING (auth.uid() IS NOT NULL) 
WITH CHECK (auth.uid() IS NOT NULL);
