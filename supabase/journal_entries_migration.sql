-- ════════════════════════════════════════════════════════════════════════════
-- journal_entries — enterprise-grade migration
--
-- Architecture: journal entries are first-class records, separate from mood
-- checkins. A journal entry can optionally reference a mood_checkin
-- (via checkin_id) to surface the mood context alongside the note.
--
-- This separation enables:
--   • standalone text entries with no mood rating
--   • mood checkins with no note (metrics only)
--   • linked entries (note written during/after a mood checkin)
--   • independent querying, indexing, and audit of each type
-- ════════════════════════════════════════════════════════════════════════════

-- ── STEP 1: Create table (or upgrade existing) ───────────────────────────────

-- Fresh install: create if not yet present
CREATE TABLE IF NOT EXISTS journal_entries (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  enrollment_id UUID REFERENCES enrollments(id) ON DELETE SET NULL,
  content       TEXT NOT NULL CHECK (char_length(content) > 0),
  day_key       INTEGER NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Idempotent column additions — safe to run even if columns already exist.
-- Handles the case where the table was created by an earlier, narrower schema.
--
-- checkin_id is stored as a plain UUID (no FK to mood_checkins) to avoid FK
-- race conditions during sync: journal_entries and mood_checkins are queued
-- independently and may arrive at Supabase in any order. The local Drift DB
-- maintains the FK link for the edit flow; Supabase only needs the UUID for
-- reference/analytics.
ALTER TABLE journal_entries
  ADD COLUMN IF NOT EXISTS checkin_id    UUID,
  ADD COLUMN IF NOT EXISTS mood          SMALLINT CHECK (mood BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS energy        SMALLINT CHECK (energy BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS stress        SMALLINT CHECK (stress BETWEEN 1 AND 5);

-- Drop FK on checkin_id if it was previously created with one (idempotent)
DO $$
DECLARE
  con_name TEXT;
BEGIN
  SELECT conname INTO con_name
    FROM pg_constraint
   WHERE conrelid = 'journal_entries'::regclass
     AND contype = 'f'
     AND conname LIKE '%checkin_id%'
   LIMIT 1;
  IF con_name IS NOT NULL THEN
    EXECUTE 'ALTER TABLE journal_entries DROP CONSTRAINT ' || quote_ident(con_name);
  END IF;
END $$;

-- ── STEP 2: Indexes ───────────────────────────────────────────────────────────

-- Primary read pattern: fetch all entries for a user's enrollment in a date range
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_enrollment
  ON journal_entries (user_id, enrollment_id, day_key DESC);

-- Lookup by checkin_id to find linked note when editing a checkin
CREATE INDEX IF NOT EXISTS idx_journal_entries_checkin_id
  ON journal_entries (checkin_id)
  WHERE checkin_id IS NOT NULL;

-- ── STEP 3: updated_at trigger ────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION _journal_entries_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_journal_entries_updated_at ON journal_entries;
CREATE TRIGGER trg_journal_entries_updated_at
  BEFORE UPDATE ON journal_entries
  FOR EACH ROW EXECUTE FUNCTION _journal_entries_set_updated_at();

-- ── STEP 4: RLS ───────────────────────────────────────────────────────────────

ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;

-- Drop previous versions (idempotent)
DROP POLICY IF EXISTS "cj: journal_entries select own"  ON journal_entries;
DROP POLICY IF EXISTS "cj: journal_entries insert own"  ON journal_entries;
DROP POLICY IF EXISTS "cj: journal_entries update own"  ON journal_entries;
DROP POLICY IF EXISTS "cj: journal_entries delete own"  ON journal_entries;

CREATE POLICY "cj: journal_entries select own"
  ON journal_entries FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "cj: journal_entries insert own"
  ON journal_entries FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "cj: journal_entries update own"
  ON journal_entries FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "cj: journal_entries delete own"
  ON journal_entries FOR DELETE
  USING (user_id = auth.uid());

-- ── STEP 5: Verify ───────────────────────────────────────────────────────────

SELECT
  count(*)                     AS total_entries,
  count(checkin_id)            AS linked_to_checkin,
  count(*) FILTER (WHERE mood IS NOT NULL) AS with_mood
FROM journal_entries;
