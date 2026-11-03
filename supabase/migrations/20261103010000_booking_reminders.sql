-- Scheduled booking reminders. Each reminder is a row in `notifications`, so it
-- shows in the in-app bell and is pushed to the phone by the send-push trigger.
-- Runs every 10 minutes via pg_cron; deterministic ids make every reminder
-- fire at most once per booking.

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- The app writes booking times as India wall-clock without a zone, which
-- Postgres stores as if UTC. Re-read that wall-clock as Asia/Kolkata.
CREATE OR REPLACE FUNCTION public.booking_ist(p_value TIMESTAMPTZ)
RETURNS TIMESTAMPTZ AS $$
    SELECT (p_value AT TIME ZONE 'UTC') AT TIME ZONE 'Asia/Kolkata';
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.send_booking_reminders()
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
    v_rows  INTEGER;
BEGIN
    WITH b AS (
        SELECT
            id,
            coalesce(nullif(customer_id, ''), rider_id) AS renter_id,
            coalesce(nullif(vehicle_title, ''), 'your ride') AS title,
            lower(coalesce(status, '')) AS st,
            public.booking_ist(start_date::timestamptz) AS starts_at,
            public.booking_ist(end_date::timestamptz) AS ends_at
        FROM public.bookings
        WHERE lower(coalesce(status, '')) IN ('confirmed', 'active', 'completed')
          AND end_date::timestamptz > now() - interval '3 days'
    ),
    reminders AS (
        -- 1. Pickup within the next 2 hours
        SELECT 'rem_pickup_' || id AS nid, renter_id,
               'Pickup soon: ' || title AS ttl,
               'Your booking starts at ' || to_char(starts_at AT TIME ZONE 'Asia/Kolkata', 'HH12:MI AM')
                   || '. Carry your Driving License and Aadhaar.' AS msg,
               id AS related_id
        FROM b WHERE st = 'confirmed' AND starts_at BETWEEN now() AND now() + interval '2 hours'
        UNION ALL
        -- 2. Return due within 30 minutes
        SELECT 'rem_return_' || id, renter_id,
               'Return due soon: ' || title,
               'Please return by ' || to_char(ends_at AT TIME ZONE 'Asia/Kolkata', 'HH12:MI AM')
                   || '. On-time returns boost your Kinetic Trust Score.',
               id
        FROM b WHERE st = 'active' AND ends_at BETWEEN now() AND now() + interval '30 minutes'
        UNION ALL
        -- 3. Overdue by 15+ minutes
        SELECT 'rem_overdue_' || id, renter_id,
               'Return overdue: ' || title,
               'Your rental ended at ' || to_char(ends_at AT TIME ZONE 'Asia/Kolkata', 'HH12:MI AM')
                   || '. Please return it now or contact the host to extend.',
               id
        FROM b WHERE st = 'active' AND ends_at BETWEEN now() - interval '1 day' AND now() - interval '15 minutes'
        UNION ALL
        -- 4. Review request 1–24 h after the ride ended
        SELECT 'rem_review_' || id, renter_id,
               'How was ' || title || '?',
               'Rate your ride and help other riders choose. It only takes a few seconds.',
               id
        FROM b WHERE st = 'completed' AND ends_at BETWEEN now() - interval '24 hours' AND now() - interval '1 hour'
    )
    INSERT INTO public.notifications (id, user_id, title, message, type, timestamp, is_read, related_id, action_nav_index, metadata)
    SELECT nid, renter_id, ttl, msg, 'bookingConfirmation', now(), false, related_id, 19,
           jsonb_build_object('source', 'reminder')
    FROM reminders
    WHERE coalesce(renter_id, '') <> ''
    ON CONFLICT (id) DO NOTHING;

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    v_count := v_count + v_rows;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.send_booking_reminders() FROM PUBLIC, anon, authenticated;

-- (Re)schedule every 10 minutes.
DO $$
BEGIN
    PERFORM cron.unschedule('booking-reminders')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'booking-reminders');
    PERFORM cron.schedule('booking-reminders', '*/10 * * * *', 'select public.send_booking_reminders()');
END $$;
