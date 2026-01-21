-- Create Applicants table
CREATE TABLE IF NOT EXISTS public.applicants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  
  -- Personal Info
  name TEXT NOT NULL,
  age INTEGER NOT NULL,
  photo TEXT, -- URL or Path
  fingerprint_photo TEXT, -- URL or Path
  
  -- Demographics
  marital_status TEXT NOT NULL CHECK (marital_status IN ('single', 'married', 'divorced', 'widowed')),
  family_members INTEGER NOT NULL DEFAULT 0,
  current_occupation TEXT,
  
  -- Address
  division TEXT,
  district TEXT,
  upazilla TEXT,
  thana TEXT,
  location TEXT, -- Full address string
  
  -- Business & Funding
  business_goal TEXT,
  funding_goal NUMERIC NOT NULL,
  current_funding NUMERIC DEFAULT 0,
  
  -- Status tracking
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
  
  -- Verification (Admin/Volunteer actions)
  verified_by UUID REFERENCES public.users(user_id),
  created_by UUID REFERENCES public.users(user_id) DEFAULT auth.uid()
);

-- Enable RLS
ALTER TABLE public.applicants ENABLE ROW LEVEL SECURITY;

-- Policies

-- 1. Volunteers can insert new applicants
CREATE POLICY "Volunteers can create applicants" ON public.applicants
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE user_id = auth.uid() 
      AND user_type IN ('VOLUNTEER', 'ADMINISTRATOR')
    )
  );

-- 2. Admins can update applicants (Approve/Reject)
CREATE POLICY "Admins can update applicants" ON public.applicants
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE user_id = auth.uid() 
      AND user_type = 'ADMINISTRATOR'
    )
  );

-- 3. Admins and Volunteers can view all applicants (Pending & Approved)
CREATE POLICY "Staff can view all applicants" ON public.applicants
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE user_id = auth.uid() 
      AND user_type IN ('VOLUNTEER', 'ADMINISTRATOR')
    )
  );

-- 4. Donors (and public?) can view APPROVED applicants only
CREATE POLICY "Donors can view approved applicants" ON public.applicants
  FOR SELECT USING (
    status = 'APPROVED'
  );

-- Storage buckets for photos (Optional setup, usually done in UI but good to note)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('applicant_photos', 'applicant_photos', true);
