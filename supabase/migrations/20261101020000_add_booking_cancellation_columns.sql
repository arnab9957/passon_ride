-- The app records who cancelled and why; without these columns the update is rejected.
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS cancelled_by TEXT DEFAULT '';
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS cancellation_reason TEXT DEFAULT '';
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS rental_ended_at TIMESTAMPTZ;

NOTIFY pgrst, 'reload schema';
