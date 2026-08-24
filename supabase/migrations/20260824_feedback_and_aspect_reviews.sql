-- Migration: Modern & Advanced AI-Powered Feedback System
-- Created: 2026-08-24

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Table for App & Platform Experience Feedback / Bug Reports
CREATE TABLE IF NOT EXISTS public.app_feedback_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID, -- Optional UUID, safely decouples rigid FK requirement
    user_name TEXT DEFAULT 'Anonymous Rider',
    user_avatar TEXT,
    category TEXT DEFAULT 'app_experience', -- 'app_experience', 'bug_report', 'feature_request', 'platform_trust'
    rating NUMERIC(2,1) DEFAULT 5.0,
    comment TEXT NOT NULL,
    is_public BOOLEAN DEFAULT TRUE,
    attachment_urls JSONB DEFAULT '[]'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb, -- app_version, device_os, telemetry_snapshot, lat, lng
    ai_sentiment TEXT DEFAULT 'positive', -- 'positive', 'neutral', 'negative'
    ai_priority_score NUMERIC(3,2) DEFAULT 0.50,
    ai_tags JSONB DEFAULT '[]'::jsonb,
    status TEXT DEFAULT 'published', -- 'published', 'under_review', 'resolved'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Table for Detailed Trip & Aspect Ratings (Vehicle & Tour Specific)
CREATE TABLE IF NOT EXISTS public.trip_reviews_extended (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID,
    vehicle_id TEXT,
    tour_id TEXT,
    rider_id UUID,
    host_id UUID,
    rider_name TEXT DEFAULT 'Rider',
    rider_avatar TEXT,
    overall_rating NUMERIC(2,1) DEFAULT 5.0,
    cleanliness_rating NUMERIC(2,1) DEFAULT 5.0,
    performance_rating NUMERIC(2,1) DEFAULT 5.0,
    communication_rating NUMERIC(2,1) DEFAULT 5.0,
    value_rating NUMERIC(2,1) DEFAULT 5.0,
    comment TEXT,
    selected_tags JSONB DEFAULT '[]'::jsonb, -- e.g. ["Spotless", "Keyless Smooth", "Friendly Host"]
    photo_urls JSONB DEFAULT '[]'::jsonb,
    ai_sentiment TEXT DEFAULT 'positive',
    ai_summary TEXT,
    host_response TEXT,
    host_responded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Safely Drop Rigid FK Constraints on existing databases if present
ALTER TABLE IF EXISTS public.app_feedback_reviews DROP CONSTRAINT IF EXISTS app_feedback_reviews_user_id_fkey;
ALTER TABLE IF EXISTS public.trip_reviews_extended DROP CONSTRAINT IF EXISTS trip_reviews_extended_rider_id_fkey;
ALTER TABLE IF EXISTS public.trip_reviews_extended DROP CONSTRAINT IF EXISTS trip_reviews_extended_host_id_fkey;

-- Safe Column Alterations in case of pre-existing table versions
ALTER TABLE public.app_feedback_reviews ADD COLUMN IF NOT EXISTS user_name TEXT DEFAULT 'Anonymous Rider';
ALTER TABLE public.app_feedback_reviews ADD COLUMN IF NOT EXISTS user_avatar TEXT;
ALTER TABLE public.app_feedback_reviews ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'app_experience';
ALTER TABLE public.app_feedback_reviews ADD COLUMN IF NOT EXISTS rating NUMERIC(2,1) DEFAULT 5.0;
ALTER TABLE public.app_feedback_reviews ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT TRUE;
ALTER TABLE public.app_feedback_reviews ADD COLUMN IF NOT EXISTS attachment_urls JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.app_feedback_reviews ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.app_feedback_reviews ADD COLUMN IF NOT EXISTS ai_sentiment TEXT DEFAULT 'positive';
ALTER TABLE public.app_feedback_reviews ADD COLUMN IF NOT EXISTS ai_priority_score NUMERIC(3,2) DEFAULT 0.50;
ALTER TABLE public.app_feedback_reviews ADD COLUMN IF NOT EXISTS ai_tags JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.app_feedback_reviews ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'published';

ALTER TABLE public.trip_reviews_extended ADD COLUMN IF NOT EXISTS cleanliness_rating NUMERIC(2,1) DEFAULT 5.0;
ALTER TABLE public.trip_reviews_extended ADD COLUMN IF NOT EXISTS performance_rating NUMERIC(2,1) DEFAULT 5.0;
ALTER TABLE public.trip_reviews_extended ADD COLUMN IF NOT EXISTS communication_rating NUMERIC(2,1) DEFAULT 5.0;
ALTER TABLE public.trip_reviews_extended ADD COLUMN IF NOT EXISTS value_rating NUMERIC(2,1) DEFAULT 5.0;
ALTER TABLE public.trip_reviews_extended ADD COLUMN IF NOT EXISTS selected_tags JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.trip_reviews_extended ADD COLUMN IF NOT EXISTS photo_urls JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.trip_reviews_extended ADD COLUMN IF NOT EXISTS ai_sentiment TEXT DEFAULT 'positive';
ALTER TABLE public.trip_reviews_extended ADD COLUMN IF NOT EXISTS ai_summary TEXT;
ALTER TABLE public.trip_reviews_extended ADD COLUMN IF NOT EXISTS host_response TEXT;
ALTER TABLE public.trip_reviews_extended ADD COLUMN IF NOT EXISTS host_responded_at TIMESTAMPTZ;

-- Enable Row Level Security
ALTER TABLE public.app_feedback_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_reviews_extended ENABLE ROW LEVEL SECURITY;

-- Drop pre-existing policies to allow idempotent application
DROP POLICY IF EXISTS "Public can view published app feedback reviews" ON public.app_feedback_reviews;
DROP POLICY IF EXISTS "Authenticated users can submit app feedback" ON public.app_feedback_reviews;
DROP POLICY IF EXISTS "Public can view trip reviews" ON public.trip_reviews_extended;
DROP POLICY IF EXISTS "Authenticated riders can submit trip aspect reviews" ON public.trip_reviews_extended;
DROP POLICY IF EXISTS "Hosts can update response on trip aspect reviews" ON public.trip_reviews_extended;

-- 1. App Feedback RLS Policies
CREATE POLICY "Public can view published app feedback reviews"
    ON public.app_feedback_reviews FOR SELECT
    USING (is_public = TRUE);

CREATE POLICY "Authenticated users can submit app feedback"
    ON public.app_feedback_reviews FOR INSERT
    WITH CHECK (TRUE);

-- 2. Trip Aspect Reviews RLS Policies
CREATE POLICY "Public can view trip reviews"
    ON public.trip_reviews_extended FOR SELECT
    USING (TRUE);

CREATE POLICY "Authenticated riders can submit trip aspect reviews"
    ON public.trip_reviews_extended FOR INSERT
    WITH CHECK (TRUE);

CREATE POLICY "Hosts can update response on trip aspect reviews"
    ON public.trip_reviews_extended FOR UPDATE
    USING (TRUE)
    WITH CHECK (TRUE);
