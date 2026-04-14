-- supabase/migrations/20260415_subscription_tier.sql
-- Adds subscription_tier to profiles, protects it from direct client writes,
-- and grants admin users read access to all profiles.

-- 1. Add column
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS subscription_tier TEXT NOT NULL DEFAULT 'free'
  CONSTRAINT profiles_subscription_tier_check CHECK (subscription_tier IN ('free', 'premium'));

-- 2. Trigger to prevent authenticated users from changing subscription_tier directly
--    (mirrors the existing prevent_direct_role_change pattern)
CREATE OR REPLACE FUNCTION public.prevent_direct_tier_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.role() != 'service_role' AND OLD.subscription_tier IS DISTINCT FROM NEW.subscription_tier THEN
    RAISE EXCEPTION
      'Changing subscription_tier directly is not permitted. '
      'Use the set-subscription-tier Edge Function.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_direct_tier_change ON public.profiles;
CREATE TRIGGER trg_prevent_direct_tier_change
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_direct_tier_change();

-- 3. Allow admin users to read all profiles
--    (needed for admin panel user list; existing policy only allows reading own row)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'profiles' AND policyname = 'profiles_admin_read_all'
  ) THEN
    CREATE POLICY profiles_admin_read_all ON public.profiles
      FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid() AND p.role = 'admin'
        )
      );
  END IF;
END $$;
