-- FIX: Grant DELETE permissions to Admins for Applicants and Donations
-- Problem: Admins could not delete applicants because they lacked DELETE policies on 'applicants' and 'donations' tables.

-- 1. Allow Admins to DELETE from 'applicants'
drop policy if exists "Admins can delete applicants" on applicants;
create policy "Admins can delete applicants"
  on applicants for delete
  using (exists (select 1 from public.users where user_id = auth.uid() and user_type = 'ADMINISTRATOR'));

-- 2. Allow Admins to DELETE from 'donations' (Required for cascade delete logic)
drop policy if exists "Admins can delete donations" on donations;
create policy "Admins can delete donations"
  on donations for delete
  using (exists (select 1 from public.users where user_id = auth.uid() and user_type = 'ADMINISTRATOR'));

-- 3. Allow Admins to UPDATE 'applicants' (For Edit functionality)
drop policy if exists "Admins can update applicants" on applicants;
create policy "Admins can update applicants"
  on applicants for update
  using (exists (select 1 from public.users where user_id = auth.uid() and user_type = 'ADMINISTRATOR'));

-- Verification:
-- Run this script in the Supabase SQL Editor.
-- Then try deleting an applicant again.
