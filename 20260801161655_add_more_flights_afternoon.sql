/*
# Add more flights with afternoon/evening departures for today

## Summary
Adds additional flights for today and tomorrow with departure times in the
afternoon and evening (UTC), so the flight search always returns results
even when earlier flights have already departed.

## No new tables
Inserts into existing flights table only.
*/

DO $$
DECLARE
  base_ts timestamptz := date_trunc('day', now());
  d int;
  hr int;
  dep_ts timestamptz;
  arr_ts timestamptz;
  fn text;
BEGIN
  FOR d IN 0..3 LOOP
    -- Delhi -> Mumbai at 14:00, 17:00, 20:00
    FOREACH hr IN ARRAY ARRAY[14, 17, 20] LOOP
      dep_ts := base_ts + (d || ' days')::interval + (hr || ' hours')::interval;
      arr_ts := dep_ts + '135 minutes'::interval;
      fn := 'AI-' || (2000 + d * 100 + hr);
      INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
      VALUES (fn, 'Air India', 'Delhi (DEL)', 'Mumbai (BOM)', dep_ts, arr_ts, 'T3', 'G12', 'On Time', 4500, 135, 'Airbus A320')
      ON CONFLICT (flight_no) DO NOTHING;
    END LOOP;

    -- Mumbai -> Delhi at 15:00, 18:00, 21:00
    FOREACH hr IN ARRAY ARRAY[15, 18, 21] LOOP
      dep_ts := base_ts + (d || ' days')::interval + (hr || ' hours')::interval;
      arr_ts := dep_ts + '135 minutes'::interval;
      fn := 'AI-' || (2100 + d * 100 + hr);
      INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
      VALUES (fn, 'Air India', 'Mumbai (BOM)', 'Delhi (DEL)', dep_ts, arr_ts, 'T2', 'G5', 'On Time', 4500, 135, 'Airbus A320')
      ON CONFLICT (flight_no) DO NOTHING;
    END LOOP;

    -- Delhi -> Bangalore at 13:00, 16:00, 19:00
    FOREACH hr IN ARRAY ARRAY[13, 16, 19] LOOP
      dep_ts := base_ts + (d || ' days')::interval + (hr || ' hours')::interval;
      arr_ts := dep_ts + '175 minutes'::interval;
      fn := '6E-' || (2200 + d * 100 + hr);
      INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
      VALUES (fn, 'IndiGo', 'Delhi (DEL)', 'Bangalore (BLR)', dep_ts, arr_ts, 'T1', 'G8', 'On Time', 5200, 175, 'Airbus A321')
      ON CONFLICT (flight_no) DO NOTHING;
    END LOOP;

    -- Mumbai -> Bangalore at 14:00, 17:00, 20:00
    FOREACH hr IN ARRAY ARRAY[14, 17, 20] LOOP
      dep_ts := base_ts + (d || ' days')::interval + (hr || ' hours')::interval;
      arr_ts := dep_ts + '105 minutes'::interval;
      fn := '6E-' || (2300 + d * 100 + hr);
      INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
      VALUES (fn, 'IndiGo', 'Mumbai (BOM)', 'Bangalore (BLR)', dep_ts, arr_ts, 'T1', 'G5', 'On Time', 3800, 105, 'Airbus A320')
      ON CONFLICT (flight_no) DO NOTHING;
    END LOOP;

    -- Bangalore -> Mumbai at 15:00, 18:00
    FOREACH hr IN ARRAY ARRAY[15, 18] LOOP
      dep_ts := base_ts + (d || ' days')::interval + (hr || ' hours')::interval;
      arr_ts := dep_ts + '105 minutes'::interval;
      fn := '6E-' || (2400 + d * 100 + hr);
      INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
      VALUES (fn, 'IndiGo', 'Bangalore (BLR)', 'Mumbai (BOM)', dep_ts, arr_ts, 'T1', 'G2', 'On Time', 3800, 105, 'Airbus A320')
      ON CONFLICT (flight_no) DO NOTHING;
    END LOOP;

    -- Chennai -> Hyderabad at 14:00, 17:00, 20:00
    FOREACH hr IN ARRAY ARRAY[14, 17, 20] LOOP
      dep_ts := base_ts + (d || ' days')::interval + (hr || ' hours')::interval;
      arr_ts := dep_ts + '75 minutes'::interval;
      fn := 'SG-' || (2500 + d * 100 + hr);
      INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
      VALUES (fn, 'SpiceJet', 'Chennai (MAA)', 'Hyderabad (HYD)', dep_ts, arr_ts, 'T2', 'G8', 'On Time', 2800, 75, 'Boeing 737')
      ON CONFLICT (flight_no) DO NOTHING;
    END LOOP;

    -- Delhi -> Dubai at 14:00, 20:00
    FOREACH hr IN ARRAY ARRAY[14, 20] LOOP
      dep_ts := base_ts + (d || ' days')::interval + (hr || ' hours')::interval;
      arr_ts := dep_ts + '210 minutes'::interval;
      fn := 'AI-' || (2600 + d * 100 + hr);
      INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
      VALUES (fn, 'Air India International', 'Delhi (DEL)', 'Dubai (DXB)', dep_ts, arr_ts, 'T3', 'G22', 'On Time', 18500, 210, 'Boeing 787')
      ON CONFLICT (flight_no) DO NOTHING;
    END LOOP;

    -- Delhi -> Kolkata at 16:00, 19:00
    FOREACH hr IN ARRAY ARRAY[16, 19] LOOP
      dep_ts := base_ts + (d || ' days')::interval + (hr || ' hours')::interval;
      arr_ts := dep_ts + '140 minutes'::interval;
      fn := 'AI-' || (2700 + d * 100 + hr);
      INSERT INTO flights (flight_no, airline, origin, destination, departure, arrival, terminal, gate, status, price, duration_mins, aircraft)
      VALUES (fn, 'Air India', 'Delhi (DEL)', 'Kolkata (CCU)', dep_ts, arr_ts, 'T3', 'G14', 'On Time', 4800, 140, 'Airbus A320')
      ON CONFLICT (flight_no) DO NOTHING;
    END LOOP;

  END LOOP;
END $$;
