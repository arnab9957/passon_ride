-- Provider-defined checkout price lines for tours
-- (vehicles keep theirs inside iot_data->'price_components').
ALTER TABLE public.tours
  ADD COLUMN IF NOT EXISTS price_components jsonb NOT NULL DEFAULT '[]'::jsonb;
