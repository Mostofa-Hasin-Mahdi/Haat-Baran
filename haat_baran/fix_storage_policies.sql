-- 1. Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('applicant_photos', 'applicant_photos', true)
ON CONFLICT (id) DO NOTHING;

-- Force public=true in case it was created differently before
UPDATE storage.buckets SET public = true WHERE id = 'applicant_photos';

-- 2. Drop existing policies to avoid conflicts (SAFEST approach for re-running)
-- We wrap these in DO blocks or just executing them one by one. 
-- Supabase SQL editor often handles multiple statements, but if one fails, subsequent ones might not run depending on transaction mode.
-- Simple DROP IF EXISTS is usually safe.

DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Upload" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Update" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Delete" ON storage.objects;

-- 3. Create Policy: Public Read
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'applicant_photos' );

-- 4. Create Policy: Authenticated Upload
CREATE POLICY "Authenticated Upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'applicant_photos' AND
  auth.role() = 'authenticated'
);

-- 5. Create Policy: Authenticated Update
CREATE POLICY "Authenticated Update"
ON storage.objects FOR UPDATE
USING ( bucket_id = 'applicant_photos' AND auth.role() = 'authenticated' );

-- 6. Create Policy: Authenticated Delete
CREATE POLICY "Authenticated Delete"
ON storage.objects FOR DELETE
USING ( bucket_id = 'applicant_photos' AND auth.role() = 'authenticated' );
