-- Payment-screenshot OCR verification for the ₹10 UPI booking fee.
-- Screenshots live in a private bucket; only the edge function (service role) reads/writes them.

ALTER TABLE public.booking_fee_payments
  ADD COLUMN IF NOT EXISTS screenshot_path   text,
  ADD COLUMN IF NOT EXISTS screenshot_sha256 text,
  ADD COLUMN IF NOT EXISTS ocr_text          text,
  ADD COLUMN IF NOT EXISTS verification      jsonb,
  ADD COLUMN IF NOT EXISTS verification_method text; -- 'ocr_auto' | 'admin'

-- The same image can never verify two payments.
CREATE UNIQUE INDEX IF NOT EXISTS booking_fee_payments_screenshot_sha256_key
  ON public.booking_fee_payments (screenshot_sha256)
  WHERE screenshot_sha256 IS NOT NULL;

INSERT INTO storage.buckets (id, name, public)
VALUES ('payment-proofs', 'payment-proofs', false)
ON CONFLICT (id) DO NOTHING;
