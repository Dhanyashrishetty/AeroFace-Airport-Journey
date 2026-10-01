/*
# Add payment, email, price fields and expand flight seed data

## Summary
1. Adds price, email, payment_id, payment_status columns to passengers.
2. Adds price, duration_mins, aircraft columns to flights.
3. Seeds many flights across multiple routes and 7 days so flight search works.

## Modified Tables
- passengers: +price, +email, +payment_id, +payment_status
- flights: +price, +duration_mins, +aircraft

## Security
No new tables. Existing RLS policies already cover anon CRUD on both tables.
*/

-- ======= passengers new columns =======
ALTER TABLE passengers
  ADD COLUMN IF NOT EXISTS price numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS email text,
  ADD COLUMN IF NOT EXISTS payment_id text,
  ADD COLUMN IF NOT EXISTS payment_status text NOT NULL DEFAULT 'PENDING'
    CHECK (payment_status IN ('PENDING','PAID','FAILED','REFUNDED'));

-- ======= flights new columns =======
ALTER TABLE flights
  ADD COLUMN IF NOT EXISTS price numeric DEFAULT 3500,
  ADD COLUMN IF NOT EXISTS duration_mins int DEFAULT 120,
  ADD COLUMN IF NOT EXISTS aircraft text DEFAULT 'Airbus A320';

-- ======= Seed flights across routes and 7 days =======
-- Use a DO block with explicit text casts to avoid array typing issues
DO $$
DECLARE
  d int;
  hr int;
  dep_ts timestamptz;
  arr_ts timestamptz;
  fn text;
  status text;
  base_ts timestamptz := date_trunc('day', now());
BEGIN
  FOR d IN 0..6 LOOP
    -- Delhi -> Mumbai
    hr := 6 + (d % 4) * 3;
    dep_ts := base_ts + (d || ' days')::interval + (hr || ' hours')::interval;
    arr_ts := dep_ts + '135 minutes'::interval;
    fn := 'AI-' || (200 + d * 10);
    IF d = 0 AND hr < extract(hour from now())::int THEN status := 'Departed'; ELSE status := 'On Time'; END IF;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, 'Air India', 'Delhi (DEL)', 'Mumbai (BOM)', dep_ts, arr_ts, 'T3', 'G12', status, 4500, 135, 'Airbus A320')
    ON CONFLICT (flight_no) DO NOTHING;

    -- Mumbai -> Delhi
    dep_ts := base_ts + (d || ' days')::interval + ((hr + 5) || ' hours')::interval;
    arr_ts := dep_ts + '135 minutes'::interval;
    fn := 'AI-' || (300 + d * 10);
    IF d = 0 AND (hr + 5) < extract(hour from now())::int THEN status := 'Departed'; ELSE status := 'On Time'; END IF;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, 'Air India', 'Mumbai (BOM)', 'Delhi (DEL)', dep_ts, arr_ts, 'T2', 'G5', status, 4500, 135, 'Airbus A320')
    ON CONFLICT (flight_no) DO NOTHING;

    -- Delhi -> Bangalore
    dep_ts := base_ts + (d || ' days')::interval + ((hr + 2) || ' hours')::interval;
    arr_ts := dep_ts + '175 minutes'::interval;
    fn := '6E-' || (400 + d * 10);
    IF d = 0 AND (hr + 2) < extract(hour from now())::int THEN status := 'Departed'; ELSE status := 'On Time'; END IF;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, 'IndiGo', 'Delhi (DEL)', 'Bangalore (BLR)', dep_ts, arr_ts, 'T1', 'G8', status, 5200, 175, 'Airbus A321')
    ON CONFLICT (flight_no) DO NOTHING;

    -- Bangalore -> Delhi
    dep_ts := base_ts + (d || ' days')::interval + ((hr + 6) || ' hours')::interval;
    arr_ts := dep_ts + '175 minutes'::interval;
    fn := '6E-' || (500 + d * 10);
    IF d = 0 AND (hr + 6) < extract(hour from now())::int THEN status := 'Departed'; ELSE status := 'On Time'; END IF;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, 'IndiGo', 'Bangalore (BLR)', 'Delhi (DEL)', dep_ts, arr_ts, 'T1', 'G3', status, 5200, 175, 'Airbus A321')
    ON CONFLICT (flight_no) DO NOTHING;

    -- Mumbai -> Bangalore
    dep_ts := base_ts + (d || ' days')::interval + ((hr + 1) || ' hours')::interval;
    arr_ts := dep_ts + '105 minutes'::interval;
    fn := '6E-' || (600 + d * 10);
    IF d = 0 AND (hr + 1) < extract(hour from now())::int THEN status := 'Departed'; ELSE status := 'On Time'; END IF;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, 'IndiGo', 'Mumbai (BOM)', 'Bangalore (BLR)', dep_ts, arr_ts, 'T1', 'G5', status, 3800, 105, 'Airbus A320')
    ON CONFLICT (flight_no) DO NOTHING;

    -- Bangalore -> Mumbai
    dep_ts := base_ts + (d || ' days')::interval + ((hr + 4) || ' hours')::interval;
    arr_ts := dep_ts + '105 minutes'::interval;
    fn := '6E-' || (700 + d * 10);
    IF d = 0 AND (hr + 4) < extract(hour from now())::int THEN status := 'Departed'; ELSE status := 'On Time'; END IF;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, 'IndiGo', 'Bangalore (BLR)', 'Mumbai (BOM)', dep_ts, arr_ts, 'T1', 'G2', status, 3800, 105, 'Airbus A320')
    ON CONFLICT (flight_no) DO NOTHING;

    -- Chennai -> Hyderabad
    dep_ts := base_ts + (d || ' days')::interval + ((hr + 3) || ' hours')::interval;
    arr_ts := dep_ts + '75 minutes'::interval;
    fn := 'SG-' || (800 + d * 10);
    IF d = 0 AND (hr + 3) < extract(hour from now())::int THEN status := 'Departed'; ELSE status := 'On Time'; END IF;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, 'SpiceJet', 'Chennai (MAA)', 'Hyderabad (HYD)', dep_ts, arr_ts, 'T2', 'G8', status, 2800, 75, 'Boeing 737')
    ON CONFLICT (flight_no) DO NOTHING;

    -- Hyderabad -> Chennai
    dep_ts := base_ts + (d || ' days')::interval + ((hr + 7) || ' hours')::interval;
    arr_ts := dep_ts + '75 minutes'::interval;
    fn := 'SG-' || (900 + d * 10);
    IF d = 0 AND (hr + 7) < extract(hour from now())::int THEN status := 'Departed'; ELSE status := 'On Time'; END IF;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, 'SpiceJet', 'Hyderabad (HYD)', 'Chennai (MAA)', dep_ts, arr_ts, 'T2', 'G4', status, 2800, 75, 'Boeing 737')
    ON CONFLICT (flight_no) DO NOTHING;

    -- Delhi -> Kolkata
    dep_ts := base_ts + (d || ' days')::interval + ((hr + 2) || ' hours')::interval;
    arr_ts := dep_ts + '140 minutes'::interval;
    fn := 'AI-' || (1000 + d * 10);
    IF d = 0 AND (hr + 2) < extract(hour from now())::int THEN status := 'Departed'; ELSE status := 'On Time'; END IF;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, 'Air India', 'Delhi (DEL)', 'Kolkata (CCU)', dep_ts, arr_ts, 'T3', 'G14', status, 4800, 140, 'Airbus A320')
    ON CONFLICT (flight_no) DO NOTHING;

    -- Delhi -> Dubai (international)
    dep_ts := base_ts + (d || ' days')::interval + ((hr + 5) || ' hours')::interval;
    arr_ts := dep_ts + '210 minutes'::interval;
    fn := 'AI-' || (1100 + d * 10);
    IF d = 0 AND (hr + 5) < extract(hour from now())::int THEN status := 'Departed'; ELSE status := 'On Time'; END IF;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, 'Air India International', 'Delhi (DEL)', 'Dubai (DXB)', dep_ts, arr_ts, 'T3', 'G22', status, 18500, 210, 'Boeing 787')
    ON CONFLICT (flight_no) DO NOTHING;

    -- Mumbai -> London (international)
    dep_ts := base_ts + (d || ' days')::interval + ((hr + 8) || ' hours')::interval;
    arr_ts := dep_ts + '480 minutes'::interval;
    fn := 'EK-' || (1200 + d * 10);
    IF d = 0 AND (hr + 8) < extract(hour from now())::int THEN status := 'Departed'; ELSE status := 'On Time'; END IF;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, 'Emirates', 'Mumbai (BOM)', 'London (LHR)', dep_ts, arr_ts, 'T2', 'G31', status, 42000, 480, 'Airbus A380')
    ON CONFLICT (flight_no) DO NOTHING;

    -- Delhi -> Singapore (international)
    dep_ts := base_ts + (d || ' days')::interval + ((hr + 6) || ' hours')::interval;
    arr_ts := dep_ts + '330 minutes'::interval;
    fn := 'SQ-' || (1300 + d * 10);
    IF d = 0 AND (hr + 6) < extract(hour from now())::int THEN status := 'Departed'; ELSE status := 'On Time'; END IF;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, 'Singapore Airlines', 'Delhi (DEL)', 'Singapore (SIN)', dep_ts, arr_ts, 'T3', 'G24', status, 32000, 330, 'Airbus A350')
    ON CONFLICT (flight_no) DO NOTHING;

    -- Bangalore -> Sharjah (international)
    dep_ts := base_ts + (d || ' days')::interval + ((hr + 4) || ' hours')::interval;
    arr_ts := dep_ts + '230 minutes'::interval;
    fn := 'IX-' || (1400 + d * 10);
    IF d = 0 AND (hr + 4) < extract(hour from now())::int THEN status := 'Departed'; ELSE status := 'On Time'; END IF;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, 'Air Arabia', 'Bangalore (BLR)', 'Sharjah (SHJ)', dep_ts, arr_ts, 'T1', 'G9', status, 14500, 230, 'Airbus A320')
    ON CONFLICT (flight_no) DO NOTHING;

    -- Mumbai -> Dubai (international)
    dep_ts := base_ts + (d || ' days')::interval + ((hr + 3) || ' hours')::interval;
    arr_ts := dep_ts + '190 minutes'::interval;
    fn := 'EK-' || (1500 + d * 10);
    IF d = 0 AND (hr + 3) < extract(hour from now())::int THEN status := 'Departed'; ELSE status := 'On Time'; END IF;
    INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
    VALUES (fn, 'Emirates', 'Mumbai (BOM)', 'Dubai (DXB)', dep_ts, arr_ts, 'T2', 'G31', status, 16800, 190, 'Boeing 777')
    ON CONFLICT (flight_no) DO NOTHING;

  END LOOP;
END $$;

-- ======= Update existing seed passengers with price + email =======
UPDATE passengers SET price = 4500, email = 'arjun.sharma@example.com', payment_status = 'PAID', payment_id = 'pay_dummy_001' WHERE ticket_no = 'TKT-2024-001';
UPDATE passengers SET price = 3800, email = 'priya.nair@example.com', payment_status = 'PAID', payment_id = 'pay_dummy_002' WHERE ticket_no = 'TKT-2024-002';
UPDATE passengers SET price = 2800, email = 'ravi.kumar@example.com', payment_status = 'PAID', payment_id = 'pay_dummy_003' WHERE ticket_no = 'TKT-2024-003';
UPDATE passengers SET price = 18500, email = 'sneha.patel@example.com', payment_status = 'PAID', payment_id = 'pay_dummy_004' WHERE ticket_no = 'TKT-2024-004';
UPDATE passengers SET price = 42000, email = 'mohammed.ali@example.com', payment_status = 'PAID', payment_id = 'pay_dummy_005' WHERE ticket_no = 'TKT-2024-005';
UPDATE passengers SET price = 3800, email = 'kavya.reddy@example.com', payment_status = 'PAID', payment_id = 'pay_dummy_006' WHERE ticket_no = 'TKT-2024-006';
