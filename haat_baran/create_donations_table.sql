-- Create Donation Status Enum
create type donation_status as enum (
  'PENDING',
  'APPROVED',
  'MEETING_REQUESTED',
  'SCHEDULED',
  'COMPLETED',
  'REJECTED'
);

-- Create Donations Table
create table donations (
  id uuid default gen_random_uuid() primary key,
  donor_id uuid references auth.users(id) not null,
  applicant_id uuid references applicants(id) not null,
  amount decimal(12, 2) default 0.0,
  status donation_status default 'PENDING',
  
  -- Admin Scheduled Meeting Details
  scheduled_at timestamp with time zone,
  scheduled_location text,
  
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- RLS Policies
alter table donations enable row level security;

-- Donors can see their own donations
create policy "Donors can view own donations"
  on donations for select
  using (auth.uid() = donor_id);

-- Donors can create requests
create policy "Donors can create donations"
  on donations for insert
  with check (auth.uid() = donor_id);

-- Donors can update their own donations (e.g. to Request Meeting)
create policy "Donors can update own donations"
  on donations for update
  using (auth.uid() = donor_id);

-- Admins can view all donations
-- (Assuming admins have a way to be identified, usually via a public.users table or custom claim. 
-- For simplicity in this demo environment, we often allow public/authenticated read or rely on app logic. 
-- But strictly:
-- create policy "Admins can view all" ... )
-- For now, allowing authenticated users to read usually helps dev, but let's restrict if possible.
-- If user table has 'role', we check that.
-- Let's stick to: "Authenticated can read" if we want transparency, or just specific policies.
-- Let's just allow all authenticated for select for now to avoid friction, or specific admin policy if `public.users` exists.
-- The `users` table exists (saw in context).

create policy "Admins can view all donations"
  on donations for select
  using (exists (select 1 from public.users where user_id = auth.uid() and user_type = 'ADMINISTRATOR'));

create policy "Admins can update all donations"
  on donations for update
  using (exists (select 1 from public.users where user_id = auth.uid() and user_type = 'ADMINISTRATOR'));
