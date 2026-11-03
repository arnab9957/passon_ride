-- Tour agency operational details (transport, group size, schedule, meals,
-- policies, licence) stored as one JSON object on each tour.
alter table public.tours
  add column if not exists logistics jsonb not null default '{}'::jsonb;

-- Lets the catalogue filter tours by transport type, e.g. logistics->'transport_modes' ? 'Mini Bus'.
create index if not exists tours_logistics_transport_idx
  on public.tours using gin ((logistics -> 'transport_modes'));
