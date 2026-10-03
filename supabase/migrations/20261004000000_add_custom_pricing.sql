ALTER TABLE vehicles
ADD COLUMN price_per_hour NUMERIC DEFAULT 0,
ADD COLUMN custom_time_range_start TEXT DEFAULT '',
ADD COLUMN custom_time_range_end TEXT DEFAULT '',
ADD COLUMN custom_time_range_price NUMERIC DEFAULT 0;
