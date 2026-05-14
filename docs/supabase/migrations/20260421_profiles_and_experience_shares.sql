-- ── profiles (already exists — add new columns only) ─────────────────────────
-- The profiles table was created in 20260413_chat_foundation.sql with id as PK.
-- display_name already exists there. We only need to add is_anonymous_default.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_anonymous_default BOOLEAN NOT NULL DEFAULT false;

-- ── experience_shares ────────────────────────────────────────────────────────
-- One row per journal entry that a user chose to share with their package community.
-- Scoped by package_id; no channel_id needed since posts come from training sessions
-- (which have no channel context) and are displayed per-package in the feed.

CREATE TABLE IF NOT EXISTS public.experience_shares (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  package_id      TEXT NOT NULL,
  mood_checkin_id UUID REFERENCES public.mood_checkins(id) ON DELETE SET NULL,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name    TEXT NOT NULL,   -- snapshot: 'Anonym' if anonymous at time of share
  is_anonymous    BOOLEAN NOT NULL DEFAULT false,
  content         TEXT,            -- null if user only submitted mood values
  mood            SMALLINT CHECK (mood IS NULL OR (mood BETWEEN 1 AND 5)),
  energy          SMALLINT CHECK (energy IS NULL OR (energy BETWEEN 1 AND 5)),
  stress          SMALLINT CHECK (stress IS NULL OR (stress BETWEEN 1 AND 5)),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.experience_shares ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can read all shares (package membership enforced in app).
CREATE POLICY "shares_read"   ON public.experience_shares FOR SELECT USING (auth.uid() IS NOT NULL);
-- Users can only insert their own shares.
CREATE POLICY "shares_insert" ON public.experience_shares FOR INSERT WITH CHECK (auth.uid() = user_id);
-- Users can delete their own shares.
CREATE POLICY "shares_delete_own" ON public.experience_shares FOR DELETE USING (auth.uid() = user_id);

-- Moderator delete: SECURITY DEFINER function that bypasses RLS.
-- Checks moderator role via package_id → community chat channel → chat_channel_members.
CREATE OR REPLACE FUNCTION public.moderator_delete_experience_share(share_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_package_id TEXT;
  v_share_owner UUID;
BEGIN
  SELECT package_id, user_id INTO v_package_id, v_share_owner
    FROM public.experience_shares WHERE id = share_id;

  IF v_share_owner IS NULL THEN
    RETURN; -- share not found
  END IF;

  -- Allow if caller owns the share
  IF v_share_owner = auth.uid() THEN
    DELETE FROM public.experience_shares WHERE id = share_id;
    RETURN;
  END IF;

  -- Allow if caller is moderator of the community channel for this package
  IF EXISTS (
    SELECT 1
    FROM   public.chat_channels cc
    JOIN   public.chat_channel_members ccm ON ccm.channel_id = cc.id
    WHERE  cc.package_id  = v_package_id
      AND  cc.type        = 'community'
      AND  ccm.user_id    = auth.uid()
      AND  ccm.role       = 'moderator'
  ) THEN
    DELETE FROM public.experience_shares WHERE id = share_id;
  END IF;
END;
$$;
