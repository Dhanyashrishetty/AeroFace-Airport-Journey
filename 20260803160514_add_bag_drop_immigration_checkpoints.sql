/*
# Add BAG_DROP and IMMIGRATION checkpoints + bag tracking columns

## Summary
Expands the airport journey from 3 checkpoints (ENTRY, SECURITY, BOARDING) to 5
(ENTRY, BAG_DROP, SECURITY, IMMIGRATION, BOARDING) to match the real airport flow.
Also adds bag tracking columns to passengers and updates the journey_logs
checkpoint constraint to include the new checkpoints.

## Changes

### passengers table
- Add `bag_tagged` (boolean, default false) — whether bag has been tagged at bag drop
- Add `bag_accepted` (boolean, default false) — whether bag has been accepted
- Add `boarding_status` (text, default null, CHECK PENDING/ALLOWED/DENIED/BOARDED)
  — final boarding decision at the boarding gate
- Update `current_checkpoint` CHECK constraint to include BAG_DROP and IMMIGRATION
  New order: NOT_ARRIVED → ENTRY → BAG_DROP → SECURITY → IMMIGRATION → BOARDING → DEPARTED
  (IMMIGRATION is skipped for domestic passengers in app logic, but the DB allows it)

### journey_logs table
- Update `checkpoint` CHECK constraint to include BAG_DROP and IMMIGRATION

### Security
No new tables. Existing RLS policies remain unchanged (open CRUD for anon+authenticated).
Constraints are dropped and recreated to add new values — no data loss.

### Important notes
1. Constraints are dropped with IF EXISTS before recreating, so this is safe to re-run.
2. Existing passengers keep their current_checkpoint value (no data migration needed).
3. The app logic determines which checkpoints apply (e.g., skip IMMIGRATION for domestic).
*/

-- passengers: add bag columns
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS bag_tagged boolean DEFAULT false;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS bag_accepted boolean DEFAULT false;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS boarding_status text DEFAULT NULL;

-- Add CHECK constraint for boarding_status
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'passengers_boarding_status_check'
  ) THEN
    ALTER TABLE passengers ADD CONSTRAINT passengers_boarding_status_check
      CHECK (boarding_status IS NULL OR boarding_status IN ('PENDING','ALLOWED','DENIED','BOARDED'));
  END IF;
END $$;

-- passengers: update current_checkpoint CHECK constraint
ALTER TABLE passengers DROP CONSTRAINT IF EXISTS passengers_current_checkpoint_check;
ALTER TABLE passengers DROP CONSTRAINT IF EXISTS passengers_current_checkpoint_check1;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'passengers_current_checkpoint_check'
  ) THEN
    ALTER TABLE passengers ADD CONSTRAINT passengers_current_checkpoint_check
      CHECK (current_checkpoint IN ('NOT_ARRIVED','ENTRY','BAG_DROP','SECURITY','IMMIGRATION','BOARDING','DEPARTED'));
  END IF;
END $$;

-- journey_logs: update checkpoint CHECK constraint
ALTER TABLE journey_logs DROP CONSTRAINT IF EXISTS journey_logs_checkpoint_check;
ALTER TABLE journey_logs DROP CONSTRAINT IF EXISTS journey_logs_checkpoint_check1;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'journey_logs_checkpoint_check'
  ) THEN
    ALTER TABLE journey_logs ADD CONSTRAINT journey_logs_checkpoint_check
      CHECK (checkpoint IN ('ENTRY','BAG_DROP','SECURITY','IMMIGRATION','BOARDING','ARRIVED','DEPARTED'));
  END IF;
END $$;
