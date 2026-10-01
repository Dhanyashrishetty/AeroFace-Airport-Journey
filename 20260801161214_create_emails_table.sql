/*
# Create emails table for tracking sent boarding pass emails

## Summary
Stores a log of every boarding-pass email sent by the system after a successful
Razorpay payment. Used by the send-boarding-pass edge function to record sends
and by the frontend to confirm delivery.

## New Table
- emails
  - id (uuid, PK)
  - passenger_id (uuid, FK to passengers)
  - recipient_email (text)
  - subject (text)
  - body (text)
  - pdf_attached (boolean, whether a PDF boarding pass was attached)
  - status (text: SENT or FAILED)
  - created_at (timestamp)

## Security
RLS enabled with anon+authenticated CRUD (no-login app).
*/

CREATE TABLE IF NOT EXISTS emails (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  passenger_id    uuid REFERENCES passengers(id) ON DELETE CASCADE,
  recipient_email text NOT NULL,
  subject         text NOT NULL,
  body            text NOT NULL,
  pdf_attached    boolean NOT NULL DEFAULT true,
  status          text NOT NULL DEFAULT 'SENT' CHECK (status IN ('SENT','FAILED')),
  created_at      timestamptz DEFAULT now()
);

ALTER TABLE emails ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_emails" ON emails;
CREATE POLICY "anon_select_emails" ON emails FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_emails" ON emails;
CREATE POLICY "anon_insert_emails" ON emails FOR INSERT TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_emails" ON emails;
CREATE POLICY "anon_update_emails" ON emails FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_emails" ON emails;
CREATE POLICY "anon_delete_emails" ON emails FOR DELETE TO anon, authenticated USING (true);
