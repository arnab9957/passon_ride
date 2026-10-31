-- The app sends these on every vehicle booking; without them the insert is rejected.
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS customer_driving_license_number TEXT DEFAULT '';
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS customer_driving_license_url TEXT DEFAULT '';
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS customer_driving_license_type TEXT DEFAULT '';
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS customer_driving_license_expiry TEXT DEFAULT '';
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS customer_live_photo_url TEXT DEFAULT '';

NOTIFY pgrst, 'reload schema';
