-- Chat: every new message notifies the other person (in-app bell + phone push via the
-- send-push trigger on notifications), and messages are delivered live to the chat list.

-- 1. Live delivery of new messages to the app.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
    END IF;
END $$;

-- 2. Notification row for the recipient of each new message.
CREATE OR REPLACE FUNCTION public.notify_chat_message()
RETURNS TRIGGER AS $$
DECLARE
    c          public.conversations%ROWTYPE;
    v_to       TEXT;
    v_from     TEXT;
    v_preview  TEXT;
BEGIN
    SELECT * INTO c FROM public.conversations WHERE id::text = NEW.conversation_id::text;
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;

    IF NEW.sender_id::text = c.renter_id::text THEN
        v_to := c.provider_id::text;
        v_from := COALESCE(NULLIF(c.renter_name, ''), 'Customer');
    ELSE
        v_to := c.renter_id::text;
        v_from := COALESCE(NULLIF(c.provider_name, ''), 'Host');
    END IF;

    v_preview := CASE COALESCE(NEW.message_type, 'text')
        WHEN 'image' THEN '📷 Photo'
        WHEN 'location' THEN '📍 Location'
        WHEN 'document' THEN '📄 Document'
        ELSE left(COALESCE(NEW.content, ''), 140)
    END;

    INSERT INTO public.notifications (id, user_id, title, message, type, "timestamp", is_read, related_id, action_nav_index, metadata)
    VALUES (
        'n_msg_' || NEW.id::text,
        v_to,
        '💬 ' || v_from,
        v_preview,
        'chatMessage',
        now(),
        FALSE,
        c.id::text,
        5, -- Messages
        jsonb_build_object('conversation_id', c.id::text, 'sender_id', NEW.sender_id::text, 'vehicle_title', COALESCE(c.title, ''))
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_notify_chat_message ON public.messages;
CREATE TRIGGER trg_notify_chat_message
AFTER INSERT ON public.messages
FOR EACH ROW EXECUTE FUNCTION public.notify_chat_message();
