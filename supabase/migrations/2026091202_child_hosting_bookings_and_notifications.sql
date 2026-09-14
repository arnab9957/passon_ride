-- ==========================================================
-- Migration: Child Hosting Profile Bookings Sync & Mother Notifications
-- Date: 2026-09-12
--
-- Features:
-- 1. Updates get_mother_aggregated_bookings to include:
--    - Child-hosted vehicle bookings placed by external customers
--    - Customer profile identity (Name, Phone, Email, Photo, Trust Score)
--    - Distinct account_type ('child_hosting') and is_child_hosting flag
-- 2. Creates Postgres Trigger fn_notify_mother_on_child_booking
--    - Dispatches instant in-app notification to Mother account when
--      a customer books any vehicle hosted by any linked child profile.
-- 3. Extends notification SELECT policy so mother can read alerts.
-- ==========================================================

-- ==========================================================
-- 1. DROP AND RECREATE get_mother_aggregated_bookings RPC
-- ==========================================================
DROP FUNCTION IF EXISTS public.get_mother_aggregated_bookings(TEXT);

CREATE OR REPLACE FUNCTION public.get_mother_aggregated_bookings(p_mother_id TEXT)
RETURNS TABLE (
    id TEXT,
    vehicle_id TEXT,
    vehicle_title TEXT,
    vehicle_image_url TEXT,
    host_name TEXT,
    host_id TEXT,
    start_date TEXT,
    end_date TEXT,
    total_price NUMERIC,
    status TEXT,
    unlock_passcode TEXT,
    created_at TEXT,
    account_id TEXT,
    account_name TEXT,
    account_type TEXT,
    is_child_hosting BOOLEAN,
    child_id TEXT,
    child_name TEXT,
    customer_id TEXT,
    customer_name TEXT,
    customer_email TEXT,
    customer_phone TEXT,
    customer_photo TEXT,
    customer_trust_score NUMERIC
) AS $$
DECLARE
    v_actual_mother_id TEXT;
    v_actual_customer_id TEXT;
BEGIN
    -- Resolve mother_id or customer_id
    SELECT m.mother_id, m.customer_id 
    INTO v_actual_mother_id, v_actual_customer_id
    FROM public.mother_profile m
    WHERE m.mother_id = p_mother_id OR m.customer_id = p_mother_id
    LIMIT 1;

    IF v_actual_mother_id IS NULL THEN
        v_actual_mother_id := p_mother_id;
        v_actual_customer_id := p_mother_id;
    END IF;

    RETURN QUERY
    WITH all_records AS (
        -- 1. Mother's own rental & hosting bookings
        SELECT 
            b.id::TEXT AS id,
            b.vehicle_id::TEXT AS vehicle_id,
            COALESCE(b.vehicle_title, '')::TEXT AS vehicle_title,
            COALESCE(b.vehicle_image_url, '')::TEXT AS vehicle_image_url,
            COALESCE(b.host_name, '')::TEXT AS host_name,
            COALESCE(b.host_id, '')::TEXT AS host_id,
            b.start_date::TEXT AS start_date,
            b.end_date::TEXT AS end_date,
            COALESCE(b.total_price, 0)::NUMERIC AS total_price,
            COALESCE(b.status, 'Confirmed')::TEXT AS status,
            COALESCE(b.unlock_passcode, '')::TEXT AS unlock_passcode,
            b.created_at::TEXT AS created_at,
            v_actual_mother_id::TEXT AS account_id,
            COALESCE(m.name, 'Mother Account')::TEXT AS account_name,
            'mother'::TEXT AS account_type,
            FALSE AS is_child_hosting,
            ''::TEXT AS child_id,
            ''::TEXT AS child_name,
            COALESCE(b.rider_id, '')::TEXT AS customer_id,
            COALESCE(p.display_name, 'Self')::TEXT AS customer_name,
            COALESCE(p.email, '')::TEXT AS customer_email,
            COALESCE(p.phone_number, '')::TEXT AS customer_phone,
            COALESCE(p.photo_url, '')::TEXT AS customer_photo,
            COALESCE(p.trust_score, 100)::NUMERIC AS customer_trust_score
        FROM public.bookings b
        LEFT JOIN public.mother_profile m ON (m.mother_id = v_actual_mother_id)
        LEFT JOIN public.profiles p ON (p.id = b.rider_id)
        WHERE (b.account_id = v_actual_mother_id 
               OR b.rider_id = v_actual_customer_id 
               OR b.rider_id = v_actual_mother_id
               OR (b.host_id = v_actual_customer_id OR b.host_id = v_actual_mother_id))

        UNION ALL

        -- 2. Child's own rental bookings (Child rented a vehicle)
        SELECT 
            b.id::TEXT AS id,
            b.vehicle_id::TEXT AS vehicle_id,
            COALESCE(b.vehicle_title, '')::TEXT AS vehicle_title,
            COALESCE(b.vehicle_image_url, '')::TEXT AS vehicle_image_url,
            COALESCE(b.host_name, '')::TEXT AS host_name,
            COALESCE(b.host_id, '')::TEXT AS host_id,
            b.start_date::TEXT AS start_date,
            b.end_date::TEXT AS end_date,
            COALESCE(b.total_price, 0)::NUMERIC AS total_price,
            COALESCE(b.status, 'Confirmed')::TEXT AS status,
            COALESCE(b.unlock_passcode, '')::TEXT AS unlock_passcode,
            b.created_at::TEXT AS created_at,
            c.child_id::TEXT AS account_id,
            c.name::TEXT AS account_name,
            'child'::TEXT AS account_type,
            FALSE AS is_child_hosting,
            c.child_id::TEXT AS child_id,
            c.name::TEXT AS child_name,
            c.child_id::TEXT AS customer_id,
            c.name::TEXT AS customer_name,
            COALESCE(c.email, '')::TEXT AS customer_email,
            COALESCE(c.phone, '')::TEXT AS customer_phone,
            COALESCE(c.profile_photo, '')::TEXT AS customer_photo,
            100::NUMERIC AS customer_trust_score
        FROM public.bookings b
        JOIN public.child_profile c ON (b.account_id = c.child_id OR b.rider_id = c.child_id)
        WHERE c.mother_id = v_actual_mother_id

        UNION ALL

        -- 3. Child's Hosted Fleet Bookings (Customer booked a vehicle hosted by child!)
        SELECT 
            b.id::TEXT AS id,
            b.vehicle_id::TEXT AS vehicle_id,
            COALESCE(b.vehicle_title, '')::TEXT AS vehicle_title,
            COALESCE(b.vehicle_image_url, '')::TEXT AS vehicle_image_url,
            COALESCE(b.host_name, c.name)::TEXT AS host_name,
            c.child_id::TEXT AS host_id,
            b.start_date::TEXT AS start_date,
            b.end_date::TEXT AS end_date,
            COALESCE(b.total_price, 0)::NUMERIC AS total_price,
            COALESCE(b.status, 'Confirmed')::TEXT AS status,
            COALESCE(b.unlock_passcode, '')::TEXT AS unlock_passcode,
            b.created_at::TEXT AS created_at,
            c.child_id::TEXT AS account_id,
            c.name::TEXT AS account_name,
            'child_hosting'::TEXT AS account_type,
            TRUE AS is_child_hosting,
            c.child_id::TEXT AS child_id,
            c.name::TEXT AS child_name,
            COALESCE(b.rider_id, '')::TEXT AS customer_id,
            COALESCE(p.display_name, 'Customer Rider')::TEXT AS customer_name,
            COALESCE(p.email, '')::TEXT AS customer_email,
            COALESCE(p.phone_number, '')::TEXT AS customer_phone,
            COALESCE(p.photo_url, '')::TEXT AS customer_photo,
            COALESCE(p.trust_score, 95)::NUMERIC AS customer_trust_score
        FROM public.bookings b
        JOIN public.child_profile c ON (
            b.host_id = c.child_id 
            OR b.vehicle_id IN (
                SELECT v.id FROM public.vehicles v 
                WHERE v.host_id = c.child_id OR v.owner_account_id = c.child_id
            )
        )
        LEFT JOIN public.profiles p ON (p.id = b.rider_id)
        WHERE c.mother_id = v_actual_mother_id
          AND (b.rider_id IS DISTINCT FROM c.child_id)
    )
    SELECT DISTINCT ON (r.id)
        r.id,
        r.vehicle_id,
        r.vehicle_title,
        r.vehicle_image_url,
        r.host_name,
        r.host_id,
        r.start_date,
        r.end_date,
        r.total_price,
        r.status,
        r.unlock_passcode,
        r.created_at,
        r.account_id,
        r.account_name,
        r.account_type,
        r.is_child_hosting,
        r.child_id,
        r.child_name,
        r.customer_id,
        r.customer_name,
        r.customer_email,
        r.customer_phone,
        r.customer_photo,
        r.customer_trust_score
    FROM all_records r
    ORDER BY r.id, r.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_mother_aggregated_bookings(TEXT) TO anon, authenticated, service_role;

-- ==========================================================
-- 2. AUTOMATED NOTIFICATION TRIGGER ON public.bookings
-- ==========================================================
CREATE OR REPLACE FUNCTION public.fn_notify_mother_on_child_booking()
RETURNS TRIGGER AS $$
DECLARE
    v_child_id TEXT;
    v_child_name TEXT;
    v_mother_id TEXT;
    v_mother_customer_id TEXT;
    v_cust_name TEXT;
    v_cust_email TEXT;
    v_cust_phone TEXT;
BEGIN
    -- Check if booking belongs to child hosting
    SELECT c.child_id, c.name, c.mother_id, m.customer_id
    INTO v_child_id, v_child_name, v_mother_id, v_mother_customer_id
    FROM public.child_profile c
    JOIN public.mother_profile m ON m.mother_id = c.mother_id
    WHERE c.child_id = NEW.host_id
       OR c.child_id = (SELECT COALESCE(v.host_id, v.owner_account_id) FROM public.vehicles v WHERE v.id = NEW.vehicle_id LIMIT 1)
    LIMIT 1;

    -- If not linked to any child profile, skip
    IF v_child_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- If child is the rider, skip hosting alert
    IF NEW.rider_id = v_child_id THEN
        RETURN NEW;
    END IF;

    -- Fetch customer info
    SELECT p.display_name, p.email, p.phone_number
    INTO v_cust_name, v_cust_email, v_cust_phone
    FROM public.profiles p
    WHERE p.id = NEW.rider_id
    LIMIT 1;

    IF v_cust_name IS NULL OR trim(v_cust_name) = '' THEN
        v_cust_name := 'A Customer';
    END IF;

    -- On INSERT: New Booking Received
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO public.notifications (
            id,
            user_id,
            title,
            message,
            type,
            timestamp,
            is_read,
            related_id,
            image_url,
            action_nav_index,
            metadata
        ) VALUES (
            'notif_' || extract(epoch from now())::bigint || '_' || substr(md5(random()::text), 1, 6),
            COALESCE(v_mother_customer_id, v_mother_id),
            'Child Fleet: New Booking on ' || COALESCE(NEW.vehicle_title, 'Vehicle') || ' 🚗',
            v_cust_name || ' booked ' || COALESCE(NEW.vehicle_title, 'vehicle') || ' hosted by ' || v_child_name || ' for ₹' || COALESCE(NEW.total_price::text, '0') || '. Tap to view customer details.',
            'childBookingAlert',
            NOW(),
            FALSE,
            NEW.id,
            NEW.vehicle_image_url,
            2,
            jsonb_build_object(
                'booking_id', NEW.id,
                'vehicle_id', NEW.vehicle_id,
                'vehicle_title', NEW.vehicle_title,
                'child_id', v_child_id,
                'child_name', v_child_name,
                'customer_id', NEW.rider_id,
                'customer_name', v_cust_name,
                'customer_email', COALESCE(v_cust_email, ''),
                'customer_phone', COALESCE(v_cust_phone, ''),
                'total_price', NEW.total_price,
                'is_child_hosting', true,
                'status', NEW.status
            )
        );

        IF v_mother_id IS NOT NULL AND v_mother_id IS DISTINCT FROM v_mother_customer_id THEN
            INSERT INTO public.notifications (
                id,
                user_id,
                title,
                message,
                type,
                timestamp,
                is_read,
                related_id,
                image_url,
                action_nav_index,
                metadata
            ) VALUES (
                'notif_' || extract(epoch from now())::bigint || '_' || substr(md5(random()::text), 1, 6),
                v_mother_id,
                'Child Fleet: New Booking on ' || COALESCE(NEW.vehicle_title, 'Vehicle') || ' 🚗',
                v_cust_name || ' booked ' || COALESCE(NEW.vehicle_title, 'vehicle') || ' hosted by ' || v_child_name || ' for ₹' || COALESCE(NEW.total_price::text, '0') || '.',
                'childBookingAlert',
                NOW(),
                FALSE,
                NEW.id,
                NEW.vehicle_image_url,
                2,
                jsonb_build_object(
                    'booking_id', NEW.id,
                    'child_id', v_child_id,
                    'child_name', v_child_name,
                    'customer_name', v_cust_name,
                    'is_child_hosting', true
                )
            );
        END IF;

    -- On UPDATE: Status Changed
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.status IS DISTINCT FROM NEW.status) THEN
            INSERT INTO public.notifications (
                id,
                user_id,
                title,
                message,
                type,
                timestamp,
                is_read,
                related_id,
                image_url,
                action_nav_index,
                metadata
            ) VALUES (
                'notif_' || extract(epoch from now())::bigint || '_' || substr(md5(random()::text), 1, 6),
                COALESCE(v_mother_customer_id, v_mother_id),
                'Child Fleet Booking Update (' || NEW.status || ')',
                'Booking on ' || COALESCE(NEW.vehicle_title, 'vehicle') || ' hosted by ' || v_child_name || ' is now ' || NEW.status || '.',
                'childBookingAlert',
                NOW(),
                FALSE,
                NEW.id,
                NEW.vehicle_image_url,
                2,
                jsonb_build_object(
                    'booking_id', NEW.id,
                    'child_id', v_child_id,
                    'child_name', v_child_name,
                    'customer_id', NEW.rider_id,
                    'customer_name', v_cust_name,
                    'status', NEW.status,
                    'is_child_hosting', true
                )
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_mother_on_child_booking ON public.bookings;
CREATE TRIGGER trg_notify_mother_on_child_booking
    AFTER INSERT OR UPDATE ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_notify_mother_on_child_booking();

-- ==========================================================
-- 3. PERMISSIONS AND RLS FOR NOTIFICATIONS
-- ==========================================================
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;

CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
USING (
    ((SELECT auth.uid()::text) = user_id)
    OR user_id IN (
        SELECT mother_id FROM public.mother_profile WHERE customer_id = (SELECT auth.uid()::text)
    )
    OR user_id IN (
        SELECT child_id FROM public.child_profile WHERE mother_id IN (
            SELECT mother_id FROM public.mother_profile WHERE customer_id = (SELECT auth.uid()::text)
        )
    )
);
