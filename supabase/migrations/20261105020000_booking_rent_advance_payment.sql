-- Offline (walk-in) vehicle bookings: rent and advance are collected separately at
-- the counter, and the provider records which payment method the customer used.
-- total_price stays the full amount payable (rent + advance).
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS rent_amount numeric NOT NULL DEFAULT 0;
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS advance_amount numeric NOT NULL DEFAULT 0;
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS payment_method text NOT NULL DEFAULT '';
