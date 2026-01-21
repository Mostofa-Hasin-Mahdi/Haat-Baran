-- FIX: Correct Admin RLS Policy Column Name
-- Problem: The previous policy checked for `id` in public.users, but the column is named `user_id`.
-- This caused the Admin check to always fail even for valid Admins.

-- 1. Drop old/incorrect queries
drop policy if exists "Admins can view all donations" on donations;
drop policy if exists "Admins can update all donations" on donations;
drop policy if exists "Allow all users to view donations" on donations; -- Check cleanup
drop policy if exists "Allow all users to update donations" on donations; -- Check cleanup

-- 2. Recreate Correct Admin Policies using 'user_id'
create policy "Admins can view all donations"
  on donations for select
  using (exists (select 1 from public.users where user_id = auth.uid() and user_type = 'ADMINISTRATOR'));

create policy "Admins can update all donations"
  on donations for update
  using (exists (select 1 from public.users where user_id = auth.uid() and user_type = 'ADMINISTRATOR'));

-- Verification:
-- After running this, users with user_type='ADMINISTRATOR' will properly see the data.
