-- Migration: Add exempt_hosts table for initial document-exempt vehicle hosting
-- Created on 2026-09-27

CREATE TABLE IF NOT EXISTS public.exempt_hosts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    reason TEXT DEFAULT 'Initial host onboarding exemption',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookup by email
CREATE INDEX IF NOT EXISTS idx_exempt_hosts_email ON public.exempt_hosts(LOWER(email));

-- Enable RLS
ALTER TABLE public.exempt_hosts ENABLE ROW LEVEL SECURITY;

-- Allow read access to all authenticated and anon users
DROP POLICY IF EXISTS "Allow read exempt_hosts" ON public.exempt_hosts;
CREATE POLICY "Allow read exempt_hosts"
ON public.exempt_hosts
FOR SELECT
USING (true);

-- Allow authenticated users with admin role to insert/update/delete
DROP POLICY IF EXISTS "Allow admin manage exempt_hosts" ON public.exempt_hosts;
CREATE POLICY "Allow admin manage exempt_hosts"
ON public.exempt_hosts
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = (auth.uid())::text
        AND LOWER(profiles.role) = 'admin'
    ) OR (
        auth.jwt() ->> 'email' = 'passion.ride26@gmail.com'
    )
);

-- Seed initial authorized exempt host emails
INSERT INTO public.exempt_hosts (email, reason)
VALUES
    ('pwangdu323@gmail.com', 'Authorized Initial Host Account'),
    ('passion.ride26@gmail.com', 'Platform Admin / Primary Host'),
    ('admin@passionride.com', 'Internal System Administrator'),
    ('initial.host@passionride.com', 'Pilot Program Test Host'),
    ('test.host@passionride.com', 'Demo Host Account'),
    ('demo.host@passionride.com', 'Product Demo Host'),
    ('rider@passonride.com', 'QA / Test Account')
ON CONFLICT (email) DO UPDATE
SET updated_at = NOW(), is_active = TRUE;
