-- CoreJourney — Atomic appointment proposal creation
-- Idempotent: safe to re-run.
--
-- Creates a proposed appointment, ensures the operational relationship exists,
-- and writes the chat notice in one server-side transaction.

CREATE OR REPLACE FUNCTION propose_appointment(
  p_client_id uuid,
  p_proposed_slots timestamptz[],
  p_location text DEFAULT NULL,
  p_notes text DEFAULT NULL,
  p_trainee_day_number int DEFAULT NULL
)
RETURNS appointments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trainer_id uuid := auth.uid();
  v_appointment appointments%ROWTYPE;
  v_channel_id uuid;
  v_slot_count int := COALESCE(array_length(p_proposed_slots, 1), 0);
  v_proposal_label text;
BEGIN
  IF v_trainer_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM profiles
    WHERE id = v_trainer_id
      AND role = 'trainer'
  ) THEN
    RAISE EXCEPTION 'Nur Trainer koennen Termine vorschlagen';
  END IF;

  IF p_client_id = v_trainer_id THEN
    RAISE EXCEPTION 'Du kannst dir selbst keinen Termin vorschlagen';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM profiles
    WHERE id = p_client_id
  ) THEN
    RAISE EXCEPTION 'Partner nicht gefunden';
  END IF;

  IF v_slot_count < 1 THEN
    RAISE EXCEPTION 'Bitte mindestens einen Slot auswaehlen';
  END IF;

  IF v_slot_count > 8 THEN
    RAISE EXCEPTION 'Bitte maximal acht Slots vorschlagen';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM unnest(p_proposed_slots) AS slot_start
    WHERE slot_start <= now()
  ) THEN
    RAISE EXCEPTION 'Terminvorschlaege muessen in der Zukunft liegen';
  END IF;

  PERFORM ensure_trainer_client_relationship(p_client_id);

  INSERT INTO appointments (
    trainer_id,
    trainee_id,
    title,
    scheduled_for,
    proposed_slots,
    duration_minutes,
    location,
    notes,
    status,
    trigger,
    trainee_day_number
  )
  VALUES (
    v_trainer_id,
    p_client_id,
    'Isometrische Partnerübung',
    NULL,
    p_proposed_slots,
    60,
    NULLIF(trim(COALESCE(p_location, '')), ''),
    NULLIF(trim(COALESCE(p_notes, '')), ''),
    'proposed',
    'manual',
    p_trainee_day_number
  )
  RETURNING * INTO v_appointment;

  v_channel_id := get_or_create_direct_channel(v_trainer_id, p_client_id);
  v_proposal_label := CASE
    WHEN v_slot_count = 1 THEN 'einen Terminvorschlag'
    ELSE v_slot_count::text || ' Terminvorschläge'
  END;

  INSERT INTO chat_messages (
    channel_id,
    sender_id,
    content,
    is_bot_response,
    is_call_request
  )
  VALUES (
    v_channel_id,
    v_trainer_id,
    'Ich habe dir ' || v_proposal_label ||
      ' gesendet. Öffne dein Dashboard, um einen passenden Termin auszuwählen.',
    false,
    false
  );

  RETURN v_appointment;
END;
$$;

GRANT EXECUTE ON FUNCTION propose_appointment(uuid, timestamptz[], text, text, int)
  TO authenticated;
