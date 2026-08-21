-- Migration: Separate Database Table for IRSARGO Chatbot & Public UI Interaction Logs
-- Created: 2026-08-21

-- 1. Create Isolated IRSARGO Chat Logs Table
CREATE TABLE IF NOT EXISTS public.irsargo_chat_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT NOT NULL,
    user_query TEXT NOT NULL,
    ui_context_snapshot TEXT, -- Only public, front-facing UI context (e.g. active screen name, public vehicle title)
    ai_response TEXT NOT NULL,
    confidence_score NUMERIC(4,3) DEFAULT 0.920,
    sources_json JSONB DEFAULT '[]'::jsonb,
    is_error BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for high-performance session query lookup
CREATE INDEX IF NOT EXISTS idx_irsargo_chat_session ON public.irsargo_chat_logs(session_id, created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.irsargo_chat_logs ENABLE ROW LEVEL SECURITY;

-- Security RLS Policies (Allows public & authenticated users to insert & query their isolated chat sessions)
CREATE POLICY "Public user irsargo chat insert" ON public.irsargo_chat_logs
    FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "Public user irsargo chat select" ON public.irsargo_chat_logs
    FOR SELECT TO anon, authenticated USING (true);
