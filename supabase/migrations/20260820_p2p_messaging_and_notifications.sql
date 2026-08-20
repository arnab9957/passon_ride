-- Migration: P2P Messaging & Four-Flow Transactional Notifications Topology
-- Created: 2026-08-20

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Base User Accounts Table (Polymorphic Anchor)
CREATE TABLE IF NOT EXISTS public.user_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    phone_number TEXT,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    trust_score NUMERIC(5,2) DEFAULT 95.00,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    is_whatsapp_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Polymorphic Renter Profile
CREATE TABLE IF NOT EXISTS public.renter_profiles (
    account_id UUID PRIMARY KEY REFERENCES public.user_accounts(id) ON DELETE CASCADE,
    license_number TEXT,
    license_status TEXT DEFAULT 'Unverified', -- 'Pending', 'Verified', 'Rejected'
    preferred_payment_method TEXT,
    total_trips_completed INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Polymorphic Provider Profile
CREATE TABLE IF NOT EXISTS public.provider_profiles (
    account_id UUID PRIMARY KEY REFERENCES public.user_accounts(id) ON DELETE CASCADE,
    kyc_status TEXT DEFAULT 'Pending', -- 'Pending', 'In_Review', 'Verified', 'Action_Required'
    bank_account_last4 TEXT,
    payout_bank_name TEXT,
    instant_booking_enabled BOOLEAN DEFAULT TRUE,
    total_rentals_hosted INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. P2P Conversations Table (Maps Renter and Provider to Listing / Asset & Booking)
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    renter_id UUID NOT NULL REFERENCES public.user_accounts(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES public.user_accounts(id) ON DELETE CASCADE,
    item_id TEXT, -- Mapped directly to specific asset / vehicle / listing
    listing_id TEXT, -- Alias for item_id
    booking_id UUID,
    vehicle_id TEXT,
    title TEXT,
    last_message TEXT,
    last_message_time TIMESTAMPTZ DEFAULT NOW(),
    renter_unread_count INT DEFAULT 0,
    provider_unread_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_renter_provider_booking UNIQUE (renter_id, provider_id, booking_id)
);

-- 5. Moderated Real-Time P2P Messages Table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.user_accounts(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_text TEXT GENERATED ALWAYS AS (content) STORED, -- OLX/Airbnb schema alias
    status TEXT DEFAULT 'sent', -- 'sending', 'sent', 'delivered', 'read', 'failed'
    message_type TEXT DEFAULT 'text', -- 'text', 'image', 'location', 'document'
    attachment_url TEXT,
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6),
    original_content TEXT,
    is_moderated BOOLEAN DEFAULT FALSE,
    flagged_reasons JSONB DEFAULT '[]'::jsonb,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Notification Delivery Logs (4-Flow Topology Tracking)
CREATE TABLE IF NOT EXISTS public.notification_delivery_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_accounts(id) ON DELETE SET NULL,
    flow_type TEXT NOT NULL, -- 'FLOW_1_BUYER_CHECKOUT_OTP', 'FLOW_2_SELLER_KYC', 'FLOW_3_HIGH_VALUE_WHATSAPP', 'FLOW_4_BOOKING_LIFECYCLE'
    channel TEXT NOT NULL, -- 'SMS', 'WHATSAPP'
    recipient_phone TEXT NOT NULL,
    status TEXT DEFAULT 'DELIVERED', -- 'PENDING', 'DELIVERED', 'FAILED'
    message_payload TEXT,
    latency_ms INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for high-performance querying
CREATE INDEX IF NOT EXISTS idx_conversations_renter ON public.conversations(renter_id);
CREATE INDEX IF NOT EXISTS idx_conversations_provider ON public.conversations(provider_id);
CREATE INDEX IF NOT EXISTS idx_conversations_booking ON public.conversations(booking_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_messages_status ON public.messages(conversation_id, status);
CREATE INDEX IF NOT EXISTS idx_notification_logs_user ON public.notification_delivery_logs(user_id, flow_type);

-- Security RLS Configuration
ALTER TABLE public.user_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.renter_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_delivery_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Public user accounts select" ON public.user_accounts
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Renter profile owner access" ON public.renter_profiles
    FOR ALL TO authenticated USING ((select auth.uid()) = account_id) WITH CHECK ((select auth.uid()) = account_id);

CREATE POLICY "Provider profile owner access" ON public.provider_profiles
    FOR ALL TO authenticated USING ((select auth.uid()) = account_id) WITH CHECK ((select auth.uid()) = account_id);

CREATE POLICY "Conversation participant access" ON public.conversations
    FOR ALL TO authenticated
    USING ((select auth.uid()) = renter_id OR (select auth.uid()) = provider_id)
    WITH CHECK ((select auth.uid()) = renter_id OR (select auth.uid()) = provider_id);

CREATE POLICY "Message conversation participant access" ON public.messages
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.conversations c
            WHERE c.id = messages.conversation_id
            AND ((select auth.uid()) = c.renter_id OR (select auth.uid()) = c.provider_id)
        )
    );

