-- ============================================================
-- CoreJourney — Exercises Table Migration + Full Seed
-- ============================================================
-- STEP 1: Extend exercises table with timer-config columns
-- STEP 2: Seed/update MORO exercises with full timer config
-- STEP 3: Seed Spinal Galant + TLR exercises (previously missing)
-- STEP 4: RLS for exercises and reflex_packages (public read, no client writes)
-- STEP 5: Verification
--
-- Safe to re-run (all INSERT use ON CONFLICT DO UPDATE).
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- STEP 1: Add timer-config columns to exercises
-- These drive the in-app training timer for each exercise.
-- ────────────────────────────────────────────────────────────
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS rhythm_type    text    NOT NULL DEFAULT 'holdRest'
  CHECK (rhythm_type IN ('phased', 'holdRest'));
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS phases_json    jsonb   NOT NULL DEFAULT '[]';
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS has_rep_switch boolean NOT NULL DEFAULT false;
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS hold_cue_de   text    NOT NULL DEFAULT 'Halten';
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS hold_cue_en   text    NOT NULL DEFAULT 'Hold';
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS hold_seconds  int     NOT NULL DEFAULT 7;
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS rest_seconds  int     NOT NULL DEFAULT 3;
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS halfway_switch boolean NOT NULL DEFAULT false;


-- ────────────────────────────────────────────────────────────
-- STEP 2: MORO exercises — update existing rows with timer config
-- (ON CONFLICT DO UPDATE covers re-runs)
-- ────────────────────────────────────────────────────────────

INSERT INTO exercises (
  id, package_id, sequence_number,
  title_de, title_en,
  position_instructions_de, position_instructions_en,
  movement_instructions_de, movement_instructions_en,
  hints_de, hints_en,
  execution_guide_de, execution_guide_en,
  duration_seconds, repetitions,
  image_path, video_path,
  rhythm_type, phases_json, has_rep_switch,
  hold_cue_de, hold_cue_en, hold_seconds, rest_seconds, halfway_switch
) VALUES

-- moro_ex1 — Moro 5 (phased: up-hold-down, side switch)
('moro_ex1', 'moro', 1, 'Moro 5', 'Moro 5',
  array['Rückenlage','Beide Beine ausgestreckt','Arme ausgestreckt neben dem Körper, Handflächen am Boden'],
  array['Lie on your back','Both legs extended','Arms extended alongside the body, palms on the floor'],
  array['Nur ein Bein bewegt sich','Dieses Bein langsam in ca. drei Sekunden anheben und auf dem Schienbein des anderen Beins ablegen','Kurz halten','In drei Sekunden wieder zurück','Seitenwechsel'],
  array['Only one leg moves','Slowly raise this leg over about three seconds and rest it on the shin of the other leg','Hold briefly','Return in three seconds','Switch sides'],
  array['Das nicht bewegte Bein bleibt komplett ruhig und unverändert liegen'],
  array['The non-moving leg remains completely still'],
  'Bein anheben und auf dem Schienbein des anderen Beins ablegen.',
  'Raise leg and rest it on the shin of the other leg.',
  40, 3,
  'assets/images/trainings/moro/moro5.png', 'assets/videos/moro/moro_5.mov',
  'phased',
  '[{"labelDe":"Hoch","labelEn":"Up","durationSeconds":3},{"labelDe":"Halten","labelEn":"Hold","durationSeconds":1},{"labelDe":"Runter","labelEn":"Down","durationSeconds":3}]',
  true, 'Halten', 'Hold', 7, 3, false),

-- moro_ex2 — Moro 3 Halber Frosch (phased: up-down, side switch)
('moro_ex2', 'moro', 2, 'Moro 3 – Halber Frosch', 'Moro 3 – Half Frog',
  array['Rückenlage','Beide Beine ausgestreckt','Neutrale Ausgangsposition'],
  array['Lie on your back','Both legs extended','Neutral starting position'],
  array['Ein Bein bewegt sich:','Fußsohle gleitet an der Innenseite des anderen Beins nach oben zum Körper, ca. drei Sekunden','Dann in drei Sekunden wieder vollständig zurück in die neutrale Position','Danach Seitenwechsel'],
  array['One leg moves:','The sole of the foot slides along the inside of the other leg upward toward the body, about three seconds','Then slide back down to neutral over three seconds','Switch sides'],
  array['Fußsohle bleibt während der gesamten Bewegung am anderen Bein anliegend','Bewegungsweite richtet sich nach diesem Kontakt'],
  array['The sole of the foot remains in contact with the other leg throughout','Range of motion is guided by this contact'],
  'Fußsohle gleitet am anderen Bein entlang nach oben.',
  'Sole of foot slides up along the other leg.',
  40, 3,
  'assets/images/trainings/moro/moro3.png', 'assets/videos/moro/moro_3.mov',
  'phased',
  '[{"labelDe":"Hoch","labelEn":"Up","durationSeconds":3},{"labelDe":"Runter","labelEn":"Down","durationSeconds":3}]',
  true, 'Halten', 'Hold', 7, 3, false),

-- moro_ex3 — Moro 4 Frosch (phased: in-out)
('moro_ex3', 'moro', 3, 'Moro 4 – Frosch', 'Moro 4 – Frog',
  array['Rückenlage','Beide Beine ausgestreckt','Fußsohlen zusammenführen'],
  array['Lie on your back','Both legs extended','Bring the soles of the feet together'],
  array['Füße langsam drei Sekunden Richtung Körper führen','Knie gehen dabei nach außen','Füße anschließend drei Sekunden zurückführen'],
  array['Slowly bring feet toward the body over three seconds','Knees open outward','Return feet over three seconds'],
  array['Range of Motion nur so weit, wie die Fußsohlen während der gesamten Bewegung eng aneinander bleiben'],
  array['Only move as far as the soles of the feet can remain together throughout'],
  'Füße zum Körper führen, Knie gehen nach außen.',
  'Bring feet toward the body, knees open outward.',
  35, 3,
  'assets/images/trainings/moro/moro4.png', null,
  'phased',
  '[{"labelDe":"Ran","labelEn":"In","durationSeconds":3},{"labelDe":"Zurück","labelEn":"Back","durationSeconds":3}]',
  false, 'Halten', 'Hold', 7, 3, false),

-- moro_ex4 — Moro 1 (phased: 4-phase knees)
('moro_ex4', 'moro', 4, 'Moro 1', 'Moro 1',
  array['Rückenlage','Beine zusammen und angewinkelt, Füße am Boden','Arme ausgestreckt neben dem Körper, Handflächen am Boden'],
  array['Lie on your back','Legs together and bent, feet on the floor','Arms extended alongside the body, palms on the floor'],
  array['Knie langsam drei Sekunden nach rechts führen','Drei Sekunden zurück zur Mitte','Knie drei Sekunden nach links führen','Zurück zur Mitte','Drei Durchgänge'],
  array['Slowly lower knees to the right over three seconds','Return to center over three seconds','Lower knees to the left over three seconds','Return to center','Three rounds'],
  array['Hüfte bleibt stabil am Boden, ohne sich abzuheben oder mitzudrehen','Bewegung nur so weit, wie die Hüfte neutral bleibt'],
  array['Hips remain stable on the floor, not lifting or rotating','Only move as far as the hips stay neutral'],
  'Knie langsam zur Seite führen. Hüfte bleibt stabil am Boden.',
  'Slowly lower knees to the side. Hips stay stable on the floor.',
  45, 3,
  'assets/images/trainings/moro/moro1.png', 'assets/videos/moro/moro_1.mov',
  'phased',
  '[{"labelDe":"Rechts","labelEn":"Right","durationSeconds":3},{"labelDe":"Mitte","labelEn":"Centre","durationSeconds":3},{"labelDe":"Links","labelEn":"Left","durationSeconds":3},{"labelDe":"Mitte","labelEn":"Centre","durationSeconds":3}]',
  false, 'Halten', 'Hold', 7, 3, false),

-- moro_ex5 — Moro 2 (phased: exhale-rollup-hold-lower)
('moro_ex5', 'moro', 5, 'Moro 2', 'Moro 2',
  array['Rückenlage','Beine zusammen und angewinkelt, Füße am Boden','Arme ausgestreckt neben dem Körper, Handflächen am Boden'],
  array['Lie on your back','Legs together and bent, feet on the floor','Arms extended alongside the body, palms on the floor'],
  array['Mit dem Ausatmen Kopf und Oberkörper langsam in ca. drei Sekunden anheben','Stirn bewegt sich Richtung Knie','Kurz halten','Langsam wieder ablegen'],
  array['While exhaling, slowly raise the head and upper body over about three seconds','Forehead moves toward the knees','Hold briefly','Slowly lower back down'],
  array['Wenn die Rumpfkraft nicht ausreicht: Hände an die Schienbeine legen, Handflächen offen lassen','Arme unterstützen nur leicht, nicht ziehen'],
  array['If core strength is insufficient: place hands on the shins, palms open','Arms only support lightly, do not pull'],
  'Kopf und Oberkörper langsam anheben, Stirn Richtung Knie.',
  'Slowly raise head and upper body, forehead toward knees.',
  30, 3,
  'assets/images/trainings/moro/moro2.png', 'assets/videos/moro/moro_2.mov',
  'phased',
  '[{"labelDe":"Ausatmen","labelEn":"Exhale","durationSeconds":1},{"labelDe":"Hochrollen","labelEn":"Roll up","durationSeconds":3},{"labelDe":"Halten","labelEn":"Hold","durationSeconds":1},{"labelDe":"Ablegen","labelEn":"Lower","durationSeconds":2}]',
  false, 'Halten', 'Hold', 7, 3, false),

-- moro_ex6 — Moro 6 Isometrischer Gegendruck (holdRest, halfwaySwitch)
('moro_ex6', 'moro', 6, 'Moro 6 – Isometrischer Gegendruck', 'Moro 6 – Isometric Counterpressure',
  array['Rückenlage','Beine angewinkelt','Hände überkreuz auf den Knien oder Schienbeinen'],
  array['Lie on your back','Legs bent','Hands crossed on the knees or shins'],
  array['Leichter Gegendruck: Beine ziehen Richtung Körper, Hände halten dagegen','Kopf leicht anheben','Sieben Sekunden durch den Mund ausatmen','Drei Sekunden Pause','Drei Wiederholungen','Armkreuz wechseln','Drei weitere Wiederholungen'],
  array['Light counterpressure: legs pull toward body, hands push against','Slightly lift the head','Exhale through the mouth for seven seconds','Three seconds rest','Three repetitions','Switch arm cross','Three more repetitions'],
  array['Spannung gleichmäßig halten, nicht ruckartig'],
  array['Maintain even tension, no jerking'],
  'Gegendruck aufbauen. Sieben Sekunden ausatmen.',
  'Build counterpressure. Exhale for seven seconds.',
  90, 6,
  'assets/images/trainings/moro/moro6.png', 'assets/videos/moro/moro_6.mov',
  'holdRest', '[]', false, 'Spannung', 'Tension', 7, 3, true),

-- moro_ex7 — Moro 7 Überkreuzter Gegendruck (holdRest, halfwaySwitch)
('moro_ex7', 'moro', 7, 'Moro 7 – Überkreuzter Gegendruck', 'Moro 7 – Crossed Counterpressure',
  array['Rückenlage','Beine angewinkelt','Hände überkreuz auf Oberschenkeln oder Knien'],
  array['Lie on your back','Legs bent','Hands crossed on the thighs or knees'],
  array['Beine Richtung Körper ziehen','Hände arbeiten dagegen','Kopf leicht zur Brust anheben','Sieben Sekunden ausatmen','Drei Sekunden Pause','Sechs Wiederholungen','Nach drei Wiederholungen Armkreuz wechseln'],
  array['Pull legs toward the body','Hands work against it','Slightly raise head toward chest','Exhale for seven seconds','Three seconds rest','Six repetitions','Switch arm cross after three repetitions'],
  array['Bewegung bleibt klein; Fokus auf kontrollierter Spannung'],
  array['Movement stays small; focus on controlled tension'],
  'Beine und Hände arbeiten gegeneinander. Sieben Sekunden ausatmen.',
  'Legs and hands work against each other. Exhale for seven seconds.',
  90, 6,
  'assets/images/trainings/moro/moro7.png', 'assets/videos/moro/moro_7.mov',
  'holdRest', '[]', false, 'Spannung', 'Tension', 7, 3, true)

ON CONFLICT (id) DO UPDATE SET
  sequence_number            = EXCLUDED.sequence_number,
  title_de                   = EXCLUDED.title_de,
  title_en                   = EXCLUDED.title_en,
  position_instructions_de   = EXCLUDED.position_instructions_de,
  position_instructions_en   = EXCLUDED.position_instructions_en,
  movement_instructions_de   = EXCLUDED.movement_instructions_de,
  movement_instructions_en   = EXCLUDED.movement_instructions_en,
  hints_de                   = EXCLUDED.hints_de,
  hints_en                   = EXCLUDED.hints_en,
  execution_guide_de         = EXCLUDED.execution_guide_de,
  execution_guide_en         = EXCLUDED.execution_guide_en,
  duration_seconds           = EXCLUDED.duration_seconds,
  repetitions                = EXCLUDED.repetitions,
  image_path                 = EXCLUDED.image_path,
  video_path                 = EXCLUDED.video_path,
  rhythm_type                = EXCLUDED.rhythm_type,
  phases_json                = EXCLUDED.phases_json,
  has_rep_switch             = EXCLUDED.has_rep_switch,
  hold_cue_de                = EXCLUDED.hold_cue_de,
  hold_cue_en                = EXCLUDED.hold_cue_en,
  hold_seconds               = EXCLUDED.hold_seconds,
  rest_seconds               = EXCLUDED.rest_seconds,
  halfway_switch             = EXCLUDED.halfway_switch;


-- ────────────────────────────────────────────────────────────
-- STEP 3A: Spinal Galant + Amphibien — 4 exercises (all holdRest 7-3)
-- ────────────────────────────────────────────────────────────

INSERT INTO exercises (
  id, package_id, sequence_number,
  title_de, title_en,
  position_instructions_de, position_instructions_en,
  movement_instructions_de, movement_instructions_en,
  hints_de, hints_en,
  execution_guide_de, execution_guide_en,
  duration_seconds, repetitions,
  image_path, video_path,
  rhythm_type, phases_json, has_rep_switch,
  hold_cue_de, hold_cue_en, hold_seconds, rest_seconds, halfway_switch
) VALUES

('sg_ex1', 'spinal_galant', 1, 'Körperschaukeln', 'Body Rocking',
  array['Rückenlage','Füße aufstellen, Knie gebeugt','Arme locker neben dem Körper'],
  array['Lie on your back','Feet placed, knees bent','Arms relaxed alongside the body'],
  array['Mit den Füßen abstemmen und den Körper sanft vor und zurück schaukeln','Der Kopf rollt dabei entspannt mit','7 Sekunden halten, 3 Sekunden Pause','6 Wiederholungen'],
  array['Push gently with the feet and rock the body forward and back','The head rolls along relaxed','Hold 7 seconds, 3 seconds rest','6 repetitions'],
  null, null,
  'Körper sanft schaukeln, Kopf rollt mit.',
  'Rock body gently, head rolls along.',
  7, 6,
  'assets/images/trainings/spinal_galant/1spin.jpeg', null,
  'holdRest', '[]', false, 'Schaukeln', 'Rock', 7, 3, false),

('sg_ex2', 'spinal_galant', 2, 'Hüftschaukeln', 'Hip Rocking',
  array['Rückenlage oder auf dem Boden sitzend','Finger nicht verschränken'],
  array['Lie on your back or sit on the floor','Do not interlace fingers'],
  array['Den Po langsam hin und her schaukeln','Finger dabei nicht verschränken','7 Sekunden pro Seite halten, 3 Sekunden Pause','6 Wiederholungen'],
  array['Gently rock the hips side to side','Do not interlace fingers','Hold 7 seconds per side, 3 seconds rest','6 repetitions'],
  null, null,
  'Po sanft hin und her schaukeln.',
  'Gently rock hips side to side.',
  7, 6,
  'assets/images/trainings/spinal_galant/2spin.jpeg', null,
  'holdRest', '[]', false, 'Schaukeln', 'Rock', 7, 3, false),

('sg_ex3', 'spinal_galant', 3, 'Einseitiger Frosch (Bauchlage)', 'One-Legged Frog (Prone)',
  array['Bauchlage','Ein Bein in Froschposition seitlich anwinkeln','Finger nicht verschränken'],
  array['Lie on your stomach','One leg bent to the side in frog position','Do not interlace fingers'],
  array['Position halten','Finger nicht verschränken','7 Sekunden halten, 3 Sekunden Pause','6 Wiederholungen'],
  array['Hold the position','Do not interlace fingers','Hold 7 seconds, 3 seconds rest','6 repetitions'],
  null, null,
  'Position halten. Finger nicht verschränken.',
  'Hold position. Do not interlace fingers.',
  7, 6,
  'assets/images/trainings/spinal_galant/3spin.jpeg', null,
  'holdRest', '[]', false, 'Halten', 'Hold', 7, 3, false),

('sg_ex4', 'spinal_galant', 4, 'Hüftrotation (Bauchlage)', 'Hip Rotation (Prone)',
  array['Bauchlage','Arme im rechten Winkel neben dem Kopf, in Linie mit dem Körper','Bei Bedarf ein Kissen unter den Po legen'],
  array['Lie on your stomach','Arms at right angles beside the head, in line with the body','Place a pillow under the hips if needed'],
  array['Hüfte langsam rotieren','Arme bleiben im rechten Winkel neben dem Kopf','Die Hüftrotation ist wichtig — auf die Qualität achten','7 Sekunden halten, 3 Sekunden Pause','6 Wiederholungen'],
  array['Slowly rotate the hips','Arms stay at right angles beside the head','Hip rotation is key — focus on quality','Hold 7 seconds, 3 seconds rest','6 repetitions'],
  array['Wenn die Übung zu schwer ist oder Schmerzen auftreten: Kissen unter den Po legen'],
  array['If too difficult or painful: place a pillow under the hips to reduce the load'],
  'Hüfte rotieren. Arme im rechten Winkel.',
  'Rotate hips. Arms at right angles.',
  7, 6,
  'assets/images/trainings/spinal_galant/4spin.jpeg', null,
  'holdRest', '[]', false, 'Drehen', 'Rotate', 7, 3, false)

ON CONFLICT (id) DO UPDATE SET
  sequence_number            = EXCLUDED.sequence_number,
  title_de                   = EXCLUDED.title_de,
  title_en                   = EXCLUDED.title_en,
  position_instructions_de   = EXCLUDED.position_instructions_de,
  position_instructions_en   = EXCLUDED.position_instructions_en,
  movement_instructions_de   = EXCLUDED.movement_instructions_de,
  movement_instructions_en   = EXCLUDED.movement_instructions_en,
  hints_de                   = EXCLUDED.hints_de,
  hints_en                   = EXCLUDED.hints_en,
  execution_guide_de         = EXCLUDED.execution_guide_de,
  execution_guide_en         = EXCLUDED.execution_guide_en,
  duration_seconds           = EXCLUDED.duration_seconds,
  repetitions                = EXCLUDED.repetitions,
  image_path                 = EXCLUDED.image_path,
  video_path                 = EXCLUDED.video_path,
  rhythm_type                = EXCLUDED.rhythm_type,
  phases_json                = EXCLUDED.phases_json,
  has_rep_switch             = EXCLUDED.has_rep_switch,
  hold_cue_de                = EXCLUDED.hold_cue_de,
  hold_cue_en                = EXCLUDED.hold_cue_en,
  hold_seconds               = EXCLUDED.hold_seconds,
  rest_seconds               = EXCLUDED.rest_seconds,
  halfway_switch             = EXCLUDED.halfway_switch;


-- ────────────────────────────────────────────────────────────
-- STEP 3B: TLR — Tonischer Labirinth Reflex — 5 exercises
-- ────────────────────────────────────────────────────────────

INSERT INTO exercises (
  id, package_id, sequence_number,
  title_de, title_en,
  position_instructions_de, position_instructions_en,
  movement_instructions_de, movement_instructions_en,
  hints_de, hints_en,
  execution_guide_de, execution_guide_en,
  duration_seconds, repetitions,
  image_path, video_path,
  rhythm_type, phases_json, has_rep_switch,
  hold_cue_de, hold_cue_en, hold_seconds, rest_seconds, halfway_switch
) VALUES

('tlr_ex1', 'tlr', 1, 'Kopf mitschaukeln', 'Head Rolling',
  array['Rückenlage','Basisposition einnehmen','Arme locker neben dem Körper'],
  array['Lie on your back','Take basic position','Arms relaxed alongside the body'],
  array['Körper sanft schaukeln','Kopf rollt beim Schaukeln entspannt mit','7 Sekunden halten, 3 Sekunden Pause','6 Wiederholungen'],
  array['Gently rock the body','Head rolls along relaxed during rocking','Hold 7 seconds, 3 seconds rest','6 repetitions'],
  null, null,
  'Körper schaukeln, Kopf rollt entspannt mit.',
  'Rock body, head rolls along relaxed.',
  7, 6,
  'assets/images/trainings/tlr/tlr1.jpeg', null,
  'holdRest', '[]', false, 'Schaukeln', 'Rock', 7, 3, false),

('tlr_ex2', 'tlr', 2, 'Über-Kopf-Rollen', 'Over-Head Roll',
  array['Vierfüßlerstand oder Kniestand','Meistes Gewicht auf den Händen','Kopf hängt locker'],
  array['All-fours or kneeling position','Most weight on the hands','Head hangs loose'],
  array['Nasenspitze beginnt die Bewegung','Langsam vorschieben bis das Kinn auf der Brust ist','Das ist ein Über-den-Kopf-Rollen','Langsame Ausführung, etwa 2 Wiederholungen pro Durchgang','7 Sekunden, 3 Sekunden Pause, 6 Wiederholungen'],
  array['Nose tip initiates the movement','Slowly roll forward until chin is on chest','This is a rolling-over-the-head movement','Slow execution, about 2 rolls per set','7 seconds, 3 seconds rest, 6 repetitions'],
  array['Meistes Gewicht auf den Händen lassen, um den Kopf zu schonen','Bei Nackenproblemen: diese Übung nicht durchführen'],
  array['Keep most weight on the hands to protect the neck','With neck problems: do not perform this exercise'],
  'Nasenspitze führt. Langsam über den Kopf rollen.',
  'Nose leads. Slowly roll over the head.',
  7, 6,
  'assets/images/trainings/tlr/tlr2.jpeg', null,
  'holdRest', '[]', false, 'Rollen', 'Roll', 7, 3, false),

('tlr_ex3', 'tlr', 3, 'Situp-Position halten', 'Hold Sit-Up Position',
  array['Rückenlage','Beine angewinkelt, Füße am Boden','Arme zur Unterstützung bereit'],
  array['Lie on your back','Legs bent, feet on floor','Arms ready to support'],
  array['Kleinmachen: Oberkörper hochrollen wie bei einem Situp','Die Situp-Position halten','Rumpfmuskulatur aktiv einsetzen','Arme nur zur leichten Unterstützung nutzen','7 Sekunden halten, 3 Sekunden Pause, 6 Wiederholungen'],
  array['Curl up: roll upper body up as in a sit-up','Hold the sit-up position','Actively engage core muscles','Use arms only for light support','Hold 7 seconds, 3 seconds rest, 6 repetitions'],
  null, null,
  'Hochrollen und Position halten. Rumpf aktiv.',
  'Roll up and hold position. Core active.',
  7, 6,
  'assets/images/trainings/tlr/tlr3.jpeg', null,
  'holdRest', '[]', false, 'Halten', 'Hold', 7, 3, false),

('tlr_ex4', 'tlr', 4, 'Kopf heben und fallen lassen', 'Head Lift and Drop',
  array['Rückenlage','Weiches flaches Kissen oder gefaltete Decke unter den Kopf legen','Auf einem Bett wird kein Kissen benötigt'],
  array['Lie on your back','Place a soft flat pillow or folded blanket under the head','No pillow needed when lying on a bed'],
  array['Beim Einatmen den Kopf leicht anheben','Beim Ausatmen den Kopf fallen lassen','Nicht das Kinn auf die Brust — Abstand halten, Kopf nach oben','Bewegung im Nacken ist wichtig','7 Sekunden, 3 Sekunden Pause, 6 Wiederholungen'],
  array['While inhaling, gently lift the head','While exhaling, let the head drop','Do not press chin to chest — keep distance, head points up','Movement in the neck is important','7 seconds, 3 seconds rest, 6 repetitions'],
  array['Kinn nicht auf die Brust legen — Abstand zwischen Kinn und Körper halten','Bewegung soll im Nacken spürbar sein'],
  array['Do not press chin to chest — maintain distance','Movement should be felt in the neck'],
  'Einatmen: Kopf heben. Ausatmen: fallen lassen.',
  'Inhale: lift head. Exhale: let drop.',
  7, 6,
  'assets/images/trainings/tlr/tlr4.jpeg', null,
  'phased',
  '[{"labelDe":"Einatmen","labelEn":"Inhale","durationSeconds":3},{"labelDe":"Ausatmen","labelEn":"Exhale","durationSeconds":4}]',
  false, 'Halten', 'Hold', 7, 3, false),

('tlr_ex5', 'tlr', 5, 'Bein-Fahrradfahren', 'Leg Cycling',
  array['Rückenlage','Basisposition einnehmen — auf die Grundposition achten','Beine in der Luft'],
  array['Lie on your back','Take basic position — pay attention to fundamentals','Legs in the air'],
  array['Mit den Füßen in der Luft Fahrrad fahren','Große, langsame Bewegungen','7 Sekunden aktiv fahren, 3 Sekunden Pause','In der Pause: Beine einfach still in der Luft halten','6 Wiederholungen'],
  array['Cycle with feet in the air','Large, slow movements','7 seconds active cycling, 3 seconds rest','During rest: simply hold legs still in the air','6 repetitions'],
  null, null,
  'Langsam Fahrradfahren in der Luft. Große Bewegungen.',
  'Slowly cycle in the air. Large movements.',
  7, 6,
  'assets/images/trainings/tlr/tlr5.jpeg', null,
  'holdRest', '[]', false, 'Fahren', 'Cycle', 7, 3, false)

ON CONFLICT (id) DO UPDATE SET
  sequence_number            = EXCLUDED.sequence_number,
  title_de                   = EXCLUDED.title_de,
  title_en                   = EXCLUDED.title_en,
  position_instructions_de   = EXCLUDED.position_instructions_de,
  position_instructions_en   = EXCLUDED.position_instructions_en,
  movement_instructions_de   = EXCLUDED.movement_instructions_de,
  movement_instructions_en   = EXCLUDED.movement_instructions_en,
  hints_de                   = EXCLUDED.hints_de,
  hints_en                   = EXCLUDED.hints_en,
  execution_guide_de         = EXCLUDED.execution_guide_de,
  execution_guide_en         = EXCLUDED.execution_guide_en,
  duration_seconds           = EXCLUDED.duration_seconds,
  repetitions                = EXCLUDED.repetitions,
  image_path                 = EXCLUDED.image_path,
  video_path                 = EXCLUDED.video_path,
  rhythm_type                = EXCLUDED.rhythm_type,
  phases_json                = EXCLUDED.phases_json,
  has_rep_switch             = EXCLUDED.has_rep_switch,
  hold_cue_de                = EXCLUDED.hold_cue_de,
  hold_cue_en                = EXCLUDED.hold_cue_en,
  hold_seconds               = EXCLUDED.hold_seconds,
  rest_seconds               = EXCLUDED.rest_seconds,
  halfway_switch             = EXCLUDED.halfway_switch;


-- ────────────────────────────────────────────────────────────
-- STEP 4: RLS for exercises and reflex_packages
--
-- These are static content tables — no user writes ever.
-- Any authenticated user may read all rows.
-- Unauthenticated (anon) may also read — needed for paywall
-- checks before login.
-- ────────────────────────────────────────────────────────────
ALTER TABLE reflex_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises       ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies on these tables
DROP POLICY IF EXISTS "cj: reflex_packages select all" ON reflex_packages;
DROP POLICY IF EXISTS "cj: exercises select all"       ON exercises;
DROP POLICY IF EXISTS "Public can view packages"       ON reflex_packages;
DROP POLICY IF EXISTS "Public can view exercises"      ON exercises;
DROP POLICY IF EXISTS "Authenticated users can read packages" ON reflex_packages;
DROP POLICY IF EXISTS "Authenticated users can read exercises" ON exercises;

-- Read-only for everyone (authenticated + anon)
CREATE POLICY "cj: reflex_packages select all"
  ON reflex_packages FOR SELECT
  USING (true);

CREATE POLICY "cj: exercises select all"
  ON exercises FOR SELECT
  USING (true);


-- ────────────────────────────────────────────────────────────
-- STEP 5: Verification
-- ────────────────────────────────────────────────────────────
SELECT
  e.package_id,
  rp.name_de AS package_name,
  min(rp.sequence_number) AS package_order,
  count(e.id) AS exercise_count,
  array_agg(e.id ORDER BY e.sequence_number) AS exercise_ids
FROM exercises e
JOIN reflex_packages rp ON rp.id = e.package_id
GROUP BY e.package_id, rp.name_de
ORDER BY package_order;
