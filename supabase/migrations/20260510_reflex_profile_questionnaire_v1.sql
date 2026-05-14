-- Reflexprofil questionnaire v1 foundation.
-- Supports parent-for-child, future adult self-report, demo separation,
-- trainer sharing consent, warning confirmations, notes and admin analytics.

CREATE TABLE IF NOT EXISTS public.reflex_subject_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  profile_type text NOT NULL CHECK (profile_type IN ('child', 'adult_self')),
  display_name text NOT NULL,
  birth_date date,
  age_years smallint CHECK (age_years BETWEEN 0 AND 120),
  age_months smallint CHECK (age_months BETWEEN 0 AND 1439),
  age_group text CHECK (
    age_group IN ('0-2', '3-4', '5-7', '8-10', '11-13', '14-17', '18+')
  ),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reflex_subject_profiles_owner
  ON public.reflex_subject_profiles(owner_user_id, created_at DESC);

ALTER TABLE public.reflex_subject_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS reflex_subject_profiles_owner_all
  ON public.reflex_subject_profiles;
CREATE POLICY reflex_subject_profiles_owner_all
  ON public.reflex_subject_profiles FOR ALL
  USING (owner_user_id = auth.uid())
  WITH CHECK (owner_user_id = auth.uid());

ALTER TABLE public.reflex_profile_assessments
  ADD COLUMN IF NOT EXISTS subject_profile_id uuid
    REFERENCES public.reflex_subject_profiles(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS questionnaire_type text NOT NULL DEFAULT 'child_parent_report',
  ADD COLUMN IF NOT EXISTS scoring_version text NOT NULL DEFAULT 'score_equal_weight_v1',
  ADD COLUMN IF NOT EXISTS warning_confirmations jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS safety_status text NOT NULL DEFAULT 'clear',
  ADD COLUMN IF NOT EXISTS trainer_sharing_prompted_at timestamptz,
  ADD COLUMN IF NOT EXISTS pdf_summary_path text,
  ADD COLUMN IF NOT EXISTS email_summary_sent_at timestamptz;

ALTER TABLE public.reflex_profile_assessments
  DROP CONSTRAINT IF EXISTS reflex_profile_assessments_status_check;

ALTER TABLE public.reflex_profile_assessments
  ADD CONSTRAINT reflex_profile_assessments_status_check
  CHECK (status IN ('draft', 'skipped', 'completed'));

ALTER TABLE public.reflex_profile_assessments
  DROP CONSTRAINT IF EXISTS reflex_profile_assessments_completion_check;

ALTER TABLE public.reflex_profile_assessments
  ADD CONSTRAINT reflex_profile_assessments_completion_check
  CHECK (
    status = 'draft'
    OR (status = 'skipped' AND skipped_at IS NOT NULL)
    OR (status = 'completed' AND completed_at IS NOT NULL)
  );

ALTER TABLE public.reflex_profile_assessments
  DROP CONSTRAINT IF EXISTS reflex_profile_assessments_questionnaire_type_check;

ALTER TABLE public.reflex_profile_assessments
  ADD CONSTRAINT reflex_profile_assessments_questionnaire_type_check
  CHECK (
    questionnaire_type IN (
      'child_parent_report',
      'adult_self_report',
      'demo_child_short'
    )
  );

ALTER TABLE public.reflex_profile_assessments
  DROP CONSTRAINT IF EXISTS reflex_profile_assessments_safety_status_check;

ALTER TABLE public.reflex_profile_assessments
  ADD CONSTRAINT reflex_profile_assessments_safety_status_check
  CHECK (
    safety_status IN (
      'clear',
      'professional_clearance_confirmed'
    )
  );

CREATE INDEX IF NOT EXISTS idx_reflex_profile_assessments_subject_created
  ON public.reflex_profile_assessments(subject_profile_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_reflex_profile_assessments_type_created
  ON public.reflex_profile_assessments(questionnaire_type, created_at DESC);

DROP POLICY IF EXISTS reflex_profile_assessments_select_own
  ON public.reflex_profile_assessments;
CREATE POLICY reflex_profile_assessments_select_own
  ON public.reflex_profile_assessments FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS reflex_profile_assessments_insert_own
  ON public.reflex_profile_assessments;
CREATE POLICY reflex_profile_assessments_insert_own
  ON public.reflex_profile_assessments FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS reflex_profile_assessments_update_own
  ON public.reflex_profile_assessments;
CREATE POLICY reflex_profile_assessments_update_own
  ON public.reflex_profile_assessments FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE TABLE IF NOT EXISTS public.reflex_profile_trainer_shares (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_profile_id uuid NOT NULL
    REFERENCES public.reflex_subject_profiles(id) ON DELETE CASCADE,
  owner_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  trainer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  relationship_id uuid REFERENCES public.trainer_client_relationships(id)
    ON DELETE SET NULL,
  scope text NOT NULL DEFAULT 'full_profile'
    CHECK (scope IN ('full_profile')),
  granted_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_reflex_profile_trainer_shares_active
  ON public.reflex_profile_trainer_shares(subject_profile_id, trainer_id)
  WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_reflex_profile_trainer_shares_trainer
  ON public.reflex_profile_trainer_shares(trainer_id, revoked_at);

ALTER TABLE public.reflex_profile_trainer_shares ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS reflex_profile_trainer_shares_owner_all
  ON public.reflex_profile_trainer_shares;
CREATE POLICY reflex_profile_trainer_shares_owner_all
  ON public.reflex_profile_trainer_shares FOR ALL
  USING (owner_user_id = auth.uid())
  WITH CHECK (owner_user_id = auth.uid());

DROP POLICY IF EXISTS reflex_profile_trainer_shares_trainer_select
  ON public.reflex_profile_trainer_shares;
CREATE POLICY reflex_profile_trainer_shares_trainer_select
  ON public.reflex_profile_trainer_shares FOR SELECT
  USING (trainer_id = auth.uid() AND revoked_at IS NULL);

DROP POLICY IF EXISTS reflex_subject_profiles_trainer_select
  ON public.reflex_subject_profiles;
CREATE POLICY reflex_subject_profiles_trainer_select
  ON public.reflex_subject_profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.reflex_profile_trainer_shares s
      WHERE s.subject_profile_id = reflex_subject_profiles.id
        AND s.trainer_id = auth.uid()
        AND s.revoked_at IS NULL
    )
  );

DROP POLICY IF EXISTS reflex_profile_assessments_trainer_select
  ON public.reflex_profile_assessments;
CREATE POLICY reflex_profile_assessments_trainer_select
  ON public.reflex_profile_assessments FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.reflex_profile_trainer_shares s
      WHERE s.subject_profile_id = reflex_profile_assessments.subject_profile_id
        AND s.trainer_id = auth.uid()
        AND s.revoked_at IS NULL
    )
  );

CREATE TABLE IF NOT EXISTS public.reflex_subject_profile_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_profile_id uuid NOT NULL
    REFERENCES public.reflex_subject_profiles(id) ON DELETE CASCADE,
  owner_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  author_trainer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  related_assessment_id uuid REFERENCES public.reflex_profile_assessments(id)
    ON DELETE SET NULL,
  note_type text NOT NULL DEFAULT 'handover'
    CHECK (note_type IN ('handover', 'session', 'general')),
  body text NOT NULL,
  visibility text NOT NULL DEFAULT 'handover_visible'
    CHECK (visibility IN ('handover_visible', 'private_to_author')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reflex_subject_profile_notes_subject
  ON public.reflex_subject_profile_notes(subject_profile_id, created_at DESC);

ALTER TABLE public.reflex_subject_profile_notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS reflex_subject_profile_notes_owner_select
  ON public.reflex_subject_profile_notes;
CREATE POLICY reflex_subject_profile_notes_owner_select
  ON public.reflex_subject_profile_notes FOR SELECT
  USING (owner_user_id = auth.uid());

DROP POLICY IF EXISTS reflex_subject_profile_notes_trainer_select
  ON public.reflex_subject_profile_notes;
CREATE POLICY reflex_subject_profile_notes_trainer_select
  ON public.reflex_subject_profile_notes FOR SELECT
  USING (
    visibility = 'handover_visible'
    AND EXISTS (
      SELECT 1
      FROM public.reflex_profile_trainer_shares s
      WHERE s.subject_profile_id = reflex_subject_profile_notes.subject_profile_id
        AND s.trainer_id = auth.uid()
        AND s.revoked_at IS NULL
    )
  );

DROP POLICY IF EXISTS reflex_subject_profile_notes_trainer_insert
  ON public.reflex_subject_profile_notes;
CREATE POLICY reflex_subject_profile_notes_trainer_insert
  ON public.reflex_subject_profile_notes FOR INSERT
  WITH CHECK (
    author_trainer_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.reflex_profile_trainer_shares s
      WHERE s.subject_profile_id = reflex_subject_profile_notes.subject_profile_id
        AND s.owner_user_id = reflex_subject_profile_notes.owner_user_id
        AND s.trainer_id = auth.uid()
        AND s.revoked_at IS NULL
    )
  );

CREATE OR REPLACE FUNCTION public.submit_reflex_profile_assessment(
  p_subject_profile_id uuid,
  p_package_id text,
  p_questionnaire_type text,
  p_questionnaire_version text,
  p_answers jsonb,
  p_scores jsonb,
  p_warning_confirmations jsonb DEFAULT '[]'::jsonb,
  p_safety_status text DEFAULT 'clear'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_assessment_id uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt.';
  END IF;

  IF p_subject_profile_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.reflex_subject_profiles rsp
    WHERE rsp.id = p_subject_profile_id
      AND rsp.owner_user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Profil nicht gefunden.';
  END IF;

  INSERT INTO public.reflex_profile_assessments (
    user_id,
    subject_profile_id,
    package_id,
    questionnaire_type,
    questionnaire_version,
    scoring_version,
    status,
    answers,
    scores,
    warning_confirmations,
    safety_status,
    completed_at
  )
  VALUES (
    v_user_id,
    p_subject_profile_id,
    p_package_id,
    p_questionnaire_type,
    p_questionnaire_version,
    'score_equal_weight_v1',
    'completed',
    COALESCE(p_answers, '{}'::jsonb),
    COALESCE(p_scores, '{}'::jsonb),
    COALESCE(p_warning_confirmations, '[]'::jsonb),
    COALESCE(p_safety_status, 'clear'),
    now()
  )
  RETURNING id INTO v_assessment_id;

  RETURN v_assessment_id;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_reflex_profile_assessment(
  uuid, text, text, text, jsonb, jsonb, jsonb, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_reflex_profile_assessment(
  uuid, text, text, text, jsonb, jsonb, jsonb, text
) TO authenticated;

DROP FUNCTION IF EXISTS public.get_latest_reflex_profile_assessment();

CREATE FUNCTION public.get_latest_reflex_profile_assessment()
RETURNS TABLE (
  id uuid,
  package_id text,
  subject_profile_id uuid,
  questionnaire_type text,
  questionnaire_version text,
  scoring_version text,
  status text,
  answers jsonb,
  scores jsonb,
  warning_confirmations jsonb,
  safety_status text,
  skipped_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    rpa.id,
    rpa.package_id,
    rpa.subject_profile_id,
    rpa.questionnaire_type,
    rpa.questionnaire_version,
    rpa.scoring_version,
    rpa.status,
    rpa.answers,
    rpa.scores,
    rpa.warning_confirmations,
    rpa.safety_status,
    rpa.skipped_at,
    rpa.completed_at,
    rpa.created_at
  FROM public.reflex_profile_assessments rpa
  WHERE rpa.user_id = auth.uid()
  ORDER BY rpa.created_at DESC
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_latest_reflex_profile_assessment()
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_latest_reflex_profile_assessment()
  TO authenticated;

DROP FUNCTION IF EXISTS public.get_reflex_profile_admin_rollup();

CREATE FUNCTION public.get_reflex_profile_admin_rollup()
RETURNS TABLE (
  questionnaire_type text,
  age_group text,
  assessment_count bigint,
  scores jsonb,
  answer_counts jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Nur Admins koennen Reflexprofil-Auswertungen sehen.';
  END IF;

  RETURN QUERY
  SELECT
    rpa.questionnaire_type,
    COALESCE(rsp.age_group, 'unknown') AS age_group,
    count(*) AS assessment_count,
    jsonb_agg(rpa.scores) AS scores,
    jsonb_agg(rpa.answers) AS answer_counts
  FROM public.reflex_profile_assessments rpa
  LEFT JOIN public.reflex_subject_profiles rsp
    ON rsp.id = rpa.subject_profile_id
  WHERE rpa.status = 'completed'
    AND rpa.questionnaire_type <> 'demo_child_short'
  GROUP BY rpa.questionnaire_type, COALESCE(rsp.age_group, 'unknown')
  ORDER BY rpa.questionnaire_type, age_group;
END;
$$;

REVOKE ALL ON FUNCTION public.get_reflex_profile_admin_rollup() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_reflex_profile_admin_rollup()
  TO authenticated;

COMMENT ON TABLE public.reflex_subject_profiles
  IS 'Named child/adult subject profiles for repeatable Reflexprofil assessments.';

COMMENT ON TABLE public.reflex_profile_trainer_shares
  IS 'Explicit user consent for active trainers to view full Reflexprofil data.';

COMMENT ON TABLE public.reflex_subject_profile_notes
  IS 'Trainer-authored profile notes that can support handover when consent exists.';
