-- ==============================================================================
-- Migration: Hotel Room Inventory & Available Rooms to Rent
-- Version: 20261014_hotel_room_inventory_and_available_rooms.sql
-- Enables hotel and homestay hosts to specify the exact number of rooms
-- available to rent, track property room capacity, and prevent overbooking.
-- ==============================================================================

-- 1. EXTEND HOTELS TABLE WITH ROOM INVENTORY COLUMNS
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS total_rooms INTEGER DEFAULT 1;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS available_rooms INTEGER DEFAULT 1;

-- 2. CREATE INDEX FOR AVAILABLE ROOM DISCOVERY
CREATE INDEX IF NOT EXISTS idx_hotels_available_rooms ON public.hotels(available_rooms);

-- 3. ENSURE POSITIVE ROOM INVARIANTS
DO $$
BEGIN
    UPDATE public.hotels 
    SET total_rooms = 1 
    WHERE total_rooms IS NULL OR total_rooms < 1;

    UPDATE public.hotels 
    SET available_rooms = total_rooms 
    WHERE available_rooms IS NULL;
END $$;

