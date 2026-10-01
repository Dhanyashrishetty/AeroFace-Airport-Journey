/*
# Face-Based Seamless Airport Journey System — Full Schema

## Summary
Creates all tables required for the face-based airport journey management system.

## Tables

### passengers
Stores all registered passengers with their personal details, travel documents, flight info,
and a stored face image (base64) used for face-recognition simulation at checkpoints.

### flights
Master list of flights with route, timing, and aircraft info. Linked from passengers.

### journey_logs
Records every checkpoint event per passenger (ENTRY, SECURITY, BOARDING, ARRIVED).
Each row has a timestamp and status update — used for real-time journey tracking.

### alerts
Security and spam events: unknown faces scanned without a booking, multiple failed scans,
lost child / person flags, and other admin-visible incidents.

## Security
All tables use RLS with anon+authenticated access (no login screen in this system).
Staff / admin views are controlled at the application layer via role columns.
*/

-- ======= FLIGHTS =======
CREATE TABLE IF NOT EXISTS flights (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  flight_no   text NOT NULL UNIQUE,
  airline     text NOT NULL,
  origin      text NOT NULL,
  destination text NOT NULL,
  departure   timestamptz NOT NULL,
  arrival     timestamptz NOT NULL,
  terminal    text NOT NULL DEFAULT 'T1',
  gate        text NOT NULL DEFAULT 'G1',
  status      text NOT NULL DEFAULT 'On Time' CHECK (status IN ('On Time','Delayed','Boarding','Departed','Cancelled')),
  created_at  timestamptz DEFAULT now()
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
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Personal Info
  first_name        text NOT NULL,
  last_name         text NOT NULL,
  date_of_birth     date NOT NULL,
  gender            text NOT NULL CHECK (gender IN ('Male','Female','Other')),
  nationality       text NOT NULL,
  -- Travel Documents
  travel_type       text NOT NULL CHECK (travel_type IN ('Domestic','International')),
  govt_id_no        text,          -- Aadhaar / Voter ID / Driving License for domestic
  passport_no       text,          -- For international
  passport_issue    date,
  passport_expiry   date,
  visa_no           text,
  -- Flight
  flight_id         uuid REFERENCES flights(id) ON DELETE SET NULL,
  seat_no           text NOT NULL,
  ticket_no         text NOT NULL UNIQUE,
  booking_date      timestamptz DEFAULT now(),
  -- Face
  face_image        text,          -- base64 data URL of registered face
  face_registered   boolean NOT NULL DEFAULT false,
  -- Status
  current_checkpoint text NOT NULL DEFAULT 'NOT_ARRIVED'
    CHECK (current_checkpoint IN ('NOT_ARRIVED','ENTRY','SECURITY','BOARDING','DEPARTED')),
  created_at        timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_passengers_ticket  ON passengers(ticket_no);
CREATE INDEX IF NOT EXISTS idx_passengers_flight  ON passengers(flight_id);

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
  checkpoint    text NOT NULL CHECK (checkpoint IN ('ENTRY','SECURITY','BOARDING','ARRIVED')),
  status        text NOT NULL DEFAULT 'CLEARED',
  notes         text,
  scanned_by    text DEFAULT 'SYSTEM',
  created_at    timestamptz DEFAULT now()
);

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
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type    text NOT NULL CHECK (alert_type IN ('UNKNOWN_FACE','SPAM_SCAN','LOST_PERSON','LIVENESS_FAIL','DOCUMENT_MISMATCH','GENERAL')),
  severity      text NOT NULL DEFAULT 'MEDIUM' CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
  description   text NOT NULL,
  checkpoint    text,
  captured_image text,  -- base64 of the unrecognised face
  resolved      boolean NOT NULL DEFAULT false,
  created_at    timestamptz DEFAULT now()
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

-- ======= SEED FLIGHTS =======
INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status) VALUES
  ('AI-202','Air India','Delhi (DEL)','Mumbai (BOM)', now() + interval '3 hours', now() + interval '5 hours 15 min','T3','G12','On Time'),
  ('6E-441','IndiGo','Mumbai (BOM)','Bangalore (BLR)', now() + interval '4 hours', now() + interval '5 hours 45 min','T1','G5','On Time'),
  ('SG-114','SpiceJet','Chennai (MAA)','Hyderabad (HYD)', now() + interval '2 hours', now() + interval '3 hours 30 min','T2','G8','Boarding'),
  ('AI-119','Air India International','Delhi (DEL)','Dubai (DXB)', now() + interval '6 hours', now() + interval '9 hours 30 min','T3','G22','On Time'),
  ('EK-501','Emirates','Mumbai (BOM)','London (LHR)', now() + interval '8 hours', now() + interval '16 hours','T2','G31','On Time'),
  ('IX-342','Air Arabia','Bangalore (BLR)','Sharjah (SHJ)', now() + interval '5 hours', now() + interval '8 hours 30 min','T1','G9','Delayed')
ON CONFLICT (flight_no) DO NOTHING;

-- ======= SEED PASSENGERS =======
DO $$
DECLARE
  f1 uuid; f2 uuid; f3 uuid; f4 uuid; f5 uuid;
BEGIN
  SELECT id INTO f1 FROM flights WHERE flight_no='AI-202'  LIMIT 1;
  SELECT id INTO f2 FROM flights WHERE flight_no='6E-441'  LIMIT 1;
  SELECT id INTO f3 FROM flights WHERE flight_no='SG-114'  LIMIT 1;
  SELECT id INTO f4 FROM flights WHERE flight_no='AI-119'  LIMIT 1;
  SELECT id INTO f5 FROM flights WHERE flight_no='EK-501'  LIMIT 1;

  INSERT INTO passengers (first_name,last_name,date_of_birth,gender,nationality,travel_type,govt_id_no,flight_id,seat_no,ticket_no,face_registered,current_checkpoint) VALUES
    ('Arjun','Sharma','1990-05-12','Male','Indian','Domestic','AADHAAR-4521-8823-9901',f1,'12A','TKT-2024-001',false,'NOT_ARRIVED'),
    ('Priya','Nair','1995-08-22','Female','Indian','Domestic','VOTER-KL-12345678',f2,'7C','TKT-2024-002',false,'NOT_ARRIVED'),
    ('Ravi','Kumar','1988-11-03','Male','Indian','Domestic','DL-TN-2345678901',f3,'22B','TKT-2024-003',false,'NOT_ARRIVED'),
    ('Sneha','Patel','1993-02-17','Female','Indian','International','AADHAAR-9012-3456-7890',f4,'5F','TKT-2024-004',false,'NOT_ARRIVED'),
    ('Mohammed','Ali','1985-07-30','Male','Indian','International','AADHAAR-1234-5678-9012',f5,'14D','TKT-2024-005',false,'NOT_ARRIVED'),
    ('Kavya','Reddy','1997-12-09','Female','Indian','Domestic','VOTER-AP-87654321',f2,'18E','TKT-2024-006',false,'NOT_ARRIVED')
  ON CONFLICT (ticket_no) DO NOTHING;

  UPDATE passengers SET
    passport_no='P1234567', passport_issue='2020-01-15', passport_expiry='2030-01-14', visa_no='UAE-2024-789012'
  WHERE ticket_no='TKT-2024-004';

  UPDATE passengers SET
    passport_no='P9876543', passport_issue='2019-06-20', passport_expiry='2029-06-19', visa_no='UK-2024-456789'
  WHERE ticket_no='TKT-2024-005';
END $$;
