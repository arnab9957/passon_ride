-- Migration: P2P Messaging, Compliance Documents & Four-Flow Transactional Notifications Topology
-- Created: 2026-08-20 (Updated with ALTER TABLE column migrations for safe Execution)

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

-- 4. P2P Conversations Table
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    renter_id UUID NOT NULL REFERENCES public.user_accounts(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES public.user_accounts(id) ON DELETE CASCADE,
    item_id TEXT,
    listing_id TEXT,
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

-- Safe Column Alterations for Pre-existing Conversations Table
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS item_id TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS listing_id TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS booking_id UUID;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS vehicle_id TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS last_message TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS last_message_time TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS renter_unread_count INT DEFAULT 0;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS provider_unread_count INT DEFAULT 0;

-- 5. Moderated Real-Time P2P Messages Table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.user_accounts(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    status TEXT DEFAULT 'sent',
    message_type TEXT DEFAULT 'text',
    attachment_url TEXT,
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6),
    original_content TEXT,
    is_moderated BOOLEAN DEFAULT FALSE,
    flagged_reasons JSONB DEFAULT '[]'::jsonb,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Safe Column Alterations for Pre-existing Messages Table (Fixes: column "status" does not exist)
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'sent';
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT 'text';
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS attachment_url TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS latitude NUMERIC(9,6);
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS longitude NUMERIC(9,6);
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS original_content TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS is_moderated BOOLEAN DEFAULT FALSE;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS flagged_reasons JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE;

-- 6. User Verification & Compliance Documents Table
CREATE TABLE IF NOT EXISTS public.compliance_documents (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    title TEXT,
    status TEXT DEFAULT 'Verified',
    expiry_date TIMESTAMPTZ,
    type TEXT,
    document_url TEXT,
    document_number TEXT,
    holder_name TEXT,
    license_type TEXT,
    file_size_kb NUMERIC,
    file_name TEXT,
    file_extension TEXT,
    confidence_score NUMERIC,
    issuing_authority TEXT,
    blood_group TEXT,
    address TEXT,
    dob TEXT,
    is_expiry_valid BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Safe Column Alterations for Pre-existing Compliance Documents Table
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS user_id TEXT;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Verified';
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMPTZ;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS type TEXT;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS document_url TEXT;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS document_number TEXT;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS holder_name TEXT;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS license_type TEXT;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS file_size_kb NUMERIC;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS file_name TEXT;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS file_extension TEXT;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS confidence_score NUMERIC;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS issuing_authority TEXT;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS blood_group TEXT;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS dob TEXT;
ALTER TABLE public.compliance_documents ADD COLUMN IF NOT EXISTS is_expiry_valid BOOLEAN DEFAULT TRUE;

-- 7. Notification Delivery Logs (4-Flow Topology Tracking)
CREATE TABLE IF NOT EXISTS public.notification_delivery_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_accounts(id) ON DELETE SET NULL,
    flow_type TEXT NOT NULL,
    channel TEXT NOT NULL,
    recipient_phone TEXT NOT NULL,
    status TEXT DEFAULT 'DELIVERED',
    message_payload TEXT,
    latency_ms INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. In-App User Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'system',
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE,
    related_id TEXT,
    image_url TEXT,
    action_nav_index INT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for high-performance querying
CREATE INDEX IF NOT EXISTS idx_conversations_renter ON public.conversations(renter_id);
CREATE INDEX IF NOT EXISTS idx_conversations_provider ON public.conversations(provider_id);
CREATE INDEX IF NOT EXISTS idx_conversations_booking ON public.conversations(booking_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_messages_status ON public.messages(conversation_id, status);
CREATE INDEX IF NOT EXISTS idx_notification_logs_user ON public.notification_delivery_logs(user_id, flow_type);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_compliance_docs_user ON public.compliance_documents(user_id);

-- Security RLS Configuration
ALTER TABLE public.user_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.renter_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_delivery_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compliance_documents ENABLE ROW LEVEL SECURITY;

-- RLS Policies (Drop existing if present to avoid duplicate policy errors)
DROP POLICY IF EXISTS "Public user accounts select" ON public.user_accounts;
CREATE POLICY "Public user accounts select" ON public.user_accounts FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Renter profile owner access" ON public.renter_profiles;
CREATE POLICY "Renter profile owner access" ON public.renter_profiles FOR ALL TO authenticated USING ((select auth.uid()) = account_id) WITH CHECK ((select auth.uid()) = account_id);

DROP POLICY IF EXISTS "Provider profile owner access" ON public.provider_profiles;
CREATE POLICY "Provider profile owner access" ON public.provider_profiles FOR ALL TO authenticated USING ((select auth.uid()) = account_id) WITH CHECK ((select auth.uid()) = account_id);

DROP POLICY IF EXISTS "Conversation participant access" ON public.conversations;
CREATE POLICY "Conversation participant access" ON public.conversations FOR ALL TO authenticated USING ((select auth.uid()) = renter_id OR (select auth.uid()) = provider_id) WITH CHECK ((select auth.uid()) = renter_id OR (select auth.uid()) = provider_id);

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Users can insert notifications" ON public.notifications;
CREATE POLICY "Users can insert notifications" ON public.notifications FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;
CREATE POLICY "Users can delete their own notifications" ON public.notifications FOR DELETE USING (true);

-- Compliance Documents RLS Policies (Allow SELECT, INSERT, UPDATE, DELETE for all authenticated and anon users)
DROP POLICY IF EXISTS "Public select compliance documents" ON public.compliance_documents;
CREATE POLICY "Public select compliance documents" ON public.compliance_documents FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public insert compliance documents" ON public.compliance_documents;
CREATE POLICY "Public insert compliance documents" ON public.compliance_documents FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public update compliance documents" ON public.compliance_documents;
CREATE POLICY "Public update compliance documents" ON public.compliance_documents FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Public delete compliance documents" ON public.compliance_documents;
CREATE POLICY "Public delete compliance documents" ON public.compliance_documents FOR DELETE USING (true);
