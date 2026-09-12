-- Migration: Admin Roles, RLS policies, and User Banning

-- Add is_banned column to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT FALSE;

-- Create an admin check function (security definer so it can read profiles even if normal RLS prevents it)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT role INTO user_role FROM public.profiles WHERE id = auth.uid()::TEXT;
    RETURN COALESCE(user_role = 'Admin', false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Profiles: Admins can do anything
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles" ON public.profiles FOR SELECT USING (is_admin());

DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
CREATE POLICY "Admins can update all profiles" ON public.profiles FOR UPDATE USING (is_admin());

-- Host Profiles: Admins can do anything
DROP POLICY IF EXISTS "Admins can view all host profiles" ON public.host_profiles;
CREATE POLICY "Admins can view all host profiles" ON public.host_profiles FOR SELECT USING (is_admin());

DROP POLICY IF EXISTS "Admins can update all host profiles" ON public.host_profiles;
CREATE POLICY "Admins can update all host profiles" ON public.host_profiles FOR UPDATE USING (is_admin());

-- Vehicles: Admins can view and update everything
DROP POLICY IF EXISTS "Admins can view all vehicles" ON public.vehicles;
CREATE POLICY "Admins can view all vehicles" ON public.vehicles FOR SELECT USING (is_admin());

DROP POLICY IF EXISTS "Admins can update all vehicles" ON public.vehicles;
CREATE POLICY "Admins can update all vehicles" ON public.vehicles FOR UPDATE USING (is_admin());

DROP POLICY IF EXISTS "Admins can delete all vehicles" ON public.vehicles;
CREATE POLICY "Admins can delete all vehicles" ON public.vehicles FOR DELETE USING (is_admin());

-- Bookings: Admins can view and update everything
DROP POLICY IF EXISTS "Admins can view all bookings" ON public.bookings;
CREATE POLICY "Admins can view all bookings" ON public.bookings FOR SELECT USING (is_admin());

DROP POLICY IF EXISTS "Admins can update all bookings" ON public.bookings;
CREATE POLICY "Admins can update all bookings" ON public.bookings FOR UPDATE USING (is_admin());
