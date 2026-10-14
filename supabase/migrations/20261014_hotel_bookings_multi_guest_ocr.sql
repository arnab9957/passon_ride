-- ==============================================================================
-- PASSION RIDE: Multi-Guest Details & Aadhaar OCR Support for Hotel Bookings
-- Adds 'guests' JSONB column to store individual details for every guest
-- (Name, Aadhaar Number, Mobile Number, DOB, Address, ID Proof URL)
-- ==============================================================================

ALTER TABLE public.hotel_bookings 
ADD COLUMN IF NOT EXISTS guests JSONB DEFAULT '[]'::jsonb;

-- Comment for schema documentation
COMMENT ON COLUMN public.hotel_bookings.guests IS 'Array of guest details objects: [{"name": "...", "aadhar_number": "...", "mobile_number": "...", "dob": "...", "address": "...", "id_proof_url": "..."}]';

