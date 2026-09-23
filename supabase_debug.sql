-- =====================================================================
-- KEEMO — SUPABASE DEBUG / RESET SCRIPT
-- Run these one section at a time in Supabase SQL Editor.
-- Paste the output back if anything looks off.
-- =====================================================================

-- 1. Verify the migration actually applied. All rows should be present.
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'profiles'
ORDER BY ordinal_position;
-- Expected columns include: subscription_status, trial_started_at, preferred_language

-- 2. Verify the trigger + function exist and are the NEW versions.
SELECT tgname, pg_get_triggerdef(oid)
FROM pg_trigger
WHERE tgname = 'on_auth_user_created';

SELECT pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = 'handle_new_user' AND pronamespace = 'public'::regnamespace;
-- The body should mention 'subscription_status' and '48 hours'.

-- 3. See what actually exists across the three tables.
SELECT id, email, email_confirmed_at, raw_user_meta_data
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;

SELECT id, email, subscription_status, is_active,
       trial_started_at, subscription_expires_at, role, created_at
FROM public.profiles
ORDER BY created_at DESC
LIMIT 10;

SELECT user_id, device_id, device_model, is_trial_device, bound_at
FROM public.device_bindings
ORDER BY bound_at DESC
LIMIT 10;

-- 4. Full nuclear reset — deletes ALL test users (auth + profile + bindings)
--    Uncomment ONLY if you want a completely fresh slate.
-- DELETE FROM auth.users;
-- (profiles + device_bindings + accepted_orders_log cascade via ON DELETE CASCADE)

-- 5. Manually simulate the trigger for debugging (as postgres, no auth needed)
--    Uncomment and edit values to test:
-- SELECT public.handle_new_user() FROM (
--     SELECT gen_random_uuid() AS id,
--            'debug@example.com'::text AS email,
--            '{"full_name":"Debug","phone_number":"0790000000","device_id":"debug-device-xyz","device_model":"Debug","preferred_language":"en"}'::jsonb AS raw_user_meta_data
-- ) AS NEW;
