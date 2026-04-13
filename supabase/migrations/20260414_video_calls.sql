-- supabase/migrations/20260414_video_calls.sql
-- Idempotent: safe to re-run.

-- ── 1. video_calls ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS video_calls (
    id                 uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id         uuid        NOT NULL REFERENCES chat_channels(id) ON DELETE CASCADE,
    agora_channel_name text        NOT NULL UNIQUE,
    started_by         uuid        NOT NULL REFERENCES profiles(id),
    started_at         timestamptz NOT NULL DEFAULT now(),
    ended_at           timestamptz           -- null = call still active
);

-- ── 2. Index ──────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_video_calls_channel
    ON video_calls(channel_id, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_video_calls_started_by
    ON video_calls(started_by);

CREATE INDEX IF NOT EXISTS idx_video_calls_active
    ON video_calls(channel_id)
    WHERE ended_at IS NULL;

-- ── 3. RLS ───────────────────────────────────────────────────

ALTER TABLE video_calls ENABLE ROW LEVEL SECURITY;

-- SELECT: user must be a member of the chat channel
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'video_calls' AND policyname = 'video_calls_select_member'
  ) THEN
    CREATE POLICY video_calls_select_member ON video_calls
      FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM chat_channel_members
          WHERE chat_channel_members.channel_id = video_calls.channel_id
            AND chat_channel_members.user_id = auth.uid()
        )
      );
  END IF;
END $$;

-- INSERT: only moderators (trainers) can create calls
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'video_calls' AND policyname = 'video_calls_insert_moderator'
  ) THEN
    CREATE POLICY video_calls_insert_moderator ON video_calls
      FOR INSERT
      WITH CHECK (
        started_by = auth.uid()
        AND EXISTS (
          SELECT 1 FROM chat_channel_members
          WHERE chat_channel_members.channel_id = video_calls.channel_id
            AND chat_channel_members.user_id = auth.uid()
            AND chat_channel_members.role = 'moderator'
        )
      );
  END IF;
END $$;

-- UPDATE: only the person who started the call can end it (set ended_at)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'video_calls' AND policyname = 'video_calls_update_started_by'
  ) THEN
    CREATE POLICY video_calls_update_started_by ON video_calls
      FOR UPDATE
      USING (started_by = auth.uid())
      WITH CHECK (started_by = auth.uid());
  END IF;
END $$;

-- DELETE: intentionally blocked at client level; calls are soft-deleted via ended_at.
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'video_calls' AND policyname = 'video_calls_delete_deny'
  ) THEN
    CREATE POLICY video_calls_delete_deny ON video_calls
      FOR DELETE
      USING (false);
  END IF;
END $$;
