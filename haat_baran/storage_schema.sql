-- Create a new storage bucket for applicant photos
INSERT INTO storage.buckets (id, name, public) 
VALUES ('applicant_photos', 'applicant_photos', true);

-- Policy to allow public access to view photos
CREATE POLICY "Public Access" 
ON storage.objects FOR SELECT 
USING ( bucket_id = 'applicant_photos' );

-- Policy to allow Volunteers and Admins to upload photos
CREATE POLICY "Authenticated Upload" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'applicant_photos' 
  AND auth.role() = 'authenticated'
);

-- Policy to allow Volunteers and Admins to update their uploads
CREATE POLICY "Authenticated Update" 
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'applicant_photos' 
  AND auth.role() = 'authenticated'
);
