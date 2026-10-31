-- Listings were created with made-up ratings (5.0 / 4.8 and a "1 review" count) although
-- no review exists in reviews, trip_reviews_extended or app_feedback_reviews.
-- Reset them so the app shows "New" until real reviews arrive.

ALTER TABLE public.vehicles ALTER COLUMN rating SET DEFAULT 0;
ALTER TABLE public.hotels ALTER COLUMN rating SET DEFAULT 0;
ALTER TABLE public.tours ALTER COLUMN rating SET DEFAULT 0;

-- Only rows with no real reviews behind them (review_count <= 1 was the placeholder)
UPDATE public.vehicles SET rating = 0, review_count = 0
WHERE coalesce(review_count, 0) <= 1
  AND NOT EXISTS (SELECT 1 FROM public.reviews r WHERE r.vehicle_id::text = vehicles.id::text);

UPDATE public.hotels SET rating = 0, review_count = 0 WHERE coalesce(review_count, 0) <= 1;
UPDATE public.tours SET rating = 0, review_count = 0 WHERE coalesce(review_count, 0) <= 1;
