-- ============================================================
-- CoreJourney — Idempotency Constraints (safe to re-run)
-- ============================================================
-- STEP 1: Deduplicate existing dirty data
--         Strategy: keep the row with the latest updated_at.
--         FK children without CASCADE are re-parented to the
--         surviving enrollment before the duplicate is deleted.
--         FK children WITH ON DELETE CASCADE are auto-deleted.
--
-- FK map for enrollments:
--   training_sessions.enrollment_id  → NO cascade  → re-parent
--   mood_checkins.enrollment_id      → NO cascade  → re-parent
--   progress_entries.enrollment_id   → CASCADE     → auto-deleted
--   intake_assessments.enrollment_id → CASCADE     → auto-deleted
--   completion_questionnaires.*      → CASCADE     → auto-deleted
--   enrollments.preceding_enrollment_id (self)     → NULL out
--
-- STEP 2: Create UNIQUE indexes as permanent guardrails
-- STEP 3: Verification
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- STEP 1A: Build a winner→loser mapping for duplicate enrollments
-- ────────────────────────────────────────────────────────────
CREATE TEMP TABLE _enrollment_dedup_map AS
SELECT
  loser.id  AS loser_id,
  winner.id AS winner_id
FROM (
  SELECT id, user_id, package_id,
    ROW_NUMBER() OVER (
      PARTITION BY user_id, package_id
      ORDER BY updated_at DESC NULLS LAST, id DESC
    ) AS rn
  FROM enrollments
  WHERE status = 'active'
) loser
JOIN (
  SELECT id, user_id, package_id,
    ROW_NUMBER() OVER (
      PARTITION BY user_id, package_id
      ORDER BY updated_at DESC NULLS LAST, id DESC
    ) AS rn
  FROM enrollments
  WHERE status = 'active'
) winner
  ON loser.user_id    = winner.user_id
 AND loser.package_id = winner.package_id
 AND winner.rn = 1
WHERE loser.rn > 1;


-- ────────────────────────────────────────────────────────────
-- STEP 1B: Re-parent training_sessions loser → winner
--
-- Only moves a session if the winner does NOT already have a
-- completed session for the same day_number (avoids conflicts).
-- Remaining sessions on a loser are deleted.
-- ────────────────────────────────────────────────────────────
UPDATE training_sessions ts
SET enrollment_id = m.winner_id
FROM _enrollment_dedup_map m
WHERE ts.enrollment_id = m.loser_id
  AND NOT EXISTS (
    SELECT 1 FROM training_sessions existing
    WHERE existing.enrollment_id = m.winner_id
      AND existing.day_number    = ts.day_number
      AND existing.is_completed  = true
      AND ts.is_completed        = true
  );

DELETE FROM training_sessions ts
USING _enrollment_dedup_map m
WHERE ts.enrollment_id = m.loser_id;


-- ────────────────────────────────────────────────────────────
-- STEP 1C: Re-parent mood_checkins loser → winner
--
-- Moves all check-ins to the winner. No uniqueness constraint
-- on (enrollment_id, day_key), so all can be re-parented safely.
-- ────────────────────────────────────────────────────────────
UPDATE mood_checkins mc
SET enrollment_id = m.winner_id
FROM _enrollment_dedup_map m
WHERE mc.enrollment_id = m.loser_id;


-- ────────────────────────────────────────────────────────────
-- STEP 1D: NULL out preceding_enrollment_id self-references
--          that point to a loser (avoids FK violation on delete)
-- ────────────────────────────────────────────────────────────
UPDATE enrollments e
SET preceding_enrollment_id = NULL
FROM _enrollment_dedup_map m
WHERE e.preceding_enrollment_id = m.loser_id;


-- ────────────────────────────────────────────────────────────
-- STEP 1E: Delete the loser enrollments
--
-- progress_entries, intake_assessments, completion_questionnaires
-- are ON DELETE CASCADE → auto-deleted by Postgres.
-- training_sessions and mood_checkins are already re-parented.
-- ────────────────────────────────────────────────────────────
DELETE FROM enrollments e
USING _enrollment_dedup_map m
WHERE e.id = m.loser_id;

DROP TABLE _enrollment_dedup_map;


-- ────────────────────────────────────────────────────────────
-- STEP 1F: Deduplicate progress_entries (survivor cleanup)
--
-- A winner that absorbed a loser may now have >1 progress entry
-- if re-parenting ran before cascade. Keep the latest.
-- ────────────────────────────────────────────────────────────
DELETE FROM progress_entries
WHERE id IN (
  SELECT id FROM (
    SELECT id,
      ROW_NUMBER() OVER (
        PARTITION BY enrollment_id
        ORDER BY updated_at DESC NULLS LAST, id DESC
      ) AS rn
    FROM progress_entries
  ) ranked
  WHERE rn > 1
);


-- ────────────────────────────────────────────────────────────
-- STEP 1G: Deduplicate training_sessions (survivor cleanup)
--
-- Keep the latest completed session per (enrollment_id, day_number).
-- ────────────────────────────────────────────────────────────
DELETE FROM training_sessions
WHERE id IN (
  SELECT id FROM (
    SELECT id,
      ROW_NUMBER() OVER (
        PARTITION BY enrollment_id, day_number
        ORDER BY created_at DESC NULLS LAST, id DESC
      ) AS rn
    FROM training_sessions
    WHERE is_completed = true
  ) ranked
  WHERE rn > 1
);


-- ────────────────────────────────────────────────────────────
-- STEP 2A: UNIQUE index — one active enrollment per (user, package)
-- ────────────────────────────────────────────────────────────
DROP INDEX IF EXISTS enrollments_user_package_active_unique;
CREATE UNIQUE INDEX enrollments_user_package_active_unique
  ON enrollments (user_id, package_id)
  WHERE status = 'active';


-- ────────────────────────────────────────────────────────────
-- STEP 2B: UNIQUE index — one progress entry per enrollment
-- ────────────────────────────────────────────────────────────
DROP INDEX IF EXISTS progress_entries_enrollment_unique;
CREATE UNIQUE INDEX progress_entries_enrollment_unique
  ON progress_entries (enrollment_id);


-- ────────────────────────────────────────────────────────────
-- STEP 2C: UNIQUE index — one completed session per (enrollment, day)
-- ────────────────────────────────────────────────────────────
DROP INDEX IF EXISTS training_sessions_enrollment_day_unique;
CREATE UNIQUE INDEX training_sessions_enrollment_day_unique
  ON training_sessions (enrollment_id, day_number)
  WHERE is_completed = true;


-- ────────────────────────────────────────────────────────────
-- STEP 3: Verification — must show 3 rows
-- ────────────────────────────────────────────────────────────
SELECT
  indexname,
  tablename,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'enrollments_user_package_active_unique',
    'progress_entries_enrollment_unique',
    'training_sessions_enrollment_day_unique'
  )
ORDER BY tablename;
