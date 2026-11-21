-- Offline-booking KYC photos taken by the provider:
-- the renter with the vehicle at handover, and their Aadhaar / passport.
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS handover_photo_url text NOT NULL DEFAULT '';
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS customer_id_proof_url text NOT NULL DEFAULT '';
