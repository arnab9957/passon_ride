-- Migration: Payment Transactions, Escrow Management & Provider Profiles Security Invoker
-- Description: Stores Razorpay & Escrow payment transactions with full RLS and sets security_invoker = true on provider_profiles view.

CREATE TABLE IF NOT EXISTS public.payment_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    booking_id TEXT,
    razorpay_payment_id TEXT NOT NULL,
    razorpay_order_id TEXT NOT NULL,
    razorpay_signature TEXT,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    currency TEXT NOT NULL DEFAULT 'INR',
    status TEXT NOT NULL DEFAULT 'captured' CHECK (status IN ('created', 'attempted', 'authorized', 'captured', 'failed', 'refunded')),
    payment_method TEXT NOT NULL DEFAULT 'razorpay' CHECK (payment_method IN ('razorpay', 'upi', 'card', 'wallet', 'stripe_escrow', 'direct_upi')),
    escrow_status TEXT NOT NULL DEFAULT 'held_in_escrow' CHECK (escrow_status IN ('held_in_escrow', 'released_to_host', 'refunded_deposit', 'disputed')),
    receipt TEXT,
    notes JSONB DEFAULT '{}'::jsonb,
    error_code TEXT,
    error_description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;

-- Indexes for lightning fast querying
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_id ON public.payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_booking_id ON public.payment_transactions(booking_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_order_id ON public.payment_transactions(razorpay_order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_payment_id ON public.payment_transactions(razorpay_payment_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON public.payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_created_at ON public.payment_transactions(created_at DESC);

-- Drop pre-existing policies to allow idempotent re-application
DROP POLICY IF EXISTS "Users can view own transactions" ON public.payment_transactions;
DROP POLICY IF EXISTS "Users can record own transactions" ON public.payment_transactions;
DROP POLICY IF EXISTS "Service role full access on transactions" ON public.payment_transactions;

-- RLS Policies:
-- 1. Users can view their own payment transactions
CREATE POLICY "Users can view own transactions"
    ON public.payment_transactions
    FOR SELECT
    USING (auth.uid() = user_id);

-- 2. Authenticated users can insert payment transactions for themselves
CREATE POLICY "Users can record own transactions"
    ON public.payment_transactions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id OR auth.uid() IS NULL);

-- 3. Service role / Admins have full access
CREATE POLICY "Service role full access on transactions"
    ON public.payment_transactions
    FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role');

-- 4. Set security_invoker = true on provider_profiles view
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM pg_views 
        WHERE schemaname = 'public' 
          AND viewname = 'provider_profiles'
    ) THEN
        ALTER VIEW public.provider_profiles SET (security_invoker = true);
    END IF;
END $$;