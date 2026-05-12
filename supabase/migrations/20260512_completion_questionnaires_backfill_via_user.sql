-- Backfill subject_profile_id for completion_questionnaires whose enrollment
-- had no subject_profile_id (legacy multi-enrollment users).
-- Resolves the 4 unlinked rows left after the Phase-2 backfill.
-- Strategy: enrollment.user_id → adult_self profile for that user.

UPDATE public.completion_questionnaires cq
SET subject_profile_id = rsp.id
FROM public.enrollments e
JOIN public.reflex_subject_profiles rsp
  ON rsp.owner_user_id = e.user_id
 AND rsp.profile_type = 'adult_self'
WHERE e.id = cq.enrollment_id
  AND cq.subject_profile_id IS NULL;
