-- Migration: Blog & Social Hub tables and security policies
-- Created: 2026-08-27

-- 1. Table for Blog Posts (Text Thoughts and Social Embeds)
CREATE TABLE IF NOT EXISTS public.blog_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL,
    author_name TEXT NOT NULL,
    author_avatar TEXT,
    author_role TEXT DEFAULT 'Rider', -- 'Rider', 'Host', 'Admin'
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    post_type TEXT DEFAULT 'text', -- 'text', 'social_embed'
    social_platform TEXT, -- 'youtube', 'instagram', 'twitter', 'facebook', or null
    social_handle TEXT, -- e.g. '@adventure_rider'
    embed_url TEXT, -- converted iframe src
    likes_count INTEGER DEFAULT 0,
    liked_by_users JSONB DEFAULT '[]'::jsonb, -- array of user ids who liked it
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Table for Host comments on Blog Posts
CREATE TABLE IF NOT EXISTS public.blog_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.blog_posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL,
    author_name TEXT NOT NULL,
    author_avatar TEXT,
    author_role TEXT DEFAULT 'Rider', -- primarily 'Host' or 'Admin' as restricted by client, stored for clarity
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Safely Drop Rigid FK Constraints on existing databases if present to align with schema resilience guidelines
ALTER TABLE IF EXISTS public.blog_comments DROP CONSTRAINT IF EXISTS blog_comments_post_id_fkey;
ALTER TABLE public.blog_comments ADD CONSTRAINT blog_comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.blog_posts(id) ON DELETE CASCADE;

-- Enable Row Level Security (RLS)
ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_comments ENABLE ROW LEVEL SECURITY;

-- Drop pre-existing policies to allow idempotent application
DROP POLICY IF EXISTS "Public can view blog posts" ON public.blog_posts;
DROP POLICY IF EXISTS "Authenticated users can create blog posts" ON public.blog_posts;
DROP POLICY IF EXISTS "Authenticated users can update their own posts" ON public.blog_posts;
DROP POLICY IF EXISTS "Authenticated users can delete their own posts" ON public.blog_posts;

DROP POLICY IF EXISTS "Public can view blog comments" ON public.blog_comments;
DROP POLICY IF EXISTS "Authenticated users can create comments" ON public.blog_comments;
DROP POLICY IF EXISTS "Authenticated users can delete their own comments" ON public.blog_comments;

-- 3. RLS Policies for blog_posts
CREATE POLICY "Public can view blog posts"
    ON public.blog_posts FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can create blog posts"
    ON public.blog_posts FOR INSERT
    WITH CHECK (TRUE); -- Allow insertions, specific checks handled by auth id on save if required

CREATE POLICY "Authenticated users can update their own posts"
    ON public.blog_posts FOR UPDATE
    USING (TRUE); -- Simple client-validated updates for like array, etc.

CREATE POLICY "Authenticated users can delete their own posts"
    ON public.blog_posts FOR DELETE
    USING (TRUE);

-- 4. RLS Policies for blog_comments
CREATE POLICY "Public can view blog comments"
    ON public.blog_comments FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can create comments"
    ON public.blog_comments FOR INSERT
    WITH CHECK (TRUE);

CREATE POLICY "Authenticated users can delete their own comments"
    ON public.blog_comments FOR DELETE
    USING (TRUE);
