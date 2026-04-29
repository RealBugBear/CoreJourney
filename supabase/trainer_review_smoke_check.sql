-- CoreJourney — Trainer review and discovery smoke check
-- Read-only verification for the trainer application approval, activation, and
-- discovery backend. Safe to run in the Supabase SQL editor.

WITH checks AS (
  SELECT
    'table: trainer_applications' AS check_name,
    to_regclass('public.trainer_applications') IS NOT NULL AS ok,
    'required for application review state' AS detail
  UNION ALL
  SELECT
    'table: trainer_application_audit_events',
    to_regclass('public.trainer_application_audit_events') IS NOT NULL,
    'required for review and activation audit history'
  UNION ALL
  SELECT
    'table: trainer_profiles',
    to_regclass('public.trainer_profiles') IS NOT NULL,
    'required after a user activates as trainer'
  UNION ALL
  SELECT
    'table: trainer_profile_private',
    to_regclass('public.trainer_profile_private') IS NOT NULL,
    'required for private trainer contact data'
  UNION ALL
  SELECT
    'column: trainer_invite_codes.trainer_application_id',
    EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'trainer_invite_codes'
        AND column_name = 'trainer_application_id'
    ),
    'activation codes must be bound to a reviewed application'
  UNION ALL
  SELECT
    'column: trainer_invite_codes.purpose',
    EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'trainer_invite_codes'
        AND column_name = 'purpose'
    ),
    'separates legacy/manual codes from application approval codes'
  UNION ALL
  SELECT
    'column: chat_channels.application_id',
    EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'chat_channels'
        AND column_name = 'application_id'
    ),
    'links review channels to trainer applications'
  UNION ALL
  SELECT
    'function: submit_trainer_application',
    to_regprocedure(
      'public.submit_trainer_application(text,text,text,text,text,text,text,text,double precision,double precision)'
    ) IS NOT NULL,
    'applicant submission RPC'
  UNION ALL
  SELECT
    'function: approve_trainer_application',
    to_regprocedure('public.approve_trainer_application(uuid)') IS NOT NULL,
    'admin approval and code generation RPC'
  UNION ALL
  SELECT
    'function: finalize_trainer_application_activation',
    to_regprocedure('public.finalize_trainer_application_activation(text,uuid)') IS NOT NULL,
    'service-role activation RPC used by activate-trainer'
  UNION ALL
  SELECT
    'function: find_trainers_nearby',
    to_regprocedure('public.find_trainers_nearby(double precision,double precision,double precision)') IS NOT NULL,
    'discovery search RPC'
  UNION ALL
  SELECT
    'function: propose_application_review_appointment',
    to_regprocedure('public.propose_application_review_appointment(uuid,uuid,timestamp with time zone[],text,text)') IS NOT NULL,
    'admin review appointment proposal RPC'
  UNION ALL
  SELECT
    'function: start_direct_call',
    to_regprocedure('public.start_direct_call(uuid)') IS NOT NULL,
    'review/direct video call RPC'
  UNION ALL
  SELECT
    'trigger: prevent direct role change',
    EXISTS (
      SELECT 1
      FROM pg_trigger t
      JOIN pg_class c ON c.oid = t.tgrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public'
        AND c.relname = 'profiles'
        AND t.tgname = 'trg_prevent_direct_role_change'
        AND NOT t.tgisinternal
    ),
    'blocks authenticated users from changing profiles.role directly'
  UNION ALL
  SELECT
    'rls: trainer_profiles enabled',
    COALESCE((
      SELECT c.relrowsecurity
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public'
        AND c.relname = 'trainer_profiles'
    ), false),
    'trainer profiles must be protected by RLS'
  UNION ALL
  SELECT
    'rls: trainer_profile_private enabled',
    COALESCE((
      SELECT c.relrowsecurity
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public'
        AND c.relname = 'trainer_profile_private'
    ), false),
    'private trainer contact data must be protected by RLS'
  UNION ALL
  SELECT
    'rls: trainer_applications enabled',
    COALESCE((
      SELECT c.relrowsecurity
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public'
        AND c.relname = 'trainer_applications'
    ), false),
    'applications must be visible only to owner/admin'
  UNION ALL
  SELECT
    'find_trainers_nearby return: submitted_at',
    EXISTS (
      SELECT 1
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.proname = 'find_trainers_nearby'
        AND pg_get_function_result(p.oid) ILIKE '%submitted_at timestamp with time zone%'
    ),
    'prevents older clients from receiving null for required model fields'
  UNION ALL
  SELECT
    'find_trainers_nearby return: status',
    EXISTS (
      SELECT 1
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.proname = 'find_trainers_nearby'
        AND pg_get_function_result(p.oid) ILIKE '%status text%'
    ),
    'keeps discovery rows compatible with TrainerProfile.fromJson'
  UNION ALL
  SELECT
    'find_trainers_nearby return: has_location',
    EXISTS (
      SELECT 1
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.proname = 'find_trainers_nearby'
        AND pg_get_function_result(p.oid) ILIKE '%has_location boolean%'
    ),
    'lets trainer UI explain discovery visibility'
)
SELECT
  CASE WHEN ok THEN 'ok' ELSE 'fail' END AS status,
  check_name,
  detail
FROM checks
ORDER BY status, check_name;

-- Data integrity checks. These should normally return zero rows.

SELECT
  'orphan application approval codes' AS check_name,
  COUNT(*) AS problem_count
FROM public.trainer_invite_codes tic
LEFT JOIN public.trainer_applications ta
  ON ta.id = tic.trainer_application_id
WHERE tic.purpose = 'trainer_application_approval'
  AND ta.id IS NULL;

SELECT
  'approved applications without activation code' AS check_name,
  COUNT(*) AS problem_count
FROM public.trainer_applications
WHERE status = 'approved'
  AND activation_code_id IS NULL;

SELECT
  'active trainer role without active trainer profile' AS check_name,
  COUNT(*) AS problem_count
FROM public.profiles p
LEFT JOIN public.trainer_profiles tp
  ON tp.id = p.id
 AND tp.status = 'active'
WHERE p.role = 'trainer'
  AND tp.id IS NULL;

SELECT
  'discoverable active trainer profiles without location' AS check_name,
  COUNT(*) AS problem_count
FROM public.trainer_profiles
WHERE status = 'active'
  AND (
    location_private IS NULL
    OR location_public IS NULL
  );
