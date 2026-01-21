-- ============================================
-- HAAT BARAN - LOGIN & USER SCHEMA
-- ============================================

-- 1. Create the base users table
CREATE TABLE IF NOT EXISTS public.users (
    user_id UUID PRIMARY KEY DEFAULT auth.uid(), -- Link to Supabase Auth User ID
    username VARCHAR(50),
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    user_type VARCHAR(20) NOT NULL DEFAULT 'DONOR' CHECK (user_type IN ('VOLUNTEER', 'DONOR', 'ADMINISTRATOR')),
    account_status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (account_status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED', 'PENDING')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create Role Specific Tables

-- Volunteer Table
CREATE TABLE IF NOT EXISTS public.volunteers (
    volunteer_id SERIAL PRIMARY KEY,
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    assigned_region VARCHAR(100),
    performance_score DECIMAL(5,2) DEFAULT 0.00,
    total_applications_collected INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Donor Table
CREATE TABLE IF NOT EXISTS public.donors (
    donor_id SERIAL PRIMARY KEY,
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    total_donated DECIMAL(15,2) DEFAULT 0.00,
    donation_count INTEGER DEFAULT 0,
    donor_type VARCHAR(20) DEFAULT 'INDIVIDUAL',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Administrator Table
CREATE TABLE IF NOT EXISTS public.administrators (
    admin_id SERIAL PRIMARY KEY,
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    access_level VARCHAR(20) DEFAULT 'MODERATOR',
    department VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);


-- 3. Row Level Security (RLS) - Basic Setup
-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.administrators ENABLE ROW LEVEL SECURITY;

-- Policies (Open for now to facilitate development, refine for production)
-- Allow users to view their own data
CREATE POLICY "Users can view their own profile" ON public.users
    FOR SELECT USING (auth.uid() = user_id);

-- Allow everyone to insert (needed for signup trigger/logic if not using trigger)
-- Ideally, we use a Trigger for safe user creation.

-- 4. Trigger to handle new user signup automatically
-- This ensures that when a user signs up via Supabase Auth, they are added to public.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (user_id, email, user_type)
  VALUES (new.id, new.email, 'DONOR'); -- Default to DONOR
  
  -- Also create the donor record
  INSERT INTO public.donors (user_id)
  VALUES (new.id);
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger using the function
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Comment:
-- For VOLUNTEER and ADMINISTRATOR, you will manually update the `user_type` in `public.users` 
-- and insert a record into `public.volunteers` or `public.administrators` 
-- and delete the `public.donors` record if needed, OR just creating them manually from the start 
-- doesn't trigger this if you create them in `auth.users` without triggering this? 
-- Actually, the trigger runs on ANY insert to auth.users. 
-- So even for Admin, it will start as Donor. You just strictly update it in the DB Table editor.
