-- Migration to add quantity column to vehicles table

ALTER TABLE vehicles
ADD COLUMN quantity INT NOT NULL DEFAULT 1;
