-- ============================================================
-- AeroFace FULL DATABASE SETUP
-- Run once in Supabase → SQL Editor → New query → Run
-- Creates ALL tables if they do not exist (fixes "passengers does not exist")
-- ============================================================

-- ======= FLIGHTS =======
CREATE TABLE IF NOT EXISTS flights (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  flight_no     text NOT NULL UNIQUE,
  airline       text NOT NULL,
  origin        text NOT NULL,
  destination   text NOT NULL,
  departure     timestamptz NOT NULL,
  arrival       timestamptz NOT NULL,
  terminal      text NOT NULL DEFAULT 'T1',
  gate          text NOT NULL DEFAULT 'G1',
  status        text NOT NULL DEFAULT 'On Time'
                  CHECK (status IN ('On Time','Delayed','Boarding','Departed','Cancelled')),
  price         numeric DEFAULT 3500,
  duration_mins int DEFAULT 120,
  aircraft      text DEFAULT 'Airbus A320',
  created_at    timestamptz DEFAULT now()
);

ALTER TABLE flights ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_flights" ON flights;
CREATE POLICY "anon_select_flights" ON flights FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_flights" ON flights;
CREATE POLICY "anon_insert_flights" ON flights FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_flights" ON flights;
CREATE POLICY "anon_update_flights" ON flights FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_flights" ON flights;
CREATE POLICY "anon_delete_flights" ON flights FOR DELETE TO anon, authenticated USING (true);

-- ======= PASSENGERS =======
CREATE TABLE IF NOT EXISTS passengers (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name           text NOT NULL,
  last_name            text NOT NULL,
  date_of_birth        date NOT NULL,
  gender               text NOT NULL CHECK (gender IN ('Male','Female','Other')),
  nationality          text NOT NULL,
  travel_type          text NOT NULL CHECK (travel_type IN ('Domestic','International')),
  govt_id_no           text,
  passport_no          text,
  passport_issue       date,
  passport_expiry      date,
  visa_no              text,
  flight_id            uuid REFERENCES flights(id) ON DELETE SET NULL,
  seat_no              text NOT NULL,
  ticket_no            text NOT NULL UNIQUE,
  booking_date         timestamptz DEFAULT now(),
  face_image           text,
  face_descriptor      text,
  face_registered      boolean NOT NULL DEFAULT false,
  current_checkpoint   text NOT NULL DEFAULT 'NOT_ARRIVED',
  created_at           timestamptz DEFAULT now(),
  price                numeric DEFAULT 0,
  email                text,
  payment_id           text,
  payment_status       text NOT NULL DEFAULT 'PENDING'
                         CHECK (payment_status IN ('PENDING','PAID','FAILED','REFUNDED')),
  bag_tagged           boolean DEFAULT false,
  bag_accepted         boolean DEFAULT false,
  boarding_status      text DEFAULT NULL,
  checked_in           boolean DEFAULT false,
  boarding_pass_issued boolean DEFAULT false,
  security_cleared     boolean DEFAULT false
);

-- Checkpoint constraint (full journey including Check-In / Gate / Boarded)
ALTER TABLE passengers DROP CONSTRAINT IF EXISTS passengers_current_checkpoint_check;
ALTER TABLE passengers DROP CONSTRAINT IF EXISTS passengers_current_checkpoint_check1;
ALTER TABLE passengers DROP CONSTRAINT IF EXISTS passengers_current_checkpoint_check2;
ALTER TABLE passengers ADD CONSTRAINT passengers_current_checkpoint_check
  CHECK (current_checkpoint IN (
    'NOT_ARRIVED','ENTRY','CHECK_IN','BAG_DROP','SECURITY',
    'IMMIGRATION','GATE','BOARDING','BOARDED','DEPARTED'
  ));

ALTER TABLE passengers DROP CONSTRAINT IF EXISTS passengers_boarding_status_check;
ALTER TABLE passengers ADD CONSTRAINT passengers_boarding_status_check
  CHECK (boarding_status IS NULL OR boarding_status IN ('PENDING','ALLOWED','DENIED','BOARDED'));

CREATE INDEX IF NOT EXISTS idx_passengers_ticket ON passengers(ticket_no);
CREATE INDEX IF NOT EXISTS idx_passengers_flight ON passengers(flight_id);

ALTER TABLE passengers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_passengers" ON passengers;
CREATE POLICY "anon_select_passengers" ON passengers FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_passengers" ON passengers;
CREATE POLICY "anon_insert_passengers" ON passengers FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_passengers" ON passengers;
CREATE POLICY "anon_update_passengers" ON passengers FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_passengers" ON passengers;
CREATE POLICY "anon_delete_passengers" ON passengers FOR DELETE TO anon, authenticated USING (true);

-- ======= JOURNEY LOGS =======
CREATE TABLE IF NOT EXISTS journey_logs (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  passenger_id  uuid NOT NULL REFERENCES passengers(id) ON DELETE CASCADE,
  checkpoint    text NOT NULL,
  status        text NOT NULL DEFAULT 'CLEARED',
  notes         text,
  scanned_by    text DEFAULT 'SYSTEM',
  created_at    timestamptz DEFAULT now()
);

ALTER TABLE journey_logs DROP CONSTRAINT IF EXISTS journey_logs_checkpoint_check;
ALTER TABLE journey_logs DROP CONSTRAINT IF EXISTS journey_logs_checkpoint_check1;
ALTER TABLE journey_logs DROP CONSTRAINT IF EXISTS journey_logs_checkpoint_check2;
ALTER TABLE journey_logs ADD CONSTRAINT journey_logs_checkpoint_check
  CHECK (checkpoint IN (
    'ENTRY','CHECK_IN','BAG_DROP','SECURITY','IMMIGRATION',
    'GATE','BOARDING','BOARDED','ARRIVED','DEPARTED'
  ));

CREATE INDEX IF NOT EXISTS idx_journey_passenger ON journey_logs(passenger_id);

ALTER TABLE journey_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_journey" ON journey_logs;
CREATE POLICY "anon_select_journey" ON journey_logs FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_journey" ON journey_logs;
CREATE POLICY "anon_insert_journey" ON journey_logs FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_journey" ON journey_logs;
CREATE POLICY "anon_update_journey" ON journey_logs FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_journey" ON journey_logs;
CREATE POLICY "anon_delete_journey" ON journey_logs FOR DELETE TO anon, authenticated USING (true);

-- ======= ALERTS =======
CREATE TABLE IF NOT EXISTS alerts (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type      text NOT NULL
                    CHECK (alert_type IN ('UNKNOWN_FACE','SPAM_SCAN','LOST_PERSON','LIVENESS_FAIL','DOCUMENT_MISMATCH','GENERAL')),
  severity        text NOT NULL DEFAULT 'MEDIUM'
                    CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
  description     text NOT NULL,
  checkpoint      text,
  captured_image  text,
  resolved        boolean NOT NULL DEFAULT false,
  created_at      timestamptz DEFAULT now()
);

ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_alerts" ON alerts;
CREATE POLICY "anon_select_alerts" ON alerts FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_alerts" ON alerts;
CREATE POLICY "anon_insert_alerts" ON alerts FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_alerts" ON alerts;
CREATE POLICY "anon_update_alerts" ON alerts FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_alerts" ON alerts;
CREATE POLICY "anon_delete_alerts" ON alerts FOR DELETE TO anon, authenticated USING (true);

-- ======= EMAILS (optional log of sent messages) =======
CREATE TABLE IF NOT EXISTS emails (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  passenger_id  uuid REFERENCES passengers(id) ON DELETE SET NULL,
  recipient     text NOT NULL,
  subject       text NOT NULL,
  body          text,
  email_type    text DEFAULT 'boarding-pass',
  status        text DEFAULT 'sent',
  created_at    timestamptz DEFAULT now()
);

ALTER TABLE emails ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_emails" ON emails;
CREATE POLICY "anon_select_emails" ON emails FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_emails" ON emails;
CREATE POLICY "anon_insert_emails" ON emails FOR INSERT TO anon, authenticated WITH CHECK (true);

-- ======= SEED SAMPLE FLIGHTS (today + next few days) =======
DO $$
DECLARE
  d int;
  hr int;
  dep_ts timestamptz;
  arr_ts timestamptz;
  fn text;
  base_ts timestamptz := date_trunc('day', now());
BEGIN
  -- Core sample flights
  INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft) VALUES
    ('AI-202','Air India','Delhi (DEL)','Mumbai (BOM)', now() + interval '3 hours', now() + interval '5 hours 15 min','T3','G12','On Time',4500,135,'Airbus A320'),
    ('6E-441','IndiGo','Mumbai (BOM)','Bangalore (BLR)', now() + interval '4 hours', now() + interval '5 hours 45 min','T1','G5','On Time',3800,105,'Airbus A320'),
    ('SG-114','SpiceJet','Chennai (MAA)','Hyderabad (HYD)', now() + interval '2 hours', now() + interval '3 hours 30 min','T2','G8','Boarding',2800,75,'Boeing 737'),
    ('AI-119','Air India International','Delhi (DEL)','Dubai (DXB)', now() + interval '6 hours', now() + interval '9 hours 30 min','T3','G22','On Time',18500,210,'Boeing 787'),
    ('EK-501','Emirates','Mumbai (BOM)','London (LHR)', now() + interval '8 hours', now() + interval '16 hours','T2','G31','On Time',42000,480,'Airbus A380'),
    ('IX-342','Air Arabia','Bangalore (BLR)','Sharjah (SHJ)', now() + interval '5 hours', now() + interval '8 hours 30 min','T1','G9','Delayed',12000,210,'Airbus A320')
  ON CONFLICT (flight_no) DO NOTHING;

  FOR d IN 0..3 LOOP
    FOREACH hr IN ARRAY ARRAY[10, 14, 17, 20] LOOP
      dep_ts := base_ts + (d || ' days')::interval + (hr || ' hours')::interval;
      arr_ts := dep_ts + '135 minutes'::interval;
      fn := 'AI-' || (2000 + d * 100 + hr);
      INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
      VALUES (fn, 'Air India', 'Delhi (DEL)', 'Mumbai (BOM)', dep_ts, arr_ts, 'T3', 'G12', 'On Time', 4500, 135, 'Airbus A320')
      ON CONFLICT (flight_no) DO NOTHING;

      dep_ts := base_ts + (d || ' days')::interval + ((hr + 1) || ' hours')::interval;
      arr_ts := dep_ts + '135 minutes'::interval;
      fn := 'AI-' || (2100 + d * 100 + hr);
      INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
      VALUES (fn, 'Air India', 'Mumbai (BOM)', 'Delhi (DEL)', dep_ts, arr_ts, 'T2', 'G5', 'On Time', 4500, 135, 'Airbus A320')
      ON CONFLICT (flight_no) DO NOTHING;

      dep_ts := base_ts + (d || ' days')::interval + ((hr + 2) || ' hours')::interval;
      arr_ts := dep_ts + '175 minutes'::interval;
      fn := '6E-' || (3000 + d * 100 + hr);
      INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
      VALUES (fn, 'IndiGo', 'Delhi (DEL)', 'Bangalore (BLR)', dep_ts, arr_ts, 'T1', 'G8', 'On Time', 5200, 175, 'Airbus A321')
      ON CONFLICT (flight_no) DO NOTHING;

      dep_ts := base_ts + (d || ' days')::interval + ((hr + 3) || ' hours')::interval;
      arr_ts := dep_ts + '210 minutes'::interval;
      fn := 'AI-' || (4000 + d * 100 + hr);
      INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
      VALUES (fn, 'Air India International', 'Delhi (DEL)', 'Dubai (DXB)', dep_ts, arr_ts, 'T3', 'G22', 'On Time', 18500, 210, 'Boeing 787')
      ON CONFLICT (flight_no) DO NOTHING;
    END LOOP;
  END LOOP;
END $$;



-- Done. Verify:
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- ======= search_flights (auto-creates flights for any date) =======
/*
# Create search_flights RPC function

## Summary
Creates a Postgres function `search_flights(p_origin, p_destination, p_date)` that:
1. Looks for existing flights on that date for the given route.
2. If none exist (date outside the seeded window), auto-generates and inserts
   flights for that route + date using realistic schedules, then returns them.
3. Returns the full flights row so the frontend can just call
   `supabase.rpc('search_flights', {...})` and always get results.

This makes the flight search work for ANY future date, not just the 7 days
that were pre-seeded.
*/

-- Drop existing function first (avoids "cannot remove parameter defaults" error)
DROP FUNCTION IF EXISTS search_flights(text, text, date);
DROP FUNCTION IF EXISTS public.search_flights(text, text, date);

CREATE OR REPLACE FUNCTION search_flights(
  p_origin      text,
  p_destination text,
  p_date        date
)
RETURNS SETOF flights
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  route_config RECORD;
  dep_ts       timestamptz;
  arr_ts       timestamptz;
  fn           text;
  rand_suffix  int;
  found_count  int;
  base_ts      timestamptz;
BEGIN
  base_ts := p_date::timestamptz;

  -- How many flights already exist for this exact route + date?
  SELECT count(*) INTO found_count
  FROM flights
  WHERE origin = p_origin
    AND destination = p_destination
    AND departure::date = p_date;

  -- Only auto-generate if none exist
  IF found_count = 0 THEN

    -- Determine schedule based on route
    SELECT
      CASE
        WHEN (p_origin IN ('Delhi (DEL)','Mumbai (BOM)','Bangalore (BLR)','Chennai (MAA)','Hyderabad (HYD)','Kolkata (CCU)')
          AND p_destination IN ('Delhi (DEL)','Mumbai (BOM)','Bangalore (BLR)','Chennai (MAA)','Hyderabad (HYD)','Kolkata (CCU)'))
          THEN 'Domestic'
        ELSE 'International'
      END AS travel_type,
      CASE
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Mumbai (BOM)'     THEN 135
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='Delhi (DEL)'      THEN 135
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Bangalore (BLR)'  THEN 175
        WHEN p_origin='Bangalore (BLR)' AND p_destination='Delhi (DEL)'      THEN 175
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='Bangalore (BLR)'  THEN 105
        WHEN p_origin='Bangalore (BLR)' AND p_destination='Mumbai (BOM)'     THEN 105
        WHEN p_origin='Chennai (MAA)'   AND p_destination='Hyderabad (HYD)'  THEN 75
        WHEN p_origin='Hyderabad (HYD)' AND p_destination='Chennai (MAA)'    THEN 75
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Kolkata (CCU)'    THEN 140
        WHEN p_origin='Kolkata (CCU)'   AND p_destination='Delhi (DEL)'      THEN 140
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Dubai (DXB)'      THEN 210
        WHEN p_origin='Dubai (DXB)'     AND p_destination='Delhi (DEL)'      THEN 210
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='Dubai (DXB)'      THEN 190
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='London (LHR)'     THEN 480
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Singapore (SIN)'  THEN 330
        WHEN p_origin='Bangalore (BLR)' AND p_destination='Sharjah (SHJ)'    THEN 230
        ELSE 150
      END AS duration_mins,
      CASE
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Mumbai (BOM)'     THEN 4500
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='Delhi (DEL)'      THEN 4500
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Bangalore (BLR)'  THEN 5200
        WHEN p_origin='Bangalore (BLR)' AND p_destination='Delhi (DEL)'      THEN 5200
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='Bangalore (BLR)'  THEN 3800
        WHEN p_origin='Bangalore (BLR)' AND p_destination='Mumbai (BOM)'     THEN 3800
        WHEN p_origin='Chennai (MAA)'   AND p_destination='Hyderabad (HYD)'  THEN 2800
        WHEN p_origin='Hyderabad (HYD)' AND p_destination='Chennai (MAA)'    THEN 2800
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Kolkata (CCU)'    THEN 4800
        WHEN p_origin='Kolkata (CCU)'   AND p_destination='Delhi (DEL)'      THEN 4800
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Dubai (DXB)'      THEN 18500
        WHEN p_origin='Dubai (DXB)'     AND p_destination='Delhi (DEL)'      THEN 18500
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='Dubai (DXB)'      THEN 16800
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='London (LHR)'     THEN 42000
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Singapore (SIN)'  THEN 32000
        WHEN p_origin='Bangalore (BLR)' AND p_destination='Sharjah (SHJ)'    THEN 14500
        ELSE 5000
      END AS price,
      CASE
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Mumbai (BOM)'     THEN 'Air India'
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='Delhi (DEL)'      THEN 'Air India'
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Bangalore (BLR)'  THEN 'IndiGo'
        WHEN p_origin='Bangalore (BLR)' AND p_destination='Delhi (DEL)'      THEN 'IndiGo'
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='Bangalore (BLR)'  THEN 'IndiGo'
        WHEN p_origin='Bangalore (BLR)' AND p_destination='Mumbai (BOM)'     THEN 'IndiGo'
        WHEN p_origin='Chennai (MAA)'   AND p_destination='Hyderabad (HYD)'  THEN 'SpiceJet'
        WHEN p_origin='Hyderabad (HYD)' AND p_destination='Chennai (MAA)'    THEN 'SpiceJet'
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Kolkata (CCU)'    THEN 'Air India'
        WHEN p_origin='Kolkata (CCU)'   AND p_destination='Delhi (DEL)'      THEN 'Air India'
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Dubai (DXB)'      THEN 'Air India International'
        WHEN p_origin='Dubai (DXB)'     AND p_destination='Delhi (DEL)'      THEN 'Air India International'
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='Dubai (DXB)'      THEN 'Emirates'
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='London (LHR)'     THEN 'Emirates'
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Singapore (SIN)'  THEN 'Singapore Airlines'
        WHEN p_origin='Bangalore (BLR)' AND p_destination='Sharjah (SHJ)'    THEN 'Air Arabia'
        ELSE 'IndiGo'
      END AS airline,
      CASE
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Mumbai (BOM)'     THEN 'AI'
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='Delhi (DEL)'      THEN 'AI'
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Bangalore (BLR)'  THEN '6E'
        WHEN p_origin='Bangalore (BLR)' AND p_destination='Delhi (DEL)'      THEN '6E'
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='Bangalore (BLR)'  THEN '6E'
        WHEN p_origin='Bangalore (BLR)' AND p_destination='Mumbai (BOM)'     THEN '6E'
        WHEN p_origin='Chennai (MAA)'   AND p_destination='Hyderabad (HYD)'  THEN 'SG'
        WHEN p_origin='Hyderabad (HYD)' AND p_destination='Chennai (MAA)'    THEN 'SG'
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Kolkata (CCU)'    THEN 'AI'
        WHEN p_origin='Kolkata (CCU)'   AND p_destination='Delhi (DEL)'      THEN 'AI'
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Dubai (DXB)'      THEN 'AI'
        WHEN p_origin='Dubai (DXB)'     AND p_destination='Delhi (DEL)'      THEN 'AI'
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='Dubai (DXB)'      THEN 'EK'
        WHEN p_origin='Mumbai (BOM)'    AND p_destination='London (LHR)'     THEN 'EK'
        WHEN p_origin='Delhi (DEL)'     AND p_destination='Singapore (SIN)'  THEN 'SQ'
        WHEN p_origin='Bangalore (BLR)' AND p_destination='Sharjah (SHJ)'    THEN 'IX'
        ELSE '6E'
      END AS prefix,
      CASE
        WHEN p_origin='Delhi (DEL)'    THEN 'T3'
        WHEN p_origin='Mumbai (BOM)'   THEN 'T2'
        WHEN p_origin='Bangalore (BLR)' THEN 'T1'
        ELSE 'T2'
      END AS terminal,
      CASE
        WHEN p_origin='Delhi (DEL)'    THEN 'G12'
        WHEN p_origin='Mumbai (BOM)'   THEN 'G5'
        WHEN p_origin='Bangalore (BLR)' THEN 'G8'
        ELSE 'G4'
      END AS gate,
      CASE
        WHEN (p_origin IN ('Delhi (DEL)','Mumbai (BOM)','Bangalore (BLR)','Chennai (MAA)','Hyderabad (HYD)','Kolkata (CCU)')
          AND p_destination IN ('Delhi (DEL)','Mumbai (BOM)','Bangalore (BLR)','Chennai (MAA)','Hyderabad (HYD)','Kolkata (CCU)'))
          THEN 'Airbus A320'
        WHEN p_destination IN ('London (LHR)') THEN 'Airbus A380'
        WHEN p_destination IN ('Singapore (SIN)') THEN 'Airbus A350'
        WHEN p_destination IN ('Dubai (DXB)') THEN 'Boeing 787'
        ELSE 'Airbus A320'
      END AS aircraft
    INTO route_config;

    -- Insert 3 flights: morning, afternoon, evening
    rand_suffix := floor(random() * 900 + 100)::int;

    -- Morning flight (~08:00 UTC)
    fn := route_config.prefix || '-' || (rand_suffix);
    dep_ts := base_ts + interval '8 hours';
    arr_ts := dep_ts + (route_config.duration_mins || ' minutes')::interval;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, route_config.airline, p_origin, p_destination, dep_ts, arr_ts,
            route_config.terminal, route_config.gate, 'On Time',
            route_config.price, route_config.duration_mins, route_config.aircraft)
    ON CONFLICT (flight_no) DO NOTHING;

    -- Afternoon flight (~14:00 UTC)
    fn := route_config.prefix || '-' || (rand_suffix + 1);
    dep_ts := base_ts + interval '14 hours';
    arr_ts := dep_ts + (route_config.duration_mins || ' minutes')::interval;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, route_config.airline, p_origin, p_destination, dep_ts, arr_ts,
            route_config.terminal, route_config.gate, 'On Time',
            route_config.price, route_config.duration_mins, route_config.aircraft)
    ON CONFLICT (flight_no) DO NOTHING;

    -- Evening flight (~20:00 UTC) — only for domestic + short-haul routes
    IF route_config.duration_mins <= 300 THEN
      fn := route_config.prefix || '-' || (rand_suffix + 2);
      dep_ts := base_ts + interval '20 hours';
      arr_ts := dep_ts + (route_config.duration_mins || ' minutes')::interval;
      INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
      VALUES (fn, route_config.airline, p_origin, p_destination, dep_ts, arr_ts,
              route_config.terminal, route_config.gate, 'On Time',
              route_config.price, route_config.duration_mins, route_config.aircraft)
      ON CONFLICT (flight_no) DO NOTHING;
    END IF;

  END IF;

  -- Return all flights for this route+date
  RETURN QUERY
  SELECT *
  FROM flights
  WHERE origin = p_origin
    AND destination = p_destination
    AND departure::date = p_date
  ORDER BY departure;

END;
$$;

-- Grant execute to anon and authenticated
GRANT EXECUTE ON FUNCTION search_flights(text, text, date) TO anon, authenticated;

