-- Migration: 20260424_atomic_trainer_switch
--
-- Problem 1: unique(trainer_id, client_id) blockiert Re-Linking weil disconnected-Rows
--            dieselbe Constraint verletzen wie active-Rows.
-- Problem 2: Switch-Trainer-Logik lag im Flutter-Client — nicht atomar, kein echter Rollback.
--
-- Fix:
--   1. Blanket-Unique-Constraint droppen
--   2. Partial Unique Index nur für status='active'
--   3. accept_invite() übernimmt atomar: Deaktivierung alter + Reaktivierung/Erstellung neuer Beziehung
--   4. Flutter-Client ruft nur noch rpc('accept_invite') auf — kein Client-Side-State-Management

-- ── 1. Alte Constraint entfernen ─────────────────────────────────────────────

ALTER TABLE trainer_client_relationships
  DROP CONSTRAINT IF EXISTS trainer_client_relationships_trainer_id_client_id_key;

-- ── 2. Partial Unique Index — nur eine ACTIVE Beziehung pro Paar ─────────────

CREATE UNIQUE INDEX IF NOT EXISTS uq_trainer_client_active
  ON trainer_client_relationships(trainer_id, client_id)
  WHERE status = 'active';

-- ── 3. accept_invite — atomar, alles im Backend ──────────────────────────────
--
-- Handles alle Szenarien:
--   A) Erstes Verknüpfen (kein vorheriger Record)
--   B) Trainer wechseln (aktive andere Beziehung deaktivieren)
--   C) Re-Linking mit demselben Trainer (disconnected-Row reaktivieren)

CREATE OR REPLACE FUNCTION accept_invite(p_code text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  _invite  trainer_client_relationships%rowtype;
  _client  uuid := auth.uid();
  _exist   uuid;
BEGIN
  -- 1. Invite-Code validieren (pending, noch nicht zugewiesen)
  SELECT * INTO _invite
  FROM trainer_client_relationships
  WHERE invite_code = upper(trim(p_code))
    AND status     = 'pending'
    AND client_id  IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or already used invite code';
  END IF;

  -- 2. Alle aktiven Beziehungen des Clients deaktivieren (atomar)
  UPDATE trainer_client_relationships
  SET status = 'disconnected'
  WHERE client_id = _client
    AND status    = 'active';

  -- 3. Existiert bereits ein disconnected Record für dieses Trainer-Client-Paar?
  SELECT id INTO _exist
  FROM trainer_client_relationships
  WHERE trainer_id = _invite.trainer_id
    AND client_id  = _client
    AND status     = 'disconnected'
  LIMIT 1;

  IF _exist IS NOT NULL THEN
    -- Scenario C: Re-Linking — bestehenden Record reaktivieren, Notizen erhalten
    UPDATE trainer_client_relationships
    SET status    = 'active',
        linked_at = now()
    WHERE id = _exist;

    -- Invite-Row bereinigen (wurde nicht gebraucht)
    DELETE FROM trainer_client_relationships WHERE id = _invite.id;
  ELSE
    -- Scenario A + B: Neuen Record aktivieren
    UPDATE trainer_client_relationships
    SET client_id = _client,
        status    = 'active',
        linked_at = now()
    WHERE id = _invite.id;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION accept_invite(text) TO authenticated;
