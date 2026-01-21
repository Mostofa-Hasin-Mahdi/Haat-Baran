-- =========================================================
-- MANUALLY CONFIRM EMAIL ADDRESSES
-- =========================================================
-- Use this script to bypass email verification for development.
-- =========================================================

-- 1. Confirm 'admin' user (by username in metadata)
UPDATE auth.users
SET email_confirmed_at = now()
WHERE raw_user_meta_data->>'username' = 'admin';

-- 2. Confirm 'volunteer' user
UPDATE auth.users
SET email_confirmed_at = now()
WHERE raw_user_meta_data->>'username' = 'volunteer';

-- 3. Confirm your own specific email (replace if needed, or if you used a username)
-- If you signed up with 'hasinmahdi.hmr@gmail.com' and provided 'hasin' as username:
UPDATE auth.users
SET email_confirmed_at = now()
WHERE email = 'poggerbhai@gmail.com';

-- Summary
DO $$
DECLARE
    confirmed_count INTEGER;
BEGIN
    SELECT count(*) INTO confirmed_count FROM auth.users WHERE email_confirmed_at IS NOT NULL;
    RAISE NOTICE 'Total confirmed users: %', confirmed_count;
END $$;
