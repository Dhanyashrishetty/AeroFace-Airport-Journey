-- ============================================================
-- AeroFace NUCLEAR FIX — run this entire script in SQL Editor
-- Fixes: violates check constraint "passengers_current_checkpoint_check"
-- ============================================================

-- A) Show what constraints exist NOW (for debugging)
SELECT conname AS constraint_name, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.passengers'::regclass AND contype = 'c';

-- B) DROP every CHECK constraint on passengers (all of them)
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT conname FROM pg_constraint
    WHERE conrelid = 'public.passengers'::regclass AND contype = 'c'
  LOOP
    EXECUTE format('ALTER TABLE public.passengers DROP CONSTRAINT IF EXISTS %I', r.conname);
    RAISE NOTICE 'Dropped: %', r.conname;
  END LOOP;
END $$;

-- C) DROP every CHECK constraint on journey_logs
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT conname FROM pg_constraint
    WHERE conrelid = 'public.journey_logs'::regclass AND contype = 'c'
  LOOP
    EXECUTE format('ALTER TABLE public.journey_logs DROP CONSTRAINT IF EXISTS %I', r.conname);
    RAISE NOTICE 'Dropped: %', r.conname;
  END LOOP;
END $$;

-- D) Ensure columns exist
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS checked_in boolean DEFAULT false;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS boarding_pass_issued boolean DEFAULT false;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS security_cleared boolean DEFAULT false;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS bag_tagged boolean DEFAULT false;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS bag_accepted boolean DEFAULT false;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS boarding_status text DEFAULT NULL;

-- E) Re-add ONLY the correct constraints (with CHECK_IN, GATE, BOARDED)
ALTER TABLE passengers
  ADD CONSTRAINT passengers_current_checkpoint_check
  CHECK (current_checkpoint IN (
    'NOT_ARRIVED','ENTRY','CHECK_IN','BAG_DROP','SECURITY',
    'IMMIGRATION','GATE','BOARDING','BOARDED','DEPARTED'
  ));

ALTER TABLE passengers
  ADD CONSTRAINT passengers_boarding_status_check
  CHECK (boarding_status IS NULL OR boarding_status IN ('PENDING','ALLOWED','DENIED','BOARDED'));

ALTER TABLE passengers
  ADD CONSTRAINT passengers_travel_type_check
  CHECK (travel_type IN ('Domestic','International'));

ALTER TABLE passengers
  ADD CONSTRAINT passengers_gender_check
  CHECK (gender IN ('Male','Female','Other'));

ALTER TABLE journey_logs
  ADD CONSTRAINT journey_logs_checkpoint_check
  CHECK (checkpoint IN (
    'ENTRY','CHECK_IN','BAG_DROP','SECURITY','IMMIGRATION',
    'GATE','BOARDING','BOARDED','ARRIVED','DEPARTED'
  ));

-- F) TEST: this must succeed (uses first passenger row if any)
DO $$
DECLARE pid uuid;
BEGIN
  SELECT id INTO pid FROM passengers LIMIT 1;
  IF pid IS NOT NULL THEN
    UPDATE passengers SET current_checkpoint = 'CHECK_IN' WHERE id = pid;
    UPDATE passengers SET current_checkpoint = 'ENTRY' WHERE id = pid;
    RAISE NOTICE 'TEST OK: CHECK_IN is allowed by the constraint';
  ELSE
    RAISE NOTICE 'No passengers yet — constraint still updated; register a passenger and try Check-In';
  END IF;
END $$;

-- G) Final verification — definition MUST list CHECK_IN
SELECT conname, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.passengers'::regclass
  AND conname = 'passengers_current_checkpoint_check';
