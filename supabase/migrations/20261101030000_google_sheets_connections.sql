-- Server-side Google Sheets links. RLS with no policies: only the edge function
-- (service role) can read these, because refresh tokens must never reach the app.
CREATE TABLE IF NOT EXISTS public.host_sheet_connections (
    host_id TEXT PRIMARY KEY,
    refresh_token TEXT NOT NULL,
    spreadsheet_id TEXT NOT NULL,
    spreadsheet_url TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.host_sheet_connections ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.sheet_synced_bookings (
    host_id TEXT NOT NULL,
    booking_id TEXT NOT NULL,
    synced_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (host_id, booking_id)
);
ALTER TABLE public.sheet_synced_bookings ENABLE ROW LEVEL SECURITY;
