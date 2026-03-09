-- SQL Script to manually create an admin user in Supabase
-- Run this in your Supabase SQL Editor if you prefer SQL over Python

-- 1. Create admin user in users table
INSERT INTO users (email, name, user_type, phone, created_at, updated_at)
VALUES (
    'admin@peakmap.com',  -- Change this to your email
    'Admin User',          -- Change this to your name
    'admin',               -- This must be 'admin'
    '',                    -- Phone (optional)
    NOW(),
    NOW()
)
ON CONFLICT (email) DO UPDATE
SET user_type = 'admin', name = EXCLUDED.name;

-- 2. Get the user ID (you'll need this for Supabase Auth)
-- After running the above, check the ID:
SELECT id, email, name, user_type FROM users WHERE email = 'admin@peakmap.com';

-- 3. IMPORTANT: Create auth user in Supabase Dashboard
-- Since we can't create Supabase Auth users via SQL, you need to:
-- a) Go to Supabase Dashboard → Authentication → Users
-- b) Click "Add User" → "Create new user"
-- c) Enter email: admin@peakmap.com
-- d) Enter password (min 6 characters)
-- e) Auto Confirm User: YES (important!)
-- f) Click "Create user"

-- 4. Verify admin user exists
SELECT 
    u.id,
    u.email,
    u.name,
    u.user_type,
    u.created_at
FROM users u
WHERE u.user_type = 'admin';

-- Notes:
-- - The admin user must have user_type = 'admin' in the users table
-- - The admin must also exist in Supabase Auth (created via Dashboard)
-- - Make sure email addresses match in both places
