-- CoreJourney — Trainer application review flow
-- Application-first trainer onboarding with admin review channel and
-- sight-only background-check documentation. No document files are stored.

CREATE EXTENSION IF NOT EXISTS postgis;

-- ── 1. Trainer applications ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.trainer_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

  full_name text NOT NULL,
  email text NOT NULL,
  phone text,
  city text,
  professional_background text NOT NULL,
  motivation text,

  desired_display_name text,
  desired_bio text,
  desired_location_private geography(POINT, 4326),
  desired_location_public geography(POINT, 4326),
  desired_location_precision_m int NOT NULL DEFAULT 1000,

  status text NOT NULL DEFAULT 'submitted'
    CHECK (status IN (
      'submitted',
      'in_review',
      'needs_more_info',
      'approved',
      'rejected',
      'withdrawn'
    )),

  background_check_required boolean NOT NULL DEFAULT true,
  background_check_verified_at timestamptz,
  background_check_verified_by uuid REFERENCES public.profiles(id),

  assigned_reviewer uuid REFERENCES public.profiles(id),
  reviewed_by uuid REFERENCES public.profiles(id),
  reviewed_at timestamptz,
  rejection_reason text,
  admin_notes text,

  activation_code_id uuid,
  review_channel_id uuid,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_trainer_applications_open_per_user
  ON public.trainer_applications(user_id)
  WHERE status IN ('submitted', 'in_review', 'needs_more_info');

CREATE INDEX IF NOT EXISTS idx_trainer_applications_status_created
  ON public.trainer_applications(status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_trainer_applications_user
  ON public.trainer_applications(user_id);

-- ── 2. Audit events ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.trainer_application_audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES public.trainer_applications(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES public.profiles(id),
  event_type text NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_trainer_application_audit_application_created
  ON public.trainer_application_audit_events(application_id, created_at DESC);

-- ── 3. Activation-code linkage ──────────────────────────────────────────────

ALTER TABLE public.trainer_invite_codes
  ADD COLUMN IF NOT EXISTS trainer_application_id uuid REFERENCES public.trainer_applications(id),
  ADD COLUMN IF NOT EXISTS purpose text NOT NULL DEFAULT 'legacy_manual';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.trainer_invite_codes'::regclass
      AND conname = 'trainer_invite_codes_purpose_check'
  ) THEN
    ALTER TABLE public.trainer_invite_codes
      ADD CONSTRAINT trainer_invite_codes_purpose_check
      CHECK (purpose IN ('legacy_manual', 'trainer_application_approval'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_trainer_invite_codes_application
  ON public.trainer_invite_codes(trainer_application_id);

-- ── 4. Review channels ──────────────────────────────────────────────────────

ALTER TABLE public.chat_channels
  ADD COLUMN IF NOT EXISTS application_id uuid REFERENCES public.trainer_applications(id) ON DELETE CASCADE;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.chat_channels'::regclass
      AND conname = 'chat_channels_type_check'
  ) THEN
    ALTER TABLE public.chat_channels DROP CONSTRAINT chat_channels_type_check;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.chat_channels'::regclass
      AND conname = 'chk_channel_package_id'
  ) THEN
    ALTER TABLE public.chat_channels DROP CONSTRAINT chk_channel_package_id;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.chat_channels'::regclass
      AND conname = 'chat_channels_type_check'
  ) THEN
    ALTER TABLE public.chat_channels
      ADD CONSTRAINT chat_channels_type_check
      CHECK (type IN ('direct', 'community', 'application_review'));
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.chat_channels'::regclass
      AND conname = 'chk_channel_context'
  ) THEN
    ALTER TABLE public.chat_channels
      ADD CONSTRAINT chk_channel_context
      CHECK (
        (type = 'community' AND package_id IS NOT NULL AND application_id IS NULL) OR
        (type = 'direct' AND package_id IS NULL AND application_id IS NULL) OR
        (type = 'application_review' AND package_id IS NULL AND application_id IS NOT NULL)
      );
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_channels_application_review
  ON public.chat_channels(application_id)
  WHERE type = 'application_review';

ALTER TABLE public.trainer_applications
  DROP CONSTRAINT IF EXISTS trainer_applications_review_channel_fk;

ALTER TABLE public.trainer_applications
  ADD CONSTRAINT trainer_applications_review_channel_fk
  FOREIGN KEY (review_channel_id)
  REFERENCES public.chat_channels(id)
  ON DELETE SET NULL;

-- ── 5. RLS ──────────────────────────────────────────────────────────────────

ALTER TABLE public.trainer_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainer_application_audit_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS trainer_applications_select_own_or_admin ON public.trainer_applications;
CREATE POLICY trainer_applications_select_own_or_admin
  ON public.trainer_applications FOR SELECT
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS trainer_applications_insert_own ON public.trainer_applications;
CREATE POLICY trainer_applications_insert_own
  ON public.trainer_applications FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS trainer_applications_update_own_withdraw ON public.trainer_applications;
CREATE POLICY trainer_applications_update_own_withdraw
  ON public.trainer_applications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid() AND status = 'withdrawn');

DROP POLICY IF EXISTS trainer_applications_admin_all ON public.trainer_applications;
CREATE POLICY trainer_applications_admin_all
  ON public.trainer_applications FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS trainer_application_audit_select_own_or_admin
  ON public.trainer_application_audit_events;
CREATE POLICY trainer_application_audit_select_own_or_admin
  ON public.trainer_application_audit_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.trainer_applications ta
      WHERE ta.id = trainer_application_audit_events.application_id
        AND ta.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Writes happen through SECURITY DEFINER RPCs.
DROP POLICY IF EXISTS trainer_application_audit_insert_deny
  ON public.trainer_application_audit_events;
CREATE POLICY trainer_application_audit_insert_deny
  ON public.trainer_application_audit_events FOR INSERT
  WITH CHECK (false);

-- ── 6. Helpers ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public._is_admin(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = p_user_id AND role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public._trainer_application_audit(
  p_application_id uuid,
  p_actor_id uuid,
  p_event_type text,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  INSERT INTO public.trainer_application_audit_events (
    application_id,
    actor_id,
    event_type,
    metadata
  )
  VALUES (
    p_application_id,
    p_actor_id,
    p_event_type,
    COALESCE(p_metadata, '{}'::jsonb)
  );
$$;

CREATE OR REPLACE FUNCTION public._trainer_activation_code()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chars text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_code text := '';
  i int;
BEGIN
  FOR i IN 1..8 LOOP
    v_code := v_code || substr(v_chars, 1 + floor(random() * length(v_chars))::int, 1);
  END LOOP;
  RETURN v_code;
END;
$$;

REVOKE ALL ON FUNCTION public._is_admin(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public._trainer_application_audit(uuid, uuid, text, jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public._trainer_activation_code() FROM PUBLIC;

-- ── 7. Applicant RPCs ───────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.submit_trainer_application(
  p_full_name text,
  p_email text,
  p_phone text DEFAULT NULL,
  p_city text DEFAULT NULL,
  p_professional_background text DEFAULT NULL,
  p_motivation text DEFAULT NULL,
  p_desired_display_name text DEFAULT NULL,
  p_desired_bio text DEFAULT NULL,
  p_lat float8 DEFAULT NULL,
  p_lng float8 DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_application_id uuid;
  v_channel_id uuid;
  v_location_private geography;
  v_location_public geography;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  IF trim(COALESCE(p_full_name, '')) = '' THEN
    RAISE EXCEPTION 'Vollständiger Name fehlt';
  END IF;

  IF trim(COALESCE(p_email, '')) = '' OR position('@' in p_email) = 0 THEN
    RAISE EXCEPTION 'Gültige E-Mail fehlt';
  END IF;

  IF trim(COALESCE(p_professional_background, '')) = '' THEN
    RAISE EXCEPTION 'Beruflicher Hintergrund fehlt';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.trainer_applications
    WHERE user_id = v_user_id
      AND status IN ('submitted', 'in_review', 'needs_more_info')
  ) THEN
    RAISE EXCEPTION 'Es gibt bereits eine offene Trainer-Bewerbung';
  END IF;

  IF p_lat IS NOT NULL OR p_lng IS NOT NULL THEN
    IF p_lat IS NULL OR p_lng IS NULL OR p_lat NOT BETWEEN -90 AND 90 OR p_lng NOT BETWEEN -180 AND 180 THEN
      RAISE EXCEPTION 'Ungültige Koordinaten';
    END IF;
    v_location_private := ST_MakePoint(p_lng, p_lat)::geography;
    IF EXISTS (
      SELECT 1 FROM pg_proc
      WHERE proname = '_jitter_location'
    ) THEN
      v_location_public := public._jitter_location(v_location_private, 1000);
    ELSE
      v_location_public := v_location_private;
    END IF;
  END IF;

  INSERT INTO public.trainer_applications (
    user_id,
    full_name,
    email,
    phone,
    city,
    professional_background,
    motivation,
    desired_display_name,
    desired_bio,
    desired_location_private,
    desired_location_public
  )
  VALUES (
    v_user_id,
    trim(p_full_name),
    trim(p_email),
    NULLIF(trim(COALESCE(p_phone, '')), ''),
    NULLIF(trim(COALESCE(p_city, '')), ''),
    trim(p_professional_background),
    NULLIF(trim(COALESCE(p_motivation, '')), ''),
    NULLIF(trim(COALESCE(p_desired_display_name, '')), ''),
    NULLIF(trim(COALESCE(p_desired_bio, '')), ''),
    v_location_private,
    v_location_public
  )
  RETURNING id INTO v_application_id;

  INSERT INTO public.chat_channels (type, application_id)
  VALUES ('application_review', v_application_id)
  RETURNING id INTO v_channel_id;

  INSERT INTO public.chat_channel_members (channel_id, user_id, role)
  VALUES (v_channel_id, v_user_id, 'member')
  ON CONFLICT DO NOTHING;

  INSERT INTO public.chat_channel_members (channel_id, user_id, role)
  SELECT v_channel_id, p.id, 'moderator'
  FROM public.profiles p
  WHERE p.role = 'admin'
  ON CONFLICT DO NOTHING;

  UPDATE public.trainer_applications
  SET review_channel_id = v_channel_id,
      updated_at = now()
  WHERE id = v_application_id;

  PERFORM public._trainer_application_audit(
    v_application_id,
    v_user_id,
    'application_submitted',
    jsonb_build_object('review_channel_id', v_channel_id)
  );

  RETURN v_application_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_own_trainer_application()
RETURNS TABLE (
  id uuid,
  user_id uuid,
  full_name text,
  email text,
  phone text,
  city text,
  professional_background text,
  motivation text,
  desired_display_name text,
  desired_bio text,
  status text,
  background_check_required boolean,
  background_check_verified_at timestamptz,
  background_check_verified_by uuid,
  reviewed_by uuid,
  reviewed_at timestamptz,
  rejection_reason text,
  admin_notes text,
  activation_code_id uuid,
  activation_code text,
  activation_code_expires_at timestamptz,
  review_channel_id uuid,
  created_at timestamptz,
  updated_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    ta.id,
    ta.user_id,
    ta.full_name,
    ta.email,
    ta.phone,
    ta.city,
    ta.professional_background,
    ta.motivation,
    ta.desired_display_name,
    ta.desired_bio,
    ta.status,
    ta.background_check_required,
    ta.background_check_verified_at,
    ta.background_check_verified_by,
    ta.reviewed_by,
    ta.reviewed_at,
    ta.rejection_reason,
    NULL::text AS admin_notes,
    ta.activation_code_id,
    CASE
      WHEN ta.status = 'approved' AND tic.used_at IS NULL THEN tic.code
      ELSE NULL
    END AS activation_code,
    tic.expires_at AS activation_code_expires_at,
    ta.review_channel_id,
    ta.created_at,
    ta.updated_at
  FROM public.trainer_applications ta
  LEFT JOIN public.trainer_invite_codes tic ON tic.id = ta.activation_code_id
  WHERE ta.user_id = auth.uid()
  ORDER BY ta.created_at DESC
  LIMIT 1;
$$;

-- ── 8. Admin RPCs ───────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_trainer_applications_for_review()
RETURNS TABLE (
  id uuid,
  user_id uuid,
  full_name text,
  email text,
  phone text,
  city text,
  professional_background text,
  motivation text,
  desired_display_name text,
  desired_bio text,
  status text,
  background_check_required boolean,
  background_check_verified_at timestamptz,
  background_check_verified_by uuid,
  reviewed_by uuid,
  reviewed_at timestamptz,
  rejection_reason text,
  admin_notes text,
  activation_code_id uuid,
  activation_code text,
  activation_code_expires_at timestamptz,
  review_channel_id uuid,
  created_at timestamptz,
  updated_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    ta.id,
    ta.user_id,
    ta.full_name,
    ta.email,
    ta.phone,
    ta.city,
    ta.professional_background,
    ta.motivation,
    ta.desired_display_name,
    ta.desired_bio,
    ta.status,
    ta.background_check_required,
    ta.background_check_verified_at,
    ta.background_check_verified_by,
    ta.reviewed_by,
    ta.reviewed_at,
    ta.rejection_reason,
    ta.admin_notes,
    ta.activation_code_id,
    tic.code AS activation_code,
    tic.expires_at AS activation_code_expires_at,
    ta.review_channel_id,
    ta.created_at,
    ta.updated_at
  FROM public.trainer_applications ta
  LEFT JOIN public.trainer_invite_codes tic ON tic.id = ta.activation_code_id
  WHERE public._is_admin(auth.uid())
  ORDER BY
    CASE ta.status
      WHEN 'submitted' THEN 0
      WHEN 'in_review' THEN 1
      WHEN 'needs_more_info' THEN 2
      WHEN 'approved' THEN 3
      ELSE 4
    END,
    ta.created_at DESC;
$$;

CREATE OR REPLACE FUNCTION public.mark_background_check_seen(
  p_application_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id uuid := auth.uid();
BEGIN
  IF NOT public._is_admin(v_admin_id) THEN
    RAISE EXCEPTION 'Nur Admins können die Sichtprüfung markieren';
  END IF;

  UPDATE public.trainer_applications
  SET background_check_verified_at = now(),
      background_check_verified_by = v_admin_id,
      status = CASE WHEN status = 'submitted' THEN 'in_review' ELSE status END,
      updated_at = now()
  WHERE id = p_application_id
    AND status IN ('submitted', 'in_review', 'needs_more_info');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Bewerbung nicht gefunden oder nicht prüfbar';
  END IF;

  PERFORM public._trainer_application_audit(
    p_application_id,
    v_admin_id,
    'background_check_marked_seen'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.set_trainer_application_status(
  p_application_id uuid,
  p_status text,
  p_reason text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id uuid := auth.uid();
BEGIN
  IF NOT public._is_admin(v_admin_id) THEN
    RAISE EXCEPTION 'Nur Admins können Bewerbungen bearbeiten';
  END IF;

  IF p_status NOT IN ('in_review', 'needs_more_info', 'rejected') THEN
    RAISE EXCEPTION 'Ungültiger Statuswechsel';
  END IF;

  UPDATE public.trainer_applications
  SET status = p_status,
      rejection_reason = CASE WHEN p_status = 'rejected' THEN NULLIF(trim(COALESCE(p_reason, '')), '') ELSE rejection_reason END,
      reviewed_by = CASE WHEN p_status = 'rejected' THEN v_admin_id ELSE reviewed_by END,
      reviewed_at = CASE WHEN p_status = 'rejected' THEN now() ELSE reviewed_at END,
      updated_at = now()
  WHERE id = p_application_id
    AND status IN ('submitted', 'in_review', 'needs_more_info');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Bewerbung nicht gefunden oder nicht prüfbar';
  END IF;

  PERFORM public._trainer_application_audit(
    p_application_id,
    v_admin_id,
    'status_changed',
    jsonb_build_object('status', p_status, 'reason', p_reason)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.approve_trainer_application(
  p_application_id uuid
)
RETURNS TABLE (
  code text,
  expires_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id uuid := auth.uid();
  v_application public.trainer_applications%ROWTYPE;
  v_code text;
  v_code_id uuid;
  v_expires_at timestamptz := now() + interval '14 days';
BEGIN
  IF NOT public._is_admin(v_admin_id) THEN
    RAISE EXCEPTION 'Nur Admins können Bewerbungen freigeben';
  END IF;

  SELECT * INTO v_application
  FROM public.trainer_applications
  WHERE id = p_application_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Bewerbung nicht gefunden';
  END IF;

  IF v_application.status NOT IN ('submitted', 'in_review', 'needs_more_info') THEN
    RAISE EXCEPTION 'Bewerbung ist nicht freigabefähig';
  END IF;

  IF v_application.background_check_required
     AND v_application.background_check_verified_at IS NULL THEN
    RAISE EXCEPTION 'Führungszeugnis-Sichtprüfung fehlt';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = v_application.user_id AND role = 'trainer'
  ) THEN
    RAISE EXCEPTION 'Nutzer ist bereits Trainer';
  END IF;

  LOOP
    v_code := public._trainer_activation_code();
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM public.trainer_invite_codes tic WHERE tic.code = v_code
    );
  END LOOP;

  INSERT INTO public.trainer_invite_codes (
    code,
    created_by,
    expires_at,
    trainer_application_id,
    purpose
  )
  VALUES (
    v_code,
    v_admin_id,
    v_expires_at,
    p_application_id,
    'trainer_application_approval'
  )
  RETURNING id INTO v_code_id;

  UPDATE public.trainer_applications
  SET status = 'approved',
      reviewed_by = v_admin_id,
      reviewed_at = now(),
      activation_code_id = v_code_id,
      updated_at = now()
  WHERE id = p_application_id;

  PERFORM public._trainer_application_audit(
    p_application_id,
    v_admin_id,
    'activation_code_created',
    jsonb_build_object('code_id', v_code_id, 'expires_at', v_expires_at)
  );

  RETURN QUERY SELECT v_code, v_expires_at;
END;
$$;

-- Called by the activate-trainer Edge Function with the service-role client.
CREATE OR REPLACE FUNCTION public.finalize_trainer_application_activation(
  p_code text,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code public.trainer_invite_codes%ROWTYPE;
  v_application public.trainer_applications%ROWTYPE;
  v_display_name text;
BEGIN
  SELECT * INTO v_code
  FROM public.trainer_invite_codes
  WHERE trainer_invite_codes.code = upper(trim(p_code))
    AND trainer_invite_codes.purpose = 'trainer_application_approval'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ungültiger Aktivierungscode';
  END IF;

  IF v_code.used_by IS NOT NULL THEN
    RAISE EXCEPTION 'Dieser Code wurde bereits verwendet';
  END IF;

  IF v_code.expires_at < now() THEN
    RAISE EXCEPTION 'Dieser Code ist abgelaufen';
  END IF;

  SELECT * INTO v_application
  FROM public.trainer_applications
  WHERE id = v_code.trainer_application_id
  FOR UPDATE;

  IF NOT FOUND OR v_application.status != 'approved' THEN
    RAISE EXCEPTION 'Bewerbung ist nicht freigegeben';
  END IF;

  IF v_application.user_id != p_user_id THEN
    RAISE EXCEPTION 'Code gehört nicht zu diesem Nutzer';
  END IF;

  v_display_name := COALESCE(
    NULLIF(trim(v_application.desired_display_name), ''),
    NULLIF(trim(v_application.full_name), ''),
    'Trainer'
  );

  UPDATE public.profiles
  SET role = 'trainer',
      display_name = COALESCE(NULLIF(display_name, ''), v_display_name)
  WHERE id = p_user_id;

  INSERT INTO public.trainer_profiles (
    id,
    display_name,
    bio,
    location_private,
    location_public,
    location_precision_m,
    location_updated_at,
    status,
    approved_at,
    approved_by,
    submitted_at
  )
  VALUES (
    p_user_id,
    v_display_name,
    NULLIF(trim(COALESCE(v_application.desired_bio, '')), ''),
    v_application.desired_location_private,
    v_application.desired_location_public,
    v_application.desired_location_precision_m,
    CASE WHEN v_application.desired_location_private IS NULL THEN NULL ELSE now() END,
    'active',
    now(),
    v_application.reviewed_by,
    v_application.created_at
  )
  ON CONFLICT (id) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    bio = EXCLUDED.bio,
    location_private = COALESCE(EXCLUDED.location_private, trainer_profiles.location_private),
    location_public = COALESCE(EXCLUDED.location_public, trainer_profiles.location_public),
    location_precision_m = EXCLUDED.location_precision_m,
    location_updated_at = COALESCE(EXCLUDED.location_updated_at, trainer_profiles.location_updated_at),
    status = 'active',
    approved_at = now(),
    approved_by = EXCLUDED.approved_by,
    updated_at = now();

  INSERT INTO public.trainer_profile_private (
    trainer_id,
    contact_email,
    contact_phone
  )
  VALUES (
    p_user_id,
    v_application.email,
    v_application.phone
  )
  ON CONFLICT (trainer_id) DO UPDATE SET
    contact_email = EXCLUDED.contact_email,
    contact_phone = EXCLUDED.contact_phone,
    updated_at = now();

  UPDATE public.trainer_invite_codes
  SET used_by = p_user_id,
      used_at = now()
  WHERE id = v_code.id;

  PERFORM public._trainer_application_audit(
    v_application.id,
    p_user_id,
    'activation_code_used',
    jsonb_build_object('code_id', v_code.id)
  );
END;
$$;

-- ── 9. Channel list compatibility ───────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_channel_list(p_user_id uuid)
RETURNS TABLE (
  id                    uuid,
  type                  text,
  package_id            text,
  created_at            timestamptz,
  member_role           text,
  last_read_at          timestamptz,
  last_message_content  text,
  last_message_at       timestamptz,
  unread_count          bigint
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH memberships AS (
    SELECT
      ccm.channel_id,
      ccm.role          AS member_role,
      ccm.last_read_at
    FROM public.chat_channel_members ccm
    WHERE ccm.user_id = p_user_id
  ),
  last_msgs AS (
    SELECT DISTINCT ON (cm.channel_id)
      cm.channel_id,
      cm.content      AS last_message_content,
      cm.created_at   AS last_message_at
    FROM public.chat_messages cm
    JOIN memberships m ON m.channel_id = cm.channel_id
    WHERE cm.deleted_at IS NULL
    ORDER BY cm.channel_id, cm.created_at DESC
  ),
  unread AS (
    SELECT
      cm.channel_id,
      COUNT(*)::bigint AS unread_count
    FROM public.chat_messages cm
    JOIN memberships m ON m.channel_id = cm.channel_id
    WHERE cm.created_at > m.last_read_at
      AND cm.sender_id  != p_user_id
      AND cm.deleted_at IS NULL
    GROUP BY cm.channel_id
  )
  SELECT
    c.id,
    c.type,
    c.package_id,
    c.created_at,
    m.member_role,
    m.last_read_at,
    lm.last_message_content,
    lm.last_message_at,
    COALESCE(u.unread_count, 0) AS unread_count
  FROM public.chat_channels c
  JOIN memberships m    ON m.channel_id = c.id
  LEFT JOIN last_msgs lm ON lm.channel_id = c.id
  LEFT JOIN unread u    ON u.channel_id  = c.id
  ORDER BY
    CASE c.type
      WHEN 'direct' THEN 0
      WHEN 'application_review' THEN 1
      ELSE 2
    END,
    lm.last_message_at DESC NULLS LAST,
    c.created_at DESC;
$$;

-- ── 10. Grants ──────────────────────────────────────────────────────────────

GRANT EXECUTE ON FUNCTION public.submit_trainer_application(text, text, text, text, text, text, text, text, float8, float8) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_own_trainer_application() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_trainer_applications_for_review() TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_background_check_seen(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_trainer_application_status(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.approve_trainer_application(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.finalize_trainer_application_activation(text, uuid) TO service_role;
