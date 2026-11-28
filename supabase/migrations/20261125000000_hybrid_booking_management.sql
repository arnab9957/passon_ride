-- Hybrid booking management: automatic / manual confirmation, overlap-safe
-- availability, audited status lifecycle, and locked-down bookings RLS.
--
-- Non-destructive: only adds columns, tables and functions. The four open
-- "Public ... bookings" policies (USING true) are replaced with party-scoped
-- ones. No rows are deleted. Existing bookings that already overlap keep
-- existing, but are excluded from the new overlap constraint
-- (overlap_enforced = false) so the constraint can be created.
--
-- Status vocabulary (kept compatible with the app's existing values):
--   Pending   waiting for the owner (and/or the ₹10 booking fee)
--   Confirmed reserved, blocks the vehicle
--   Active    ongoing rental (shown as "Ongoing"), blocks the vehicle
--   Completed vehicle returned
--   Rejected  owner declined, or another request for the slot was accepted
--   Cancelled cancelled by renter / owner
--   Expired   request never decided before pickup time
--
-- All status changes go through these SECURITY DEFINER functions:
--   create_vehicle_booking(jsonb, boolean)   renter creates a booking
--   transition_booking(text, text, text)     accept / reject / start / complete / cancel
--   set_booking_preferences(boolean, boolean) owner auto-confirm + accepting toggle
--   get_vehicle_busy_slots()                 public availability, no personal data
--   apply_booking_fee_paid(text)             service role only (upi-booking-fee)

CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ---------------------------------------------------------------------------
-- 1. Columns
-- ---------------------------------------------------------------------------
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS booking_reference  TEXT,
  ADD COLUMN IF NOT EXISTS confirmation_type  TEXT,
  ADD COLUMN IF NOT EXISTS pickup_location    TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS decided_at         TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS decided_by         TEXT,
  ADD COLUMN IF NOT EXISTS rejection_reason   TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS rental_started_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS overlap_enforced   BOOLEAN NOT NULL DEFAULT TRUE;

DO $$ BEGIN
  ALTER TABLE public.bookings ADD CONSTRAINT bookings_confirmation_type_chk
    CHECK (confirmation_type IS NULL OR confirmation_type IN ('AUTOMATIC', 'MANUAL'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- NOT VALID: new and updated rows must use a known status; legacy rows are left alone.
DO $$ BEGIN
  ALTER TABLE public.bookings ADD CONSTRAINT bookings_status_chk
    CHECK (initcap(lower(status)) IN ('Pending','Confirmed','Active','Completed','Rejected','Cancelled','Expired')) NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE public.host_profiles
  ADD COLUMN IF NOT EXISTS auto_confirm_bookings BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS accepting_bookings    BOOLEAN NOT NULL DEFAULT TRUE;

-- Pickup / return times are shown in the vehicle's local time zone.
ALTER TABLE public.vehicles
  ADD COLUMN IF NOT EXISTS timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata';

-- ---------------------------------------------------------------------------
-- 2. Booking reference (PR-XXXXXXXX, no 0/O/1/I)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_booking_reference()
RETURNS TEXT AS $$
DECLARE
  v_alphabet CONSTANT TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_ref TEXT;
BEGIN
  LOOP
    SELECT 'PR-' || string_agg(substr(v_alphabet, 1 + floor(random() * 32)::int, 1), '')
      INTO v_ref FROM generate_series(1, 8);
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.bookings WHERE booking_reference = v_ref);
  END LOOP;
  RETURN v_ref;
END;
$$ LANGUAGE plpgsql VOLATILE SET search_path = public;

UPDATE public.bookings SET booking_reference = public.generate_booking_reference()
WHERE booking_reference IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS bookings_booking_reference_key ON public.bookings (booking_reference);

-- ---------------------------------------------------------------------------
-- 3. Overlap protection: no two Confirmed/Active bookings of one vehicle overlap.
-- ---------------------------------------------------------------------------
-- Rows that cannot form a range, or already overlap an earlier blocking booking,
-- are kept but not enforced. For each overlapping pair the earliest-created stays enforced.
UPDATE public.bookings SET overlap_enforced = FALSE
WHERE overlap_enforced
  AND (start_date IS NULL OR end_date IS NULL OR end_date <= start_date);

UPDATE public.bookings b SET overlap_enforced = FALSE
WHERE b.overlap_enforced
  AND lower(b.status) IN ('confirmed', 'active')
  AND COALESCE(b.booking_type, 'vehicle') <> 'tour'
  AND EXISTS (
    SELECT 1 FROM public.bookings o
    WHERE o.vehicle_id = b.vehicle_id
      AND o.id <> b.id
      AND o.overlap_enforced
      AND lower(o.status) IN ('confirmed', 'active')
      AND COALESCE(o.booking_type, 'vehicle') <> 'tour'
      AND o.start_date IS NOT NULL AND o.end_date > o.start_date
      AND tstzrange(o.start_date, o.end_date, '[)') && tstzrange(b.start_date, b.end_date, '[)')
      AND (o.created_at, o.id) < (b.created_at, b.id));

DO $$ BEGIN
  ALTER TABLE public.bookings ADD CONSTRAINT bookings_no_overlapping_vehicle_rentals
    EXCLUDE USING gist (vehicle_id WITH =, tstzrange(start_date, end_date, '[)') WITH &&)
    WHERE (overlap_enforced
           AND vehicle_id IS NOT NULL
           AND COALESCE(booking_type, 'vehicle') <> 'tour'
           AND lower(status) IN ('confirmed', 'active'));
EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS bookings_vehicle_status_idx ON public.bookings (vehicle_id, status, start_date);
CREATE INDEX IF NOT EXISTS bookings_rider_idx ON public.bookings (rider_id, created_at DESC);
CREATE INDEX IF NOT EXISTS bookings_host_idx  ON public.bookings (host_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- 4. Account helpers (login id, mother id or child id → owning logins)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.account_login_ids(p_account_id TEXT)
RETURNS SETOF TEXT AS $$
  SELECT p_account_id WHERE COALESCE(p_account_id, '') <> ''
  UNION
  SELECT m.customer_id FROM public.mother_profile m WHERE m.mother_id = p_account_id
  UNION
  SELECT m.customer_id FROM public.child_profile c
  JOIN public.mother_profile m ON m.mother_id = c.mother_id
  WHERE c.child_id = p_account_id;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.owns_account_id(p_account_id TEXT)
RETURNS BOOLEAN AS $$
  SELECT auth.uid() IS NOT NULL
     AND auth.uid()::text IN (SELECT public.account_login_ids(p_account_id));
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- The provider profile that governs an owner account (child hosts use their mother's).
CREATE OR REPLACE FUNCTION public.owner_booking_settings(p_host_id TEXT,
  OUT is_verified BOOLEAN, OUT auto_confirm BOOLEAN, OUT accepting BOOLEAN)
AS $$
  SELECT COALESCE(bool_or(hp.is_verified), FALSE),
         COALESCE(bool_or(hp.is_verified AND hp.auto_confirm_bookings), FALSE),
         COALESCE(bool_and(hp.accepting_bookings), TRUE)
  FROM public.host_profiles hp
  WHERE hp.id IN (SELECT public.account_login_ids(p_host_id));
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- 5. Owner settings: auto-confirm requires (and is lost with) verification
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enforce_auto_confirm_requires_verification()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.auto_confirm_bookings AND NOT COALESCE(NEW.is_verified, FALSE) THEN
    NEW.auto_confirm_bookings := FALSE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Named to fire after trg_protect_host_verification (triggers run alphabetically).
DROP TRIGGER IF EXISTS trg_zz_auto_confirm_requires_verification ON public.host_profiles;
CREATE TRIGGER trg_zz_auto_confirm_requires_verification
BEFORE INSERT OR UPDATE ON public.host_profiles
FOR EACH ROW EXECUTE FUNCTION public.enforce_auto_confirm_requires_verification();

CREATE OR REPLACE FUNCTION public.set_booking_preferences(
  p_auto_confirm BOOLEAN DEFAULT NULL,
  p_accepting BOOLEAN DEFAULT NULL)
RETURNS JSONB AS $$
DECLARE
  v_hp public.host_profiles;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'NOT_SIGNED_IN' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_hp FROM public.host_profiles WHERE id = auth.uid()::text FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_PROVIDER_PROFILE' USING ERRCODE = 'P0002';
  END IF;
  IF p_auto_confirm AND NOT v_hp.is_verified THEN
    RAISE EXCEPTION 'VERIFICATION_REQUIRED' USING ERRCODE = '42501',
      HINT = 'Only verified owners can enable automatic confirmation.';
  END IF;
  UPDATE public.host_profiles
     SET auto_confirm_bookings = COALESCE(p_auto_confirm, auto_confirm_bookings),
         accepting_bookings    = COALESCE(p_accepting, accepting_bookings),
         updated_at = now()
   WHERE id = v_hp.id
  RETURNING * INTO v_hp;
  RETURN jsonb_build_object(
    'is_verified', v_hp.is_verified,
    'auto_confirm_bookings', v_hp.auto_confirm_bookings,
    'accepting_bookings', v_hp.accepting_bookings);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- 6. Status history (append-only, written by trigger so no path can skip it)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.booking_status_history (
  id          BIGSERIAL PRIMARY KEY,
  booking_id  TEXT NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  from_status TEXT,
  to_status   TEXT NOT NULL,
  changed_by  UUID,
  note        TEXT NOT NULL DEFAULT '',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS booking_status_history_booking_idx
  ON public.booking_status_history (booking_id, created_at);

CREATE OR REPLACE FUNCTION public.record_booking_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' OR NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO public.booking_status_history (booking_id, from_status, to_status, changed_by, note)
    VALUES (NEW.id, CASE WHEN TG_OP = 'UPDATE' THEN OLD.status END, NEW.status, auth.uid(),
            COALESCE(NULLIF(current_setting('passon.booking_note', true), ''), ''));
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_record_booking_status_change ON public.bookings;
CREATE TRIGGER trg_record_booking_status_change
AFTER INSERT OR UPDATE OF status ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.record_booking_status_change();

CREATE OR REPLACE FUNCTION public.booking_status_history_immutable()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'booking_status_history is append-only';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS booking_status_history_no_update ON public.booking_status_history;
CREATE TRIGGER booking_status_history_no_update
BEFORE UPDATE ON public.booking_status_history
FOR EACH ROW EXECUTE FUNCTION public.booking_status_history_immutable();

-- ---------------------------------------------------------------------------
-- 7. Write guard: protected columns change only inside the booking functions
-- ---------------------------------------------------------------------------
-- SECURITY INVOKER on purpose: current_user is then the caller's role, so only the
-- app-facing roles are guarded and SQL-editor / service maintenance still works.
CREATE OR REPLACE FUNCTION public.guard_booking_writes()
RETURNS TRIGGER AS $$
BEGIN
  IF current_setting('passon.booking_rpc', true) = 'on'
     OR current_user NOT IN ('anon', 'authenticated')
     OR auth.role() = 'service_role' OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    NEW.booking_reference := NULL;   -- always server-generated
    NEW.confirmation_type := NULL;
    NEW.overlap_enforced := TRUE;
    -- A direct "tour" insert must really be for a tour, not a vehicle in disguise.
    IF COALESCE(NEW.booking_type, 'vehicle') = 'tour'
       AND NOT public.owns_account_id(NEW.host_id)
       AND NOT EXISTS (SELECT 1 FROM public.tours t WHERE t.id::text = NEW.vehicle_id) THEN
      RAISE EXCEPTION 'Vehicle bookings must be created with create_vehicle_booking()'
        USING ERRCODE = '42501';
    END IF;
    RETURN NEW;
  END IF;

  IF NEW.status IS DISTINCT FROM OLD.status
     OR NEW.booking_reference IS DISTINCT FROM OLD.booking_reference
     OR NEW.confirmation_type IS DISTINCT FROM OLD.confirmation_type
     OR NEW.overlap_enforced IS DISTINCT FROM OLD.overlap_enforced
     OR NEW.decided_at IS DISTINCT FROM OLD.decided_at
     OR NEW.decided_by IS DISTINCT FROM OLD.decided_by
     OR NEW.fee_payment_status IS DISTINCT FROM OLD.fee_payment_status
     OR NEW.booking_fee IS DISTINCT FROM OLD.booking_fee THEN
    RAISE EXCEPTION 'Booking status can only change through transition_booking()'
      USING ERRCODE = '42501';
  END IF;

  -- Owners may correct their own counter (offline) records; nobody else may move
  -- a booking to another renter, owner, vehicle, period or price.
  IF NOT (public.owns_account_id(OLD.host_id) AND public.owns_account_id(OLD.rider_id))
     AND (NEW.rider_id IS DISTINCT FROM OLD.rider_id
       OR NEW.host_id IS DISTINCT FROM OLD.host_id
       OR NEW.vehicle_id IS DISTINCT FROM OLD.vehicle_id
       OR NEW.booking_type IS DISTINCT FROM OLD.booking_type
       OR NEW.start_date IS DISTINCT FROM OLD.start_date
       OR NEW.end_date IS DISTINCT FROM OLD.end_date
       OR NEW.total_price IS DISTINCT FROM OLD.total_price
       OR NEW.remaining_amount IS DISTINCT FROM OLD.remaining_amount
       OR NEW.provider_payment_status IS DISTINCT FROM OLD.provider_payment_status
       OR NEW.payment_intent_id IS DISTINCT FROM OLD.payment_intent_id) THEN
    RAISE EXCEPTION 'Booking parties, dates and amounts cannot be changed'
      USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

DROP TRIGGER IF EXISTS trg_guard_booking_writes ON public.bookings;
CREATE TRIGGER trg_guard_booking_writes
BEFORE INSERT OR UPDATE ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.guard_booking_writes();

CREATE OR REPLACE FUNCTION public.set_booking_reference()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.booking_reference IS NULL THEN
    NEW.booking_reference := public.generate_booking_reference();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Runs after the guard (alphabetical), so even guarded inserts get a reference.
DROP TRIGGER IF EXISTS trg_set_booking_reference ON public.bookings;
CREATE TRIGGER trg_set_booking_reference
BEFORE INSERT ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.set_booking_reference();

-- ---------------------------------------------------------------------------
-- 8. Row Level Security: only the booking's parties (and admins)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_booking_party(b public.bookings)
RETURNS BOOLEAN AS $$
  SELECT public.owns_account_id(b.rider_id)
      OR public.owns_account_id(b.host_id)
      OR public.owns_account_id(b.account_id)
      OR public.owns_account_id(b.child_id);
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

DROP POLICY IF EXISTS "Public select bookings" ON public.bookings;
DROP POLICY IF EXISTS "Public insert bookings" ON public.bookings;
DROP POLICY IF EXISTS "Public update bookings" ON public.bookings;
DROP POLICY IF EXISTS "Public delete bookings" ON public.bookings;

DROP POLICY IF EXISTS "bookings: parties read" ON public.bookings;
CREATE POLICY "bookings: parties read" ON public.bookings
  FOR SELECT USING (public.is_admin() OR public.is_booking_party(bookings));

-- Renters create vehicle bookings via create_vehicle_booking(). Direct inserts are
-- an owner's own counter booking, or a renter's tour booking.
DROP POLICY IF EXISTS "bookings: owner records or renter tour insert" ON public.bookings;
CREATE POLICY "bookings: owner records or renter tour insert" ON public.bookings
  FOR INSERT WITH CHECK (
    public.is_admin()
    OR (public.owns_account_id(host_id) AND public.owns_account_id(rider_id))
    OR (COALESCE(booking_type, 'vehicle') = 'tour' AND public.owns_account_id(rider_id)));

DROP POLICY IF EXISTS "bookings: parties update details" ON public.bookings;
CREATE POLICY "bookings: parties update details" ON public.bookings
  FOR UPDATE USING (public.is_admin() OR public.is_booking_party(bookings))
  WITH CHECK (public.is_admin() OR public.is_booking_party(bookings));

DROP POLICY IF EXISTS "bookings: owner deletes own records" ON public.bookings;
CREATE POLICY "bookings: owner deletes own records" ON public.bookings
  FOR DELETE USING (
    public.is_admin()
    OR (public.owns_account_id(host_id) AND public.owns_account_id(rider_id)));

REVOKE ALL ON public.bookings FROM anon;

ALTER TABLE public.booking_status_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "booking history: parties read" ON public.booking_status_history;
CREATE POLICY "booking history: parties read" ON public.booking_status_history
  FOR SELECT USING (
    public.is_admin() OR EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = booking_id AND public.is_booking_party(b)));
REVOKE INSERT, UPDATE, DELETE ON public.booking_status_history FROM anon, authenticated;

-- ---------------------------------------------------------------------------
-- 9. Availability (public, no personal data)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_vehicle_busy_slots(p_vehicle_id TEXT DEFAULT NULL)
RETURNS TABLE (vehicle_id TEXT, start_date TIMESTAMPTZ, end_date TIMESTAMPTZ) AS $$
  SELECT b.vehicle_id, b.start_date, b.end_date
  FROM public.bookings b
  WHERE lower(b.status) IN ('confirmed', 'active')
    AND COALESCE(b.booking_type, 'vehicle') <> 'tour'
    AND b.vehicle_id IS NOT NULL
    AND b.end_date > now()
    AND (p_vehicle_id IS NULL OR b.vehicle_id = p_vehicle_id)
  ORDER BY b.start_date;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.vehicle_slot_taken(
  p_vehicle_id TEXT, p_start TIMESTAMPTZ, p_end TIMESTAMPTZ, p_except_id TEXT DEFAULT NULL)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.bookings b
    WHERE b.vehicle_id = p_vehicle_id
      AND b.id IS DISTINCT FROM p_except_id
      AND lower(b.status) IN ('confirmed', 'active')
      AND COALESCE(b.booking_type, 'vehicle') <> 'tour'
      AND b.start_date < p_end AND b.end_date > p_start);
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- 10. Create a vehicle booking
-- ---------------------------------------------------------------------------
-- p_booking is the app's booking row as JSON (KYC fields, photos, contact).
-- The server decides: owner, vehicle details, status, confirmation type, reference.
CREATE OR REPLACE FUNCTION public.create_vehicle_booking(
  p_booking JSONB,
  p_awaiting_fee BOOLEAN DEFAULT FALSE)
RETURNS public.bookings AS $$
DECLARE
  v_row      public.bookings;
  v_existing public.bookings;
  v_vehicle  RECORD;
  v_settings RECORD;
  v_auto     BOOLEAN;
  v_json     JSONB;
  v_cols     TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'NOT_SIGNED_IN' USING ERRCODE = '42501';
  END IF;

  v_row := jsonb_populate_record(NULL::public.bookings, p_booking);

  IF v_row.id IS NULL OR v_row.id !~ '^b_[0-9A-Za-z_]{6,64}$' THEN
    v_row.id := 'b_' || replace(gen_random_uuid()::text, '-', '');
  END IF;
  IF COALESCE(v_row.rider_id, '') = '' THEN
    v_row.rider_id := auth.uid()::text;
  END IF;
  IF NOT public.owns_account_id(v_row.rider_id) THEN
    RAISE EXCEPTION 'NOT_YOUR_ACCOUNT' USING ERRCODE = '42501';
  END IF;

  -- Repeated submission (double tap, retry after timeout): return the first booking.
  SELECT * INTO v_existing FROM public.bookings WHERE id = v_row.id;
  IF FOUND THEN
    IF NOT public.owns_account_id(v_existing.rider_id) THEN
      RAISE EXCEPTION 'DUPLICATE_ID' USING ERRCODE = '23505';
    END IF;
    RETURN v_existing;
  END IF;

  IF v_row.start_date IS NULL OR v_row.end_date IS NULL OR v_row.end_date <= v_row.start_date THEN
    RAISE EXCEPTION 'INVALID_PERIOD' USING ERRCODE = '22023',
      HINT = 'Return time must be after pickup time.';
  END IF;
  IF v_row.start_date < now() - interval '15 minutes' THEN
    RAISE EXCEPTION 'PICKUP_IN_PAST' USING ERRCODE = '22023';
  END IF;
  IF COALESCE(v_row.total_price, 0) < 0 THEN
    RAISE EXCEPTION 'INVALID_AMOUNT' USING ERRCODE = '22023';
  END IF;

  -- Lock the vehicle: concurrent requests for one vehicle are handled one at a time.
  SELECT v.id::text AS id, v.title, v.image_url, v.status, v.location,
         COALESCE(NULLIF(v.host_id::text, ''), NULLIF(v.owner_account_id, '')) AS host_id,
         v.host_name
    INTO v_vehicle
    FROM public.vehicles v WHERE v.id::text = v_row.vehicle_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'VEHICLE_NOT_FOUND' USING ERRCODE = 'P0002';
  END IF;
  IF lower(COALESCE(v_vehicle.status, '')) IN ('maintenance', 'archived', 'inactive', 'suspended', 'unavailable') THEN
    RAISE EXCEPTION 'VEHICLE_INACTIVE' USING ERRCODE = '22023';
  END IF;
  IF COALESCE(v_vehicle.host_id, '') = '' THEN
    RAISE EXCEPTION 'VEHICLE_HAS_NO_OWNER' USING ERRCODE = '22023';
  END IF;
  IF public.owns_account_id(v_vehicle.host_id) THEN
    RAISE EXCEPTION 'OWN_VEHICLE' USING ERRCODE = '22023',
      HINT = 'Use "Record offline booking" for your own vehicles.';
  END IF;

  SELECT * INTO v_settings FROM public.owner_booking_settings(v_vehicle.host_id);
  IF NOT v_settings.accepting THEN
    RAISE EXCEPTION 'OWNER_NOT_ACCEPTING' USING ERRCODE = '22023';
  END IF;
  IF public.vehicle_slot_taken(v_vehicle.id, v_row.start_date, v_row.end_date) THEN
    RAISE EXCEPTION 'VEHICLE_UNAVAILABLE' USING ERRCODE = '23P01';
  END IF;

  -- Same renter, same vehicle, same period, still open: treat as a repeat.
  SELECT * INTO v_existing FROM public.bookings
   WHERE rider_id = v_row.rider_id AND vehicle_id = v_vehicle.id
     AND start_date = v_row.start_date AND end_date = v_row.end_date
     AND status IN ('Pending', 'Confirmed')
   LIMIT 1;
  IF FOUND THEN
    RETURN v_existing;
  END IF;

  v_auto := v_settings.is_verified AND v_settings.auto_confirm;

  v_row.booking_type      := 'vehicle';
  v_row.vehicle_id        := v_vehicle.id;
  v_row.vehicle_title     := v_vehicle.title;
  v_row.vehicle_image_url := COALESCE(NULLIF(v_vehicle.image_url, ''), v_row.vehicle_image_url);
  v_row.host_id           := v_vehicle.host_id;
  v_row.host_name         := COALESCE(NULLIF(v_vehicle.host_name, ''), v_row.host_name);
  v_row.pickup_location   := COALESCE(NULLIF(v_row.pickup_location, ''), v_vehicle.location, '');
  v_row.confirmation_type := CASE WHEN v_auto THEN 'AUTOMATIC' ELSE 'MANUAL' END;
  -- Auto-confirmed only once nothing else is outstanding (the ₹10 fee is confirmed later).
  v_row.status            := CASE WHEN v_auto AND NOT p_awaiting_fee THEN 'Confirmed' ELSE 'Pending' END;
  v_row.booking_reference := NULL;
  v_row.overlap_enforced  := TRUE;
  v_row.decided_at        := CASE WHEN v_row.status = 'Confirmed' THEN now() END;
  v_row.decided_by        := CASE WHEN v_row.status = 'Confirmed' THEN 'system:auto' END;
  v_row.rejection_reason  := '';
  v_row.cancelled_by      := '';
  v_row.cancellation_reason := '';
  v_row.cancelled_at      := NULL;
  v_row.rental_started_at := NULL;
  v_row.rental_ended_at   := NULL;
  v_row.booking_fee       := 0;
  v_row.fee_payment_status := 'NOT_REQUIRED';
  v_row.provider_payment_status := 'UNPAID';
  v_row.remaining_amount  := NULL;
  v_row.created_at        := now();
  v_row.updated_at        := now();

  PERFORM set_config('passon.booking_rpc', 'on', true);
  PERFORM set_config('passon.booking_note',
    CASE WHEN v_row.status = 'Confirmed' THEN 'Automatically confirmed'
         WHEN v_auto THEN 'Awaiting booking fee'
         ELSE 'Awaiting owner approval' END, true);
  -- Insert only the columns that have a value, so every other column gets its default.
  v_json := jsonb_strip_nulls(to_jsonb(v_row));
  SELECT string_agg(quote_ident(k), ', ') INTO v_cols FROM jsonb_object_keys(v_json) AS k;
  BEGIN
    EXECUTE format(
      'INSERT INTO public.bookings (%1$s) SELECT %1$s FROM jsonb_populate_record(NULL::public.bookings, $1) RETURNING *',
      v_cols)
    INTO v_row USING v_json;
  EXCEPTION WHEN exclusion_violation THEN
    RAISE EXCEPTION 'VEHICLE_UNAVAILABLE' USING ERRCODE = '23P01';
  END;
  PERFORM set_config('passon.booking_rpc', 'off', true);
  RETURN v_row;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- 11. Status transitions
-- ---------------------------------------------------------------------------
--   Pending   → Confirmed  owner          (fee paid or not required; slot free)
--   Pending   → Rejected   owner
--   Pending   → Cancelled  renter, owner
--   Confirmed → Active     owner, renter  (handover / keyless unlock)
--   Confirmed → Cancelled  owner; renter only before pickup time
--   Active    → Completed  owner, renter
--   Pending   → Expired    system (cron)
-- Admins may make any of these.
CREATE OR REPLACE FUNCTION public.transition_booking(
  p_booking_id TEXT,
  p_to_status TEXT,
  p_note TEXT DEFAULT '')
RETURNS public.bookings AS $$
DECLARE
  v_b       public.bookings;
  v_admin   BOOLEAN := public.is_admin();
  v_owner   BOOLEAN;
  v_renter  BOOLEAN;
  v_from    TEXT;
  v_to      TEXT := initcap(lower(trim(p_to_status)));
  v_allowed BOOLEAN := FALSE;
  v_other   RECORD;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'NOT_SIGNED_IN' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_b FROM public.bookings WHERE id = p_booking_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BOOKING_NOT_FOUND' USING ERRCODE = 'P0002';
  END IF;
  -- Lock order: vehicle, then booking (same as create_vehicle_booking).
  PERFORM 1 FROM public.vehicles WHERE id::text = v_b.vehicle_id FOR UPDATE;
  SELECT * INTO v_b FROM public.bookings WHERE id = p_booking_id FOR UPDATE;

  -- COALESCE: a NULL here would otherwise slip past the permission checks below.
  v_owner  := COALESCE(public.owns_account_id(v_b.host_id)
              OR (COALESCE(v_b.is_child_hosting, FALSE) AND public.owns_account_id(v_b.child_id)), FALSE);
  v_renter := COALESCE(public.owns_account_id(v_b.rider_id) OR public.owns_account_id(v_b.account_id), FALSE);
  v_admin  := COALESCE(v_admin, FALSE);
  IF NOT (v_admin OR v_owner OR v_renter) THEN
    RAISE EXCEPTION 'BOOKING_NOT_FOUND' USING ERRCODE = 'P0002';
  END IF;

  v_from := initcap(lower(v_b.status));
  IF v_from = v_to THEN
    RETURN v_b;  -- idempotent (double tap)
  END IF;

  v_allowed := CASE
    WHEN v_from = 'Pending'   AND v_to IN ('Confirmed', 'Rejected') THEN v_owner OR v_admin
    WHEN v_from = 'Pending'   AND v_to = 'Cancelled' THEN v_owner OR v_renter OR v_admin
    WHEN v_from = 'Pending'   AND v_to = 'Expired'   THEN v_admin
    WHEN v_from = 'Confirmed' AND v_to = 'Active'    THEN v_owner OR v_renter OR v_admin
    WHEN v_from = 'Confirmed' AND v_to = 'Cancelled' THEN v_owner OR v_admin
                                                       OR (v_renter AND now() < v_b.start_date)
    WHEN v_from = 'Active'    AND v_to = 'Completed' THEN v_owner OR v_renter OR v_admin
    ELSE FALSE
  END;
  IF NOT v_allowed THEN
    RAISE EXCEPTION 'INVALID_TRANSITION' USING ERRCODE = '22023',
      DETAIL = format('%s → %s is not allowed for you.', v_from, v_to);
  END IF;

  IF v_to = 'Confirmed' THEN
    IF v_b.fee_payment_status IN ('PENDING', 'SUBMITTED', 'FAILED') THEN
      RAISE EXCEPTION 'BOOKING_FEE_UNPAID' USING ERRCODE = '22023',
        HINT = 'The renter''s booking fee has not been verified yet.';
    END IF;
    IF COALESCE(v_b.booking_type, 'vehicle') <> 'tour'
       AND public.vehicle_slot_taken(v_b.vehicle_id, v_b.start_date, v_b.end_date, v_b.id) THEN
      RAISE EXCEPTION 'VEHICLE_UNAVAILABLE' USING ERRCODE = '23P01',
        HINT = 'Another booking already holds this period.';
    END IF;
  END IF;

  PERFORM set_config('passon.booking_rpc', 'on', true);
  PERFORM set_config('passon.booking_note', COALESCE(p_note, ''), true);
  BEGIN
    UPDATE public.bookings SET
      status            = v_to,
      decided_at        = CASE WHEN v_to IN ('Confirmed', 'Rejected') THEN now() ELSE decided_at END,
      decided_by        = CASE WHEN v_to IN ('Confirmed', 'Rejected') THEN auth.uid()::text ELSE decided_by END,
      rejection_reason  = CASE WHEN v_to = 'Rejected' THEN COALESCE(p_note, '') ELSE rejection_reason END,
      rental_started_at = CASE WHEN v_to = 'Active' THEN now() ELSE rental_started_at END,
      rental_ended_at   = CASE WHEN v_to IN ('Completed', 'Cancelled') THEN now() ELSE rental_ended_at END,
      cancelled_by      = CASE WHEN v_to = 'Cancelled' THEN (CASE WHEN v_owner THEN 'host' WHEN v_renter THEN 'customer' ELSE 'admin' END) ELSE cancelled_by END,
      cancellation_reason = CASE WHEN v_to = 'Cancelled' THEN COALESCE(p_note, '') ELSE cancellation_reason END,
      cancelled_at      = CASE WHEN v_to = 'Cancelled' THEN now() ELSE cancelled_at END,
      updated_at        = now()
    WHERE id = v_b.id
    RETURNING * INTO v_b;
  EXCEPTION WHEN exclusion_violation THEN
    RAISE EXCEPTION 'VEHICLE_UNAVAILABLE' USING ERRCODE = '23P01';
  END;

  -- Accepting one request closes every other request for an overlapping period.
  IF v_to = 'Confirmed' AND COALESCE(v_b.booking_type, 'vehicle') <> 'tour' THEN
    PERFORM set_config('passon.booking_note', 'Slot booked by another request', true);
    FOR v_other IN
      UPDATE public.bookings SET status = 'Rejected', decided_at = now(),
             decided_by = 'system:slot_taken', rejection_reason = 'Slot booked by another request',
             updated_at = now()
       WHERE vehicle_id = v_b.vehicle_id AND id <> v_b.id AND status = 'Pending'
         AND start_date < v_b.end_date AND end_date > v_b.start_date
      RETURNING id, rider_id, vehicle_title, vehicle_image_url
    LOOP
      INSERT INTO public.notifications (id, user_id, title, message, type, "timestamp", is_read,
                                        related_id, image_url, action_nav_index)
      VALUES ('notif_rej_' || v_other.id, v_other.rider_id, 'Booking request not confirmed',
              'Your request for ' || COALESCE(v_other.vehicle_title, 'the vehicle')
                || ' could not be confirmed because the slot was booked. Explore other vehicles on PassionRide.',
              'general', now(), FALSE, v_other.id, v_other.vehicle_image_url, 19)
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;

  PERFORM set_config('passon.booking_rpc', 'off', true);
  RETURN v_b;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- 12. ₹10 booking fee verified (called by the upi-booking-fee edge function)
-- ---------------------------------------------------------------------------
-- Manual bookings stay Pending for the owner. Automatic (and legacy/tour) bookings
-- are confirmed if the slot is still free; otherwise they stay Pending for the owner.
CREATE OR REPLACE FUNCTION public.apply_booking_fee_paid(p_booking_id TEXT)
RETURNS TEXT AS $$
DECLARE
  v_b public.bookings;
BEGIN
  SELECT * INTO v_b FROM public.bookings WHERE id = p_booking_id;
  IF NOT FOUND THEN RETURN NULL; END IF;
  PERFORM 1 FROM public.vehicles WHERE id::text = v_b.vehicle_id FOR UPDATE;
  SELECT * INTO v_b FROM public.bookings WHERE id = p_booking_id FOR UPDATE;

  PERFORM set_config('passon.booking_rpc', 'on', true);
  UPDATE public.bookings SET fee_payment_status = 'PAID', updated_at = now() WHERE id = v_b.id;

  IF initcap(lower(v_b.status)) = 'Pending'
     AND v_b.confirmation_type IS DISTINCT FROM 'MANUAL'
     AND (COALESCE(v_b.booking_type, 'vehicle') = 'tour'
          OR NOT public.vehicle_slot_taken(v_b.vehicle_id, v_b.start_date, v_b.end_date, v_b.id)) THEN
    PERFORM set_config('passon.booking_note', 'Booking fee verified: automatically confirmed', true);
    UPDATE public.bookings SET status = 'Confirmed', decided_at = now(), decided_by = 'system:auto'
     WHERE id = v_b.id RETURNING * INTO v_b;
  ELSE
    SELECT * INTO v_b FROM public.bookings WHERE id = p_booking_id;
  END IF;
  PERFORM set_config('passon.booking_rpc', 'off', true);
  RETURN v_b.status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- 13. Undecided requests expire at pickup time (every 15 minutes)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.expire_stale_booking_requests()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  PERFORM set_config('passon.booking_rpc', 'on', true);
  PERFORM set_config('passon.booking_note', 'Owner did not respond before pickup time', true);
  UPDATE public.bookings SET status = 'Expired', updated_at = now()
   WHERE initcap(lower(status)) = 'Pending' AND start_date < now()
     AND COALESCE(booking_type, 'vehicle') <> 'tour';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  PERFORM set_config('passon.booking_rpc', 'off', true);
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DO $$ BEGIN
  PERFORM cron.unschedule('expire-stale-booking-requests');
EXCEPTION WHEN OTHERS THEN NULL; END $$;
SELECT cron.schedule('expire-stale-booking-requests', '*/15 * * * *',
                     'SELECT public.expire_stale_booking_requests()');

-- ---------------------------------------------------------------------------
-- 14. Grants
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.create_vehicle_booking(JSONB, BOOLEAN) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.transition_booking(TEXT, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.set_booking_preferences(BOOLEAN, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_vehicle_booking(JSONB, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.transition_booking(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_booking_preferences(BOOLEAN, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_vehicle_busy_slots(TEXT) TO anon, authenticated;

REVOKE ALL ON FUNCTION public.apply_booking_fee_paid(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.expire_stale_booking_requests() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.apply_booking_fee_paid(TEXT) TO service_role;

-- Internal helpers: not callable over the API.
REVOKE ALL ON FUNCTION public.account_login_ids(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.owner_booking_settings(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.vehicle_slot_taken(TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.owns_account_id(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_booking_party(public.bookings) TO authenticated;

-- get_mother_aggregated_bookings(any_id) was SECURITY DEFINER, so it bypassed RLS and
-- returned anyone's bookings. Run it with the caller's rights: a mother still sees her own
-- and her child accounts' bookings (is_booking_party covers both), nobody else's.
DO $$ BEGIN
  ALTER FUNCTION public.get_mother_aggregated_bookings(TEXT) SECURITY INVOKER;
  REVOKE EXECUTE ON FUNCTION public.get_mother_aggregated_bookings(TEXT) FROM PUBLIC, anon;
  GRANT EXECUTE ON FUNCTION public.get_mother_aggregated_bookings(TEXT) TO authenticated, service_role;
EXCEPTION WHEN undefined_function THEN NULL; END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_status_history;
EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL; END $$;

NOTIFY pgrst, 'reload schema';
