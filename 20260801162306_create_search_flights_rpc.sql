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
