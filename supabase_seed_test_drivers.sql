-- =====================================================================
-- KEEMO — SEED 4 TEST DRIVERS (run in Supabase SQL Editor)
-- =====================================================================
-- Creates fake driver accounts in each subscription state so the Admin
-- dashboard has something to click on.
--
-- All accounts share the password  Keemo!Test123
-- (you can't actually log in as them from the phone since your device is
--  already bound to your real account — they exist purely for the admin
--  UI to list and act on.)
-- =====================================================================

-- We need the pgcrypto extension for crypt() + gen_salt('bf').
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- --------------------------------------------------------------------
-- Helper: reversibly seed a single fake auth user + driver profile.
-- The on_auth_user_created trigger fires and creates the trial profile.
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._seed_test_driver(
    p_email        TEXT,
    p_full_name    TEXT,
    p_phone        TEXT,
    p_device_id    TEXT,
    p_device_model TEXT
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_id UUID := gen_random_uuid();
BEGIN
    INSERT INTO auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at,
        confirmation_token, email_change, email_change_token_new, recovery_token
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        v_id,
        'authenticated',
        'authenticated',
        p_email,
        crypt('Keemo!Test123', gen_salt('bf')),
        NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object(
            'full_name',          p_full_name,
            'phone_number',       p_phone,
            'device_id',          p_device_id,
            'device_model',       p_device_model,
            'preferred_language', 'en'
        ),
        NOW(), NOW(),
        '', '', '', ''
    );
    RETURN v_id;
END;
$$;

-- --------------------------------------------------------------------
-- Seed the four drivers
-- --------------------------------------------------------------------
DO $$
DECLARE
    v_trial_id    UUID;
    v_active_id   UUID;
    v_expired_id  UUID;
    v_inactive_id UUID;
BEGIN
    v_trial_id := public._seed_test_driver(
        'test.trial@keemo.local',    'Ahmad Al-Trial',    '0790000001',
        'test-device-trial',         'Test Pixel 6');

    v_active_id := public._seed_test_driver(
        'test.active@keemo.local',   'Sara Al-Active',    '0790000002',
        'test-device-active',        'Test Galaxy S23');

    v_expired_id := public._seed_test_driver(
        'test.expired@keemo.local',  'Omar Al-Expired',   '0790000003',
        'test-device-expired',       'Test Xiaomi Note');

    v_inactive_id := public._seed_test_driver(
        'test.inactive@keemo.local', 'Layla Al-Inactive', '0790000004',
        'test-device-inactive',      'Test OPPO A17');

    -- Trial user: leave as-is (trigger already gave them 48h trial).

    -- Active user: activate for 30 days.
    UPDATE public.profiles
    SET subscription_status     = 'active',
        is_active               = true,
        subscription_expires_at = NOW() + INTERVAL '30 days',
        trial_started_at        = NULL
    WHERE id = v_active_id;
    UPDATE public.device_bindings SET is_trial_device = false WHERE user_id = v_active_id;

    -- Expired user: 1 hour past expiry.
    UPDATE public.profiles
    SET subscription_status     = 'expired',
        is_active               = false,
        subscription_expires_at = NOW() - INTERVAL '1 hour',
        trial_started_at        = NULL
    WHERE id = v_expired_id;
    UPDATE public.device_bindings SET is_trial_device = false WHERE user_id = v_expired_id;

    -- Inactive user: explicit deactivation.
    UPDATE public.profiles
    SET subscription_status = 'inactive',
        is_active           = false,
        subscription_expires_at = NULL,
        trial_started_at    = NULL
    WHERE id = v_inactive_id;
END $$;

-- Drop the helper so we don't leave junk exposed.
DROP FUNCTION public._seed_test_driver(TEXT, TEXT, TEXT, TEXT, TEXT);

-- --------------------------------------------------------------------
-- Verify
-- --------------------------------------------------------------------
SELECT email, full_name, subscription_status, is_active,
       subscription_expires_at, role
FROM public.profiles
WHERE email LIKE 'test.%@keemo.local'
ORDER BY email;

-- =====================================================================
-- To WIPE the test drivers later:
--   DELETE FROM auth.users WHERE email LIKE 'test.%@keemo.local';
-- (cascades to profiles + device_bindings + accepted_orders_log)
-- =====================================================================
