/*
# Add CHECK_IN, GATE, BOARDED checkpoints

## Run this in Supabase SQL Editor if Check-In fails with schema/cache errors.

Journey order:
  Domestic:      NOT_ARRIVED → ENTRY → CHECK_IN → BAG_DROP → SECURITY → GATE → BOARDED → DEPARTED
  International: NOT_ARRIVED → ENTRY → CHECK_IN → BAG_DROP → IMMIGRATION → SECURITY → GATE → BOARDED → DEPARTED
*/

-- Optional status flags (safe if already present)
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS checked_in boolean DEFAULT false;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS boarding_pass_issued boolean DEFAULT false;
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS security_cleared boolean DEFAULT false;

-- Expand current_checkpoint values
ALTER TABLE passengers DROP CONSTRAINT IF EXISTS passengers_current_checkpoint_check;
ALTER TABLE passengers DROP CONSTRAINT IF EXISTS passengers_current_checkpoint_check1;
ALTER TABLE passengers DROP CONSTRAINT IF EXISTS passengers_current_checkpoint_check2;

ALTER TABLE passengers ADD CONSTRAINT passengers_current_checkpoint_check
  CHECK (current_checkpoint IN (
    'NOT_ARRIVED','ENTRY','CHECK_IN','BAG_DROP','SECURITY',
    'IMMIGRATION','GATE','BOARDING','BOARDED','DEPARTED'
  ));

-- Expand journey_logs checkpoint values
ALTER TABLE journey_logs DROP CONSTRAINT IF EXISTS journey_logs_checkpoint_check;
ALTER TABLE journey_logs DROP CONSTRAINT IF EXISTS journey_logs_checkpoint_check1;
ALTER TABLE journey_logs DROP CONSTRAINT IF EXISTS journey_logs_checkpoint_check2;

ALTER TABLE journey_logs ADD CONSTRAINT journey_logs_checkpoint_check
  CHECK (checkpoint IN (
    'ENTRY','CHECK_IN','BAG_DROP','SECURITY','IMMIGRATION',
    'GATE','BOARDING','BOARDED','ARRIVED','DEPARTED'
  ));

-- Map legacy BOARDING → GATE for existing rows (optional)
UPDATE passengers SET current_checkpoint = 'GATE'
  WHERE current_checkpoint = 'BOARDING';
