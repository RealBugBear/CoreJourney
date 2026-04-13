-- ============================================================
-- CoreJourney Chat Foundation Migration
-- Purpose: Creates the full chat schema (channels, members,
--          messages, bot FAQs), RLS policies, indexes, and
--          the get_or_create_direct_channel() RPC helper.
--
-- Run in DEV Supabase SQL editor only.
-- This migration is idempotent: safe to re-run.
-- ============================================================


-- ── 1. chat_channels ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS chat_channels (
    id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    type       text        NOT NULL CHECK (type IN ('direct', 'community')),
    package_id text        REFERENCES reflex_packages(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    -- community channels require a package_id; direct channels must have none
    CONSTRAINT chk_channel_package_id CHECK (
        (type = 'community' AND package_id IS NOT NULL) OR
        (type = 'direct'    AND package_id IS NULL)
    )
);


-- ── 2. chat_channel_members ──────────────────────────────────

CREATE TABLE IF NOT EXISTS chat_channel_members (
    channel_id   uuid        NOT NULL REFERENCES chat_channels(id) ON DELETE CASCADE,
    user_id      uuid        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role         text        NOT NULL DEFAULT 'member' CHECK (role IN ('member', 'moderator')),
    last_read_at timestamptz NOT NULL DEFAULT now(),
    joined_at    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (channel_id, user_id)
);


-- ── 3. chat_messages ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS chat_messages (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id      uuid        NOT NULL REFERENCES chat_channels(id) ON DELETE CASCADE,
    sender_id       uuid        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content         text        NOT NULL,
    is_bot_response boolean     NOT NULL DEFAULT false,
    is_call_request boolean     NOT NULL DEFAULT false,
    deleted_at      timestamptz,          -- nullable; soft-delete timestamp
    created_at      timestamptz NOT NULL DEFAULT now()
);


-- ── 4. bot_faqs ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS bot_faqs (
    id                 uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
    keywords           text[]  NOT NULL,
    response_de        text    NOT NULL,
    response_en        text    NOT NULL,
    escalate_to_trainer boolean NOT NULL DEFAULT false,
    created_at         timestamptz NOT NULL DEFAULT now()
);


-- ── 5. Indexes ───────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_chat_messages_channel_created
    ON chat_messages(channel_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_chat_channel_members_user
    ON chat_channel_members(user_id);

CREATE INDEX IF NOT EXISTS idx_chat_messages_sender
    ON chat_messages(sender_id);


-- ── 6. Bot system user seed ──────────────────────────────────
-- IMPORTANT: The UUID below is a placeholder.
-- After creating the real bot auth user in Supabase Auth,
-- replace '00000000-0000-0000-0000-000000000001' with the
-- actual auth.users UUID and re-run the insert (or update
-- the existing row).

INSERT INTO profiles (id, display_name, role, locale)
VALUES (
    'd714e822-83a2-474f-ba01-2e59ad20dcae',
    'CoreJourney Assistent',
    'practitioner',
    'de'
)
ON CONFLICT DO NOTHING;


-- ── 7. bot_faqs seed data ────────────────────────────────────

INSERT INTO bot_faqs (keywords, response_de, response_en, escalate_to_trainer) VALUES

-- FAQ 1: Pain / Schmerz
(
    ARRAY['schmerz','pain','weh tut','hurt','hurts'],
    'Es tut mir leid zu hören, dass du Schmerzen hast. Bitte höre auf dein Körpergefühl und setze die Übungen vorerst aus. Dein Trainer wird dich kontaktieren, um gemeinsam eine sichere Lösung zu finden.',
    'I''m sorry to hear you''re in pain. Please listen to your body and pause the exercises for now. Your trainer will be in touch to help find a safe way forward together.',
    true
),

-- FAQ 2: Duration / Wie lange
(
    ARRAY['wie lange','how long','dauer','wochen','weeks'],
    'Die Dauer deines Programms hängt von deinen persönlichen Zielen und deinem Fortschritt ab. Typischerweise sehen Klienten nach 4–8 Wochen erste spürbare Verbesserungen. Dein Trainer passt den Plan regelmäßig an deinen Fortschritt an.',
    'The length of your programme depends on your personal goals and progress. Clients typically notice meaningful improvements after 4–8 weeks. Your trainer regularly adjusts the plan to match your progress.',
    false
),

-- FAQ 3: Missed session / Vergessen
(
    ARRAY['vergessen','forgot','verpasst','missed','ausgelassen'],
    'Kein Stress – das passiert! Mach einfach weiter mit der nächsten geplanten Einheit. Du musst die verpasste Einheit nicht nachholen. Kontinuität über die Zeit zählt mehr als ein einzelner Tag.',
    'No worries – it happens! Just continue with your next scheduled session. There''s no need to make up the missed one. Consistency over time matters far more than a single day.',
    false
),

-- FAQ 4: Nausea / Dizziness
(
    ARRAY['übelkeit','nausea','schwindel','dizzy','dizziness'],
    'Schwindel oder Übelkeit während des Trainings solltest du ernst nehmen. Bitte beende die Einheit sofort, ruhe dich aus und trinke ausreichend Wasser. Dein Trainer wird informiert und meldet sich bei dir, um sicherzustellen, dass es dir gut geht.',
    'Dizziness or nausea during exercise is something to take seriously. Please stop your session immediately, rest, and drink plenty of water. Your trainer will be notified and will check in with you to make sure you''re okay.',
    true
)

ON CONFLICT DO NOTHING;


-- ── 8. Row-Level Security ────────────────────────────────────

ALTER TABLE chat_channels        ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_channel_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages        ENABLE ROW LEVEL SECURITY;
ALTER TABLE bot_faqs             ENABLE ROW LEVEL SECURITY;

-- ── chat_channels policies ───────────────────────────────────

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'chat_channels' AND policyname = 'channels_select_member'
  ) THEN
    CREATE POLICY channels_select_member ON chat_channels
      FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM chat_channel_members
          WHERE chat_channel_members.channel_id = chat_channels.id
            AND chat_channel_members.user_id = auth.uid()
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'chat_channels' AND policyname = 'channels_insert_deny'
  ) THEN
    CREATE POLICY channels_insert_deny ON chat_channels
      FOR INSERT
      WITH CHECK (false);
  END IF;
END $$;

-- ── chat_channel_members policies ────────────────────────────

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'chat_channel_members' AND policyname = 'members_select_own'
  ) THEN
    CREATE POLICY members_select_own ON chat_channel_members
      FOR SELECT
      USING (user_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'chat_channel_members' AND policyname = 'members_update_own'
  ) THEN
    CREATE POLICY members_update_own ON chat_channel_members
      FOR UPDATE
      USING (user_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'chat_channel_members' AND policyname = 'members_insert_deny'
  ) THEN
    CREATE POLICY members_insert_deny ON chat_channel_members
      FOR INSERT
      WITH CHECK (false);
  END IF;
END $$;

-- ── chat_messages policies ───────────────────────────────────

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'chat_messages' AND policyname = 'messages_select_member'
  ) THEN
    CREATE POLICY messages_select_member ON chat_messages
      FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM chat_channel_members
          WHERE chat_channel_members.channel_id = chat_messages.channel_id
            AND chat_channel_members.user_id = auth.uid()
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'chat_messages' AND policyname = 'messages_insert_member'
  ) THEN
    CREATE POLICY messages_insert_member ON chat_messages
      FOR INSERT
      WITH CHECK (
        sender_id = auth.uid()
        AND EXISTS (
          SELECT 1 FROM chat_channel_members
          WHERE chat_channel_members.channel_id = chat_messages.channel_id
            AND chat_channel_members.user_id = auth.uid()
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'chat_messages' AND policyname = 'messages_update_soft_delete_sender'
  ) THEN
    CREATE POLICY messages_update_soft_delete_sender ON chat_messages
      FOR UPDATE
      USING (sender_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'chat_messages' AND policyname = 'messages_update_soft_delete_moderator'
  ) THEN
    CREATE POLICY messages_update_soft_delete_moderator ON chat_messages
      FOR UPDATE
      USING (
        EXISTS (
          SELECT 1 FROM chat_channel_members
          WHERE chat_channel_members.channel_id = chat_messages.channel_id
            AND chat_channel_members.user_id = auth.uid()
            AND chat_channel_members.role = 'moderator'
        )
      );
  END IF;
END $$;

-- ── bot_faqs policies ────────────────────────────────────────
-- No client-side reads; Edge Functions use the service role key.

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'bot_faqs' AND policyname = 'faqs_select_deny'
  ) THEN
    CREATE POLICY faqs_select_deny ON bot_faqs
      FOR SELECT
      USING (false);
  END IF;
END $$;


-- ── 9. RPC: get_or_create_direct_channel ─────────────────────

CREATE OR REPLACE FUNCTION get_or_create_direct_channel(user_a uuid, user_b uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_channel_id uuid;
    v_role_a     text;
    v_role_b     text;
BEGIN
    -- 1. Look for an existing direct channel shared by both users.
    SELECT m1.channel_id
    INTO   v_channel_id
    FROM   chat_channel_members m1
    JOIN   chat_channel_members m2
           ON m1.channel_id = m2.channel_id
    JOIN   chat_channels c
           ON c.id = m1.channel_id
    WHERE  m1.user_id = user_a
      AND  m2.user_id = user_b
      AND  c.type     = 'direct'
    LIMIT  1;

    IF v_channel_id IS NOT NULL THEN
        RETURN v_channel_id;
    END IF;

    -- 2. No existing channel found — create one.
    INSERT INTO chat_channels (type)
    VALUES ('direct')
    RETURNING id INTO v_channel_id;

    -- Determine member roles: trainers become moderators, everyone else is member.
    SELECT CASE WHEN role = 'trainer' THEN 'moderator' ELSE 'member' END
    INTO   v_role_a
    FROM   profiles
    WHERE  id = user_a;

    SELECT CASE WHEN role = 'trainer' THEN 'moderator' ELSE 'member' END
    INTO   v_role_b
    FROM   profiles
    WHERE  id = user_b;

    -- Insert both members.
    INSERT INTO chat_channel_members (channel_id, user_id, role)
    VALUES
        (v_channel_id, user_a, COALESCE(v_role_a, 'member')),
        (v_channel_id, user_b, COALESCE(v_role_b, 'member'));

    RETURN v_channel_id;
END;
$$;
