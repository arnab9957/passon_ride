-- Make conversations + messages the only chat store.
--
-- Until now no chat was ever persisted:
--   * conversations/messages required UUID ids and users in user_accounts (always empty)
--   * the chat_threads/chat_messages fallback was sent columns it doesn't have
-- All four tables are empty, so the type changes below lose nothing.

-- 0. Old message policies reference conversations.id, which blocks the type change below.
--    They're replaced in step 5. (Previously anyone, even anonymous, could read and edit every message.)
DROP POLICY IF EXISTS "Public insert messages" ON public.messages;
DROP POLICY IF EXISTS "Public select messages" ON public.messages;
DROP POLICY IF EXISTS "Public update messages" ON public.messages;
DROP POLICY IF EXISTS "Message conversation participant access" ON public.messages;

-- 1. Drop constraints that tie chat to user_accounts / UUID ids
ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_conversation_id_fkey;
ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;
ALTER TABLE public.conversations DROP CONSTRAINT IF EXISTS conversations_renter_id_fkey;
ALTER TABLE public.conversations DROP CONSTRAINT IF EXISTS conversations_provider_id_fkey;

-- 2. App ids are strings like 'c_b_<booking id>' / 'm_<millis>'; bookings.id is text
ALTER TABLE public.conversations ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.conversations ALTER COLUMN id TYPE TEXT USING id::text;
ALTER TABLE public.conversations ALTER COLUMN booking_id TYPE TEXT USING booking_id::text;
ALTER TABLE public.messages ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.messages ALTER COLUMN id TYPE TEXT USING id::text;
ALTER TABLE public.messages ALTER COLUMN id SET DEFAULT gen_random_uuid()::text;
ALTER TABLE public.messages ALTER COLUMN conversation_id TYPE TEXT USING conversation_id::text;

-- 3. Each side's display info, so both renter and host see who they're talking to
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS renter_name TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS renter_avatar TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS provider_name TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS provider_avatar TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS provider_phone TEXT;

-- 4. Re-link to real users
ALTER TABLE public.conversations
    ADD CONSTRAINT conversations_renter_id_fkey FOREIGN KEY (renter_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    ADD CONSTRAINT conversations_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.messages
    ADD CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE,
    ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_conversations_renter ON public.conversations(renter_id);
CREATE INDEX IF NOT EXISTS idx_conversations_provider ON public.conversations(provider_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id, created_at);

-- 5. RLS: only the two participants can see or write a conversation and its messages.

CREATE POLICY "Participants can read messages"
    ON public.messages FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = messages.conversation_id
          AND (SELECT auth.uid()) IN (c.renter_id, c.provider_id)
    ));

CREATE POLICY "Participants can send their own messages"
    ON public.messages FOR INSERT TO authenticated
    WITH CHECK (
        sender_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1 FROM public.conversations c
            WHERE c.id = messages.conversation_id
              AND (SELECT auth.uid()) IN (c.renter_id, c.provider_id)
        )
    );

-- Needed for read receipts on the other person's messages
CREATE POLICY "Participants can update messages"
    ON public.messages FOR UPDATE TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = messages.conversation_id
          AND (SELECT auth.uid()) IN (c.renter_id, c.provider_id)
    ));

-- 6. Realtime for live message delivery
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'messages') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'conversations') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
    END IF;
END $$;

-- 7. Remove the broken legacy chat tables and the user table nothing populates
DROP TABLE IF EXISTS public.chat_messages;
DROP TABLE IF EXISTS public.chat_threads;
DROP TABLE IF EXISTS public.user_accounts;
