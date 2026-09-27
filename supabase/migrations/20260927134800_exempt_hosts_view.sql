-- Ensure approved_emails table exists and exempt_hosts view/table aliases it
CREATE TABLE IF NOT EXISTS public.approved_emails (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    reason TEXT DEFAULT 'Initial host onboarding exemption',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE VIEW public.exempt_hosts AS
SELECT * FROM public.approved_emails;
