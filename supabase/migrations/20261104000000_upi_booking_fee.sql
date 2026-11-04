-- ₹10 UPI booking-fee payments (manual UPI Intent + UTR verification).
--
-- Flow: client asks the `upi-booking-fee` edge function to create a payment →
-- opens the UPI app (upi://pay…) → submits the UTR → an admin verifies it
-- against the merchant bank statement → booking is confirmed & provider notified.
--
-- Every write goes through the edge function (service role). Clients can only
-- READ their own rows, so nobody can mark their own payment as SUCCESS.
-- The fee is a non-refundable PassionRide fee, refunded only if the provider rejects.

-- ---------------------------------------------------------------------------
-- Booking columns
-- ---------------------------------------------------------------------------
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS booking_fee        NUMERIC(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS remaining_amount   NUMERIC(12,2),
  ADD COLUMN IF NOT EXISTS fee_payment_status TEXT NOT NULL DEFAULT 'NOT_REQUIRED',
  ADD COLUMN IF NOT EXISTS provider_payment_status TEXT NOT NULL DEFAULT 'UNPAID';

ALTER TABLE public.hotel_bookings
  ADD COLUMN IF NOT EXISTS booking_fee        NUMERIC(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS remaining_amount   NUMERIC(12,2),
  ADD COLUMN IF NOT EXISTS fee_payment_status TEXT NOT NULL DEFAULT 'NOT_REQUIRED',
  ADD COLUMN IF NOT EXISTS provider_payment_status TEXT NOT NULL DEFAULT 'UNPAID';

-- ---------------------------------------------------------------------------
-- Payments
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.booking_fee_payments (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_ref        TEXT NOT NULL UNIQUE,              -- sent to UPI as `tr`
  booking_kind       TEXT NOT NULL CHECK (booking_kind IN ('vehicle', 'tour', 'stay')),
  booking_id         TEXT NOT NULL,
  user_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  host_id            TEXT,
  amount             NUMERIC(10,2) NOT NULL CHECK (amount > 0),
  currency           TEXT NOT NULL DEFAULT 'INR',
  payment_method     TEXT NOT NULL DEFAULT 'UPI',
  payee_vpa          TEXT NOT NULL,
  utr                TEXT UNIQUE,                       -- bank transaction reference
  provider_reference TEXT,                              -- acquirer ref (future webhook)
  payment_status     TEXT NOT NULL DEFAULT 'PENDING'
                     CHECK (payment_status IN ('CREATED','PENDING','SUBMITTED','SUCCESS','FAILED',
                                               'EXPIRED','REFUND_PENDING','REFUNDED')),
  failure_reason     TEXT,
  verified_by        UUID REFERENCES auth.users(id),
  verified_at        TIMESTAMPTZ,
  expires_at         TIMESTAMPTZ NOT NULL DEFAULT now() + interval '30 minutes',
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT utr_format CHECK (utr IS NULL OR utr ~ '^[0-9]{12}$')
);

-- At most one live (not failed/expired) payment per booking: no double collection.
CREATE UNIQUE INDEX IF NOT EXISTS booking_fee_payments_one_live_per_booking
  ON public.booking_fee_payments (booking_kind, booking_id)
  WHERE payment_status IN ('CREATED','PENDING','SUBMITTED','SUCCESS');
CREATE INDEX IF NOT EXISTS booking_fee_payments_user_idx   ON public.booking_fee_payments (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS booking_fee_payments_status_idx ON public.booking_fee_payments (payment_status, created_at);

-- ---------------------------------------------------------------------------
-- Audit trail (append-only)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payment_events (
  id          BIGSERIAL PRIMARY KEY,
  payment_id  UUID NOT NULL REFERENCES public.booking_fee_payments(id) ON DELETE CASCADE,
  event_type  TEXT NOT NULL,   -- PAYMENT_CREATED, PAYMENT_INITIATED, UTR_SUBMITTED, PAYMENT_SUCCESS, ...
  actor_id    UUID,
  details     JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS payment_events_payment_idx ON public.payment_events (payment_id, created_at);

CREATE OR REPLACE FUNCTION public.payment_events_immutable()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'payment_events is append-only';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payment_events_no_update ON public.payment_events;
CREATE TRIGGER payment_events_no_update
  BEFORE UPDATE OR DELETE ON public.payment_events
  FOR EACH ROW EXECUTE FUNCTION public.payment_events_immutable();

-- ---------------------------------------------------------------------------
-- Refunds
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payment_refunds (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id       UUID NOT NULL REFERENCES public.booking_fee_payments(id) ON DELETE CASCADE,
  refund_amount    NUMERIC(10,2) NOT NULL CHECK (refund_amount > 0),
  refund_reason    TEXT NOT NULL,
  refund_status    TEXT NOT NULL DEFAULT 'PENDING' CHECK (refund_status IN ('PENDING','COMPLETED','FAILED')),
  refund_reference TEXT,
  created_by       UUID REFERENCES auth.users(id),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS payment_refunds_one_per_payment ON public.payment_refunds (payment_id);

-- ---------------------------------------------------------------------------
-- RLS: read-only for owners (and admins); all writes via service role.
-- ---------------------------------------------------------------------------
ALTER TABLE public.booking_fee_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_events       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_refunds      ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "fee payments: owner or admin read" ON public.booking_fee_payments;
CREATE POLICY "fee payments: owner or admin read" ON public.booking_fee_payments
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "payment events: owner or admin read" ON public.payment_events;
CREATE POLICY "payment events: owner or admin read" ON public.payment_events
  FOR SELECT USING (
    public.is_admin() OR EXISTS (
      SELECT 1 FROM public.booking_fee_payments p WHERE p.id = payment_id AND p.user_id = auth.uid()));

DROP POLICY IF EXISTS "refunds: owner or admin read" ON public.payment_refunds;
CREATE POLICY "refunds: owner or admin read" ON public.payment_refunds
  FOR SELECT USING (
    public.is_admin() OR EXISTS (
      SELECT 1 FROM public.booking_fee_payments p WHERE p.id = payment_id AND p.user_id = auth.uid()));

REVOKE INSERT, UPDATE, DELETE ON public.booking_fee_payments, public.payment_events, public.payment_refunds
  FROM anon, authenticated;

-- Live status on the customer's payment screen.
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_fee_payments;
EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL;
END $$;
