-- Listings from unverified hosts get one week's notice, then are deleted daily.
CREATE EXTENSION IF NOT EXISTS pg_cron;

ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS unverified_since TIMESTAMPTZ;
ALTER TABLE public.hotels ADD COLUMN IF NOT EXISTS unverified_since TIMESTAMPTZ;
ALTER TABLE public.tours ADD COLUMN IF NOT EXISTS unverified_since TIMESTAMPTZ;

CREATE OR REPLACE FUNCTION public.remove_unverified_listings()
RETURNS VOID AS $$
DECLARE
    v_table TEXT;
    v_title TEXT;
    v_trusted CONSTANT TEXT := $q$(
        SELECT id FROM public.host_profiles WHERE is_verified
        UNION
        SELECT u.id::text FROM auth.users u
        JOIN public.platform_admins a ON a.email = lower(u.email)
    )$q$;
    v_booked TEXT;
BEGIN
    FOR v_table, v_title IN VALUES ('vehicles', 'title'), ('hotels', 'name'), ('tours', 'title') LOOP
        EXECUTE format(
            'UPDATE public.%I SET unverified_since = NULL
             WHERE unverified_since IS NOT NULL AND host_id IN %s', v_table, v_trusted);

        EXECUTE format(
            'INSERT INTO public.notifications (id, user_id, title, message, type, "timestamp", is_read)
             SELECT ''notif_unverified_'' || id, host_id, ''Verify your profile within 7 days'',
                    %L || %I || %L, ''general'', now(), FALSE
             FROM public.%I
             WHERE unverified_since IS NULL AND COALESCE(host_id, '''') <> ''''
               AND host_id NOT IN %s
             ON CONFLICT (id) DO NOTHING',
            'Your listing "', v_title, '" will be removed in 7 days unless your provider profile is verified.',
            v_table, v_trusted);

        EXECUTE format(
            'UPDATE public.%I SET unverified_since = now()
             WHERE unverified_since IS NULL AND COALESCE(host_id, '''') NOT IN %s', v_table, v_trusted);

        IF v_table = 'hotels' THEN
            v_booked := $q$SELECT hotel_id FROM public.hotel_bookings
                WHERE lower(status) NOT IN ('cancelled', 'completed', 'checked_out')
                  AND check_out_date::timestamptz > now()$q$;
        ELSE
            v_booked := $q$SELECT vehicle_id FROM public.bookings
                WHERE lower(status) IN ('confirmed', 'active')
                  AND end_date::timestamptz > now() AND vehicle_id IS NOT NULL$q$;
        END IF;

        -- Upcoming customer bookings keep a listing until the stay or rental is over.
        EXECUTE format(
            'DELETE FROM public.%I
             WHERE unverified_since < now() - interval ''7 days''
               AND id NOT IN (%s)', v_table, v_booked);
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.remove_unverified_listings() FROM PUBLIC, anon, authenticated;

SELECT cron.schedule('remove-unverified-listings', '30 20 * * *', 'SELECT public.remove_unverified_listings()');
SELECT public.remove_unverified_listings();
