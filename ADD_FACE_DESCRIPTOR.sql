-- Optional but recommended: store face embedding at registration for faster matching
ALTER TABLE passengers ADD COLUMN IF NOT EXISTS face_descriptor text;
