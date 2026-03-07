-- PEAK MAP - Supabase RLS Remediation
-- Run this in Supabase SQL Editor to resolve linter errors:
-- 0007 policy_exists_rls_disabled
-- 0013 rls_disabled_in_public
-- 0023 sensitive_columns_exposed (for no-RLS cases)

BEGIN;

-- 1) Enable RLS on all flagged public tables
ALTER TABLE IF EXISTS public.admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.bus_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fares ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.gps_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.rfid_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.rfid_entry_exit_logs ENABLE ROW LEVEL SECURITY;

COMMIT;

-- 2) Ensure a service-role full-access policy exists for every table above.
--    Idempotent: policy is created only when missing.
DO $$
DECLARE
  t text;
  p text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'admins',
    'bus_updates',
    'buses',
    'drivers',
    'passengers',
    'users',
    'rides',
    'stations',
    'fares',
    'gps_logs',
    'payments',
    'rfid_cards',
    'rfid_entry_exit_logs'
  ] LOOP
    IF to_regclass(format('public.%I', t)) IS NOT NULL THEN
      p := format('Service role has full access to %s', t);

      IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = t
          AND policyname = p
      ) THEN
        EXECUTE format(
          'CREATE POLICY %I ON public.%I FOR ALL TO service_role USING (true) WITH CHECK (true);',
          p,
          t
        );
      END IF;
    END IF;
  END LOOP;
END
$$;

-- 2b) Normalize existing policy role bindings.
-- If policy names indicate service-role-only access, enforce TO service_role.
DO $$
DECLARE
  rec record;
BEGIN
  FOR rec IN
    SELECT tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND (
        policyname LIKE 'Only service role can %'
        OR policyname LIKE 'Service role has full access to %'
      )
  LOOP
    EXECUTE format(
      'ALTER POLICY %I ON public.%I TO service_role;',
      rec.policyname,
      rec.tablename
    );
  END LOOP;
END
$$;

-- 3) Keep commonly public lookup tables readable for clients.
DO $$
BEGIN
  IF to_regclass('public.stations') IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'stations'
        AND policyname = 'Anyone can view stations'
    ) THEN
    CREATE POLICY "Anyone can view stations"
      ON public.stations
      FOR SELECT
      TO anon, authenticated
      USING (true);
  END IF;

  IF to_regclass('public.fares') IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'fares'
        AND policyname = 'Anyone can view fares'
    ) THEN
    CREATE POLICY "Anyone can view fares"
      ON public.fares
      FOR SELECT
      TO anon, authenticated
      USING (true);
  END IF;
END
$$;

-- 4) Reduce exposure of sensitive columns to client roles.
DO $$
BEGIN
  IF to_regclass('public.admins') IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'admins'
        AND column_name = 'password'
    ) THEN
    REVOKE SELECT (password) ON public.admins FROM anon, authenticated;
  END IF;

  IF to_regclass('public.drivers') IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'drivers'
        AND column_name = 'password'
    ) THEN
    REVOKE SELECT (password) ON public.drivers FROM anon, authenticated;
  END IF;

  IF to_regclass('public.drivers') IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'drivers'
        AND column_name = 'license_number'
    ) THEN
    REVOKE SELECT (license_number) ON public.drivers FROM anon, authenticated;
  END IF;

  IF to_regclass('public.passengers') IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'passengers'
        AND column_name = 'password'
    ) THEN
    REVOKE SELECT (password) ON public.passengers FROM anon, authenticated;
  END IF;
END
$$;

-- 5) Verification queries
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'admins',
    'bus_updates',
    'buses',
    'drivers',
    'passengers',
    'users',
    'rides',
    'stations',
    'fares',
    'gps_logs',
    'payments',
    'rfid_cards',
    'rfid_entry_exit_logs'
  )
ORDER BY tablename;

SELECT tablename, policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'admins',
    'bus_updates',
    'buses',
    'drivers',
    'passengers',
    'users',
    'rides',
    'stations',
    'fares',
    'gps_logs',
    'payments',
    'rfid_cards',
    'rfid_entry_exit_logs'
  )
ORDER BY tablename, policyname;
