-- ====================================================================
-- JEENY AUTO-CLICKER — SUPABASE SCHEMA
-- Safe to re-run in Supabase SQL Editor.
--
-- PRODUCTION CHECKLIST after running:
--   1. Enable pg_cron in Database → Extensions, then run:
--        SELECT cron.schedule('expire_stale_subs', '*/15 * * * *',
--            $$SELECT public.expire_stale_subscriptions();$$);
--      Without this, trial/active rows stay stale after expiry until
--      someone hits the admin RPCs — the app's UI routing still works
--      (it compares subscription_expires_at to NOW() directly), only
--      the admin dashboard's counts and status chips look wrong.
--   2. Promote your account: run once, while signed in as yourself —
--        SELECT public.promote_self_to_admin_bootstrap();
--      (Locked to the first-ever admin; ignored on re-run.)
--   3. In the app's admin Settings tab, set your real WhatsApp number.
-- ====================================================================

-- ====================================================================
-- 1. PROFILES
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    phone_number TEXT,
    is_active BOOLEAN DEFAULT false,
    subscription_expires_at TIMESTAMPTZ,
    role TEXT DEFAULT 'driver' CHECK (role IN ('driver', 'admin')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Additive migrations (safe to re-run)
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS subscription_status TEXT
        NOT NULL DEFAULT 'trial'
        CHECK (subscription_status IN ('trial', 'active', 'expired', 'inactive'));

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS trial_started_at TIMESTAMPTZ;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS preferred_language TEXT DEFAULT 'en'
        CHECK (preferred_language IN ('en', 'ar'));

-- Auto-touch updated_at on any profile UPDATE
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_touch_updated_at ON public.profiles;
CREATE TRIGGER profiles_touch_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- ====================================================================
-- 2. DEVICE BINDINGS  (1 device_id <-> 1 profile, ever)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.device_bindings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    device_model TEXT,
    is_trial_device BOOLEAN DEFAULT true,
    bound_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.device_bindings
    ADD COLUMN IF NOT EXISTS is_trial_device BOOLEAN DEFAULT true;

CREATE UNIQUE INDEX IF NOT EXISTS device_bindings_device_id_unique
    ON public.device_bindings (device_id);

-- ====================================================================
-- 3. ACCEPTED ORDERS LOG
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.accepted_orders_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    fare_amount NUMERIC(10, 2),
    pickup_time_mins INT,
    raw_screen_text TEXT,
    accepted_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 4. ADMIN SETTINGS (single-row runtime config)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.admin_settings (
    id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    admin_whatsapp_number TEXT,
    admin_display_name TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.admin_settings (id, admin_whatsapp_number, admin_display_name)
VALUES (1, NULL, 'Jeeny Auto-Clicker Admin')
ON CONFLICT (id) DO NOTHING;

DROP TRIGGER IF EXISTS admin_settings_touch_updated_at ON public.admin_settings;
CREATE TRIGGER admin_settings_touch_updated_at
    BEFORE UPDATE ON public.admin_settings
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- ====================================================================
-- RLS
-- ====================================================================
ALTER TABLE public.profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_bindings     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accepted_orders_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_settings      ENABLE ROW LEVEL SECURITY;

-- ---- is_admin() helper (SECURITY DEFINER + BYPASSRLS via postgres owner) ----
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
$$;
-- Only authenticated users need to check admin-ness. Anonymous callers
-- can't be admins by definition (auth.uid() is null), so exposing this
-- to anon just widens the attack surface for no benefit.
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- ---- profiles policies ----
DROP POLICY IF EXISTS "Users can view own profile"        ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile info" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles"      ON public.profiles;
DROP POLICY IF EXISTS "Admins can update all profiles"    ON public.profiles;

CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile info"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
    ON public.profiles FOR SELECT
    USING (public.is_admin());

CREATE POLICY "Admins can update all profiles"
    ON public.profiles FOR UPDATE
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ---- device_bindings policies ----
DROP POLICY IF EXISTS "Users can view own device binding"     ON public.device_bindings;
DROP POLICY IF EXISTS "Users can insert own device binding"   ON public.device_bindings;
DROP POLICY IF EXISTS "Admins can view all device bindings"   ON public.device_bindings;
DROP POLICY IF EXISTS "Admins can delete device bindings"     ON public.device_bindings;

CREATE POLICY "Users can view own device binding"
    ON public.device_bindings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own device binding"
    ON public.device_bindings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all device bindings"
    ON public.device_bindings FOR SELECT
    USING (public.is_admin());

CREATE POLICY "Admins can delete device bindings"
    ON public.device_bindings FOR DELETE
    USING (public.is_admin());

-- ---- accepted_orders_log policies ----
DROP POLICY IF EXISTS "Users can insert accepted order logs" ON public.accepted_orders_log;
DROP POLICY IF EXISTS "Users can view own order logs"        ON public.accepted_orders_log;
DROP POLICY IF EXISTS "Admins can view all order logs"       ON public.accepted_orders_log;

CREATE POLICY "Users can insert accepted order logs"
    ON public.accepted_orders_log FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own order logs"
    ON public.accepted_orders_log FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all order logs"
    ON public.accepted_orders_log FOR SELECT
    USING (public.is_admin());

-- ---- admin_settings policies ----
DROP POLICY IF EXISTS "Authed users can read admin settings" ON public.admin_settings;
DROP POLICY IF EXISTS "Admins can update admin settings"     ON public.admin_settings;

CREATE POLICY "Authed users can read admin settings"
    ON public.admin_settings FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admins can update admin settings"
    ON public.admin_settings FOR UPDATE
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ====================================================================
-- Pre-check RPC used by the client BEFORE calling auth.signUp,
-- because Supabase Auth swallows trigger error details.
-- ====================================================================
CREATE OR REPLACE FUNCTION public.is_device_registered(p_device_id TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.device_bindings WHERE device_id = p_device_id
    );
$$;
GRANT EXECUTE ON FUNCTION public.is_device_registered(TEXT) TO anon, authenticated;

-- ====================================================================
-- SIGNUP TRIGGER: profile + 48h trial + device binding.
-- Still raises on duplicate device_id as a safety net for races.
-- ====================================================================
-- Bulletproof signup handler.
--   * Always creates the profile (with trial state) even if device metadata
--     is missing/empty/junk.
--   * Only rejects the whole signup if a duplicate device_id would violate
--     the unique index — and only when a device_id is actually present.
--   * Never raises on validation issues; coerces bad language values to 'en'.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_device_id     TEXT := NULLIF(TRIM(BOTH FROM COALESCE(NEW.raw_user_meta_data->>'device_id', '')), '');
    v_device_model  TEXT := NEW.raw_user_meta_data->>'device_model';
    v_language      TEXT := COALESCE(NULLIF(NEW.raw_user_meta_data->>'preferred_language', ''), 'en');
    v_existing_user UUID;
BEGIN
    -- Coerce any unsupported language to 'en' so we never violate the CHECK
    IF v_language NOT IN ('en', 'ar') THEN
        v_language := 'en';
    END IF;

    -- ALWAYS create the profile with a fresh 48h trial.
    INSERT INTO public.profiles (
        id, email, full_name, phone_number,
        is_active, subscription_status,
        trial_started_at, subscription_expires_at,
        preferred_language, role
    )
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'phone_number',
        true,
        'trial',
        NOW(),
        NOW() + INTERVAL '48 hours',
        v_language,
        'driver'
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name               = EXCLUDED.full_name,
        phone_number            = EXCLUDED.phone_number,
        subscription_status     = 'trial',
        is_active               = true,
        trial_started_at        = NOW(),
        subscription_expires_at = NOW() + INTERVAL '48 hours',
        preferred_language      = EXCLUDED.preferred_language;

    -- Device binding is optional. If no device_id, we're done.
    IF v_device_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Reject only if the same device_id is already tied to a DIFFERENT user.
    SELECT user_id INTO v_existing_user
    FROM public.device_bindings
    WHERE device_id = v_device_id AND user_id <> NEW.id
    LIMIT 1;

    IF v_existing_user IS NOT NULL THEN
        RAISE EXCEPTION 'DEVICE_ALREADY_REGISTERED'
            USING ERRCODE = 'unique_violation';
    END IF;

    INSERT INTO public.device_bindings (user_id, device_id, device_model, is_trial_device)
    VALUES (NEW.id, v_device_id, v_device_model, true)
    ON CONFLICT (user_id) DO UPDATE SET
        device_id       = EXCLUDED.device_id,
        device_model    = EXCLUDED.device_model,
        is_trial_device = true;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ====================================================================
-- ADMIN RPCs
-- ====================================================================
-- Activating (or extending to a fresh 30d, if already expired) fully
-- synchronizes ALL subscription-related fields across every table.
CREATE OR REPLACE FUNCTION public.activate_subscription_one_month(target_user_id UUID)
RETURNS TIMESTAMPTZ
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_expiry TIMESTAMPTZ := NOW() + INTERVAL '30 days';
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED';
    END IF;

    -- profiles: subscription state
    UPDATE public.profiles
    SET subscription_status     = 'active',
        is_active               = true,
        subscription_expires_at = new_expiry,
        trial_started_at        = NULL   -- clear the trial marker
    WHERE id = target_user_id;

    -- device_bindings: paid device, no longer a trial-owned binding
    UPDATE public.device_bindings
    SET is_trial_device = false
    WHERE user_id = target_user_id;

    RETURN new_expiry;
END;
$$;
GRANT EXECUTE ON FUNCTION public.activate_subscription_one_month(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.extend_subscription(
    target_user_id UUID,
    extend_days INT DEFAULT 30
)
RETURNS TIMESTAMPTZ
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    current_expiry TIMESTAMPTZ;
    new_expiry     TIMESTAMPTZ;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED';
    END IF;

    SELECT subscription_expires_at INTO current_expiry
    FROM public.profiles WHERE id = target_user_id;

    IF current_expiry IS NULL OR current_expiry < NOW() THEN
        new_expiry := NOW() + (extend_days || ' days')::INTERVAL;
    ELSE
        new_expiry := current_expiry + (extend_days || ' days')::INTERVAL;
    END IF;

    UPDATE public.profiles
    SET subscription_status     = 'active',
        is_active               = true,
        subscription_expires_at = new_expiry,
        trial_started_at        = NULL
    WHERE id = target_user_id;

    UPDATE public.device_bindings
    SET is_trial_device = false
    WHERE user_id = target_user_id;

    RETURN new_expiry;
END;
$$;
GRANT EXECUTE ON FUNCTION public.extend_subscription(UUID, INT) TO authenticated;

CREATE OR REPLACE FUNCTION public.deactivate_subscription(target_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED';
    END IF;

    UPDATE public.profiles
    SET subscription_status = 'inactive',
        is_active           = false
    WHERE id = target_user_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.deactivate_subscription(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.reset_user_device_binding(target_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED';
    END IF;

    DELETE FROM public.device_bindings
    WHERE user_id = target_user_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.reset_user_device_binding(UUID) TO authenticated;

-- Back-compat wrapper
CREATE OR REPLACE FUNCTION public.toggle_user_active_status(
    target_user_id UUID,
    status BOOLEAN,
    expiry_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF status THEN
        PERFORM public.activate_subscription_one_month(target_user_id);
    ELSE
        PERFORM public.deactivate_subscription(target_user_id);
    END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION public.toggle_user_active_status(UUID, BOOLEAN, TIMESTAMPTZ) TO authenticated;

-- Sweeper: flip anything past its expiry to 'expired'. Run via cron.
CREATE OR REPLACE FUNCTION public.expire_stale_subscriptions()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE affected INT;
BEGIN
    UPDATE public.profiles
    SET subscription_status = 'expired',
        is_active           = false
    WHERE subscription_expires_at IS NOT NULL
      AND subscription_expires_at < NOW()
      AND subscription_status IN ('trial', 'active');

    GET DIAGNOSTICS affected = ROW_COUNT;
    RETURN affected;
END;
$$;
GRANT EXECUTE ON FUNCTION public.expire_stale_subscriptions() TO authenticated;

-- --------------------------------------------------------------------
-- BOOTSTRAP HELPERS (run manually — not exposed via RLS/RPC to app)
-- --------------------------------------------------------------------
-- Promote a user to admin. Only callable if there are NO existing admins,
-- OR by an existing admin. Safe to expose to authenticated first-time users
-- who need to bootstrap themselves as the sole admin.
CREATE OR REPLACE FUNCTION public.promote_self_to_admin_bootstrap()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE existing_admin_count INT;
BEGIN
    SELECT COUNT(*) INTO existing_admin_count
    FROM public.profiles WHERE role = 'admin';

    IF existing_admin_count > 0 AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'ADMIN_ALREADY_EXISTS';
    END IF;

    UPDATE public.profiles SET role = 'admin' WHERE id = auth.uid();
    RETURN TRUE;
END;
$$;
GRANT EXECUTE ON FUNCTION public.promote_self_to_admin_bootstrap() TO authenticated;

-- ====================================================================
-- One-time backfill for rows that existed before the migration
-- ====================================================================
UPDATE public.profiles
SET subscription_status = CASE
        WHEN is_active AND (subscription_expires_at IS NULL OR subscription_expires_at > NOW()) THEN 'active'
        WHEN subscription_expires_at IS NOT NULL AND subscription_expires_at < NOW() THEN 'expired'
        ELSE 'inactive'
    END
WHERE (subscription_status IS NULL)
   OR (subscription_status = 'trial' AND trial_started_at IS NULL);

-- --------------------------------------------------------------------
-- Optional: enable pg_cron (Database -> Extensions) then:
--   SELECT cron.schedule(
--       'keemo_expire_subs',
--       '*/15 * * * *',
--       $$SELECT public.expire_stale_subscriptions();$$
--   );
-- --------------------------------------------------------------------
