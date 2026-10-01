-- Run once in Supabase SQL Editor (project bkqjavaghombqqueymlm)
-- Adds optional Check-In / Security columns if missing

ALTER TABLE passengers ADD COLUMN IF NOT EXISTS checked_in boolean DEFAULT false;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS boarding_pass_issued boolean DEFAULT false;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS security_cleared boolean DEFAULT false;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS bag_tagged boolean DEFAULT false;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS bag_accepted boolean DEFAULT false;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS boarding_status text DEFAULT NULL;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS face_descriptor text;

-- Done. Verify:
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'passengers' ORDER BY 1;
