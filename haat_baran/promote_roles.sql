-- =========================================================
-- PROMOTE USERS TO ROLES
-- =========================================================
-- INSTRUCTIONS:
-- 1. Create two accounts using the "Sign Up" page in the App.
--    - Account 1: Username = 'admin', Password = '1234', Email = (any valid email)
--    - Account 2: Username = 'volunteer', Password = '1234', Email = (any valid email)
-- 2. Run this script in Supabase SQL Editor.
-- =========================================================

-- 1. Promote 'admin' user
DO $$
DECLARE
    target_user_id UUID;
BEGIN
    -- Find the user by username
    SELECT user_id INTO target_user_id FROM public.users WHERE username = 'admin';

    IF target_user_id IS NOT NULL THEN
        -- Update user_type
        UPDATE public.users SET user_type = 'ADMINISTRATOR' WHERE user_id = target_user_id;

        -- Create Administrator record
        INSERT INTO public.administrators (user_id, access_level, department)
        VALUES (target_user_id, 'SUPER_ADMIN', 'IT')
        ON CONFLICT (user_id) DO NOTHING;

        -- Remove from Donors (since they started as donor)
        DELETE FROM public.donors WHERE user_id = target_user_id;
        
        RAISE NOTICE 'User "admin" has been promoted to ADMINISTRATOR.';
    ELSE
        RAISE NOTICE 'User "admin" not found. Please Sign Up first.';
    END IF;
END $$;


-- 2. Promote 'volunteer' user
DO $$
DECLARE
    target_user_id UUID;
BEGIN
    -- Find the user by username
    SELECT user_id INTO target_user_id FROM public.users WHERE username = 'volunteer';

    IF target_user_id IS NOT NULL THEN
        -- Update user_type
        UPDATE public.users SET user_type = 'VOLUNTEER' WHERE user_id = target_user_id;

        -- Create Volunteer record
        INSERT INTO public.volunteers (user_id, assigned_region, performance_score)
        VALUES (target_user_id, 'Dhaka', 100.00)
        ON CONFLICT (user_id) DO NOTHING;

        -- Remove from Donors
        DELETE FROM public.donors WHERE user_id = target_user_id;
        
        RAISE NOTICE 'User "volunteer" has been promoted to VOLUNTEER.';
    ELSE
         RAISE NOTICE 'User "volunteer" not found. Please Sign Up first.';
    END IF;
END $$;
