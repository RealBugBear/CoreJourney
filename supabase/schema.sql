-- ============================================================================
-- CoreJourney — Supabase Schema
-- Run this in Supabase SQL Editor: https://sxvpiggednbftfqeokyd.supabase.co
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PROFILES (extends auth.users)
-- ----------------------------------------------------------------------------
create table if not exists profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text,
  role text not null default 'practitioner' check (role in ('practitioner','trainer','admin')),
  locale text not null default 'de' check (locale in ('de','en')),
  child_assist_mode boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Auto-create profile on sign-up
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into profiles (id) values (new.id);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- ----------------------------------------------------------------------------
-- REFLEX PACKAGES (static content)
-- ----------------------------------------------------------------------------
create table if not exists reflex_packages (
  id text primary key,
  sequence_number int not null unique,
  name_de text not null,
  name_en text not null,
  description_de text,
  description_en text,
  is_free boolean not null default false,
  is_paywall_enabled boolean not null default true,
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- EXERCISES (static content)
-- ----------------------------------------------------------------------------
create table if not exists exercises (
  id text primary key,
  package_id text not null references reflex_packages(id),
  sequence_number int not null,
  title_de text not null,
  title_en text not null,
  position_instructions_de text[] not null,
  position_instructions_en text[] not null,
  movement_instructions_de text[] not null,
  movement_instructions_en text[] not null,
  hints_de text[],
  hints_en text[],
  execution_guide_de text not null,
  execution_guide_en text not null,
  duration_seconds int not null,
  repetitions int not null,
  image_path text not null,
  video_path text,
  audio_cue_path text
);

-- ----------------------------------------------------------------------------
-- ENROLLMENTS
-- ----------------------------------------------------------------------------
create table if not exists enrollments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  package_id text not null references reflex_packages(id),
  status text not null default 'active' check (status in ('active','paused','completed','abandoned')),
  assigned_duration_weeks int not null check (assigned_duration_weeks between 4 and 8),
  start_date date not null,
  target_completion_date date not null,
  completed_at timestamptz,
  paused_at timestamptz,
  preceding_enrollment_id uuid references enrollments(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_enrollments_user_id on enrollments(user_id);
create index if not exists idx_enrollments_status on enrollments(status);

-- ----------------------------------------------------------------------------
-- INTAKE ASSESSMENTS
-- ----------------------------------------------------------------------------
create table if not exists intake_assessments (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null unique references enrollments(id) on delete cascade,
  had_isometric_with_trainer boolean not null,
  additional_answers jsonb,
  recommended_duration_weeks int not null,
  user_accepted_recommendation boolean not null,
  final_duration_weeks int not null,
  completed_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- COMPLETION QUESTIONNAIRES
-- ----------------------------------------------------------------------------
create table if not exists completion_questionnaires (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null references enrollments(id) on delete cascade,
  attempt_number int not null default 1,
  response boolean not null,
  result text not null check (result in ('passed','extend')),
  next_enrollment_created boolean not null default false,
  submitted_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- TRAINING SESSIONS
-- ----------------------------------------------------------------------------
create table if not exists training_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  enrollment_id uuid not null references enrollments(id),
  session_date date not null,
  day_number int not null,
  completed_exercise_ids text[] not null,
  is_completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_sessions_user_date on training_sessions(user_id, session_date);
create index if not exists idx_sessions_enrollment on training_sessions(enrollment_id, session_date);

-- ----------------------------------------------------------------------------
-- PROGRESS ENTRIES (one per enrollment, mutable)
-- ----------------------------------------------------------------------------
create table if not exists progress_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  enrollment_id uuid not null unique references enrollments(id) on delete cascade,
  current_day int not null default 1,
  last_activity_date date,
  consecutive_inactive_days int not null default 0,
  daily_streak int not null default 0,
  weekly_streak int not null default 0,
  trainings_this_week int not null default 0,
  last_training_week_start date,
  weekly_goal int not null default 5,
  total_sessions_since_disclaimer int not null default 0,
  last_disclaimer_accepted_at timestamptz,
  updated_at timestamptz not null default now()
);
create index if not exists idx_progress_user on progress_entries(user_id);

-- ----------------------------------------------------------------------------
-- MOOD CHECK-INS
-- ----------------------------------------------------------------------------
create table if not exists mood_checkins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  enrollment_id uuid not null references enrollments(id),
  session_id uuid references training_sessions(id),
  recorded_at timestamptz not null default now(),
  day_key bigint not null,
  mood smallint check (mood between 1 and 5),
  energy smallint check (energy between 1 and 5),
  stress smallint check (stress between 1 and 5),
  note text,
  source text not null check (source in ('post_training','manual')),
  created_at timestamptz not null default now()
);
create index if not exists idx_mood_user_time on mood_checkins(user_id, recorded_at);

-- ----------------------------------------------------------------------------
-- TRAINER-CLIENT RELATIONSHIPS
-- ----------------------------------------------------------------------------
create table if not exists trainer_client_relationships (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references profiles(id) on delete cascade,
  client_id uuid not null references profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','active','disconnected')),
  trainer_notes text,
  invite_code text unique,
  linked_at timestamptz,
  created_at timestamptz not null default now(),
  unique(trainer_id, client_id)
);

-- ----------------------------------------------------------------------------
-- ACCESS CODES (admin-managed discount/free codes)
-- ----------------------------------------------------------------------------
create table if not exists access_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  type text not null check (type in ('free','discount')),
  discount_percent int check (discount_percent between 1 and 100),
  applicable_package_ids text[],
  max_redemptions int,
  redemption_count int not null default 0,
  expires_at timestamptz,
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- DEVICE TOKENS (for FCM push notifications)
-- ----------------------------------------------------------------------------
create table if not exists device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('ios','android')),
  updated_at timestamptz not null default now(),
  unique(user_id, platform)
);

-- ----------------------------------------------------------------------------
-- FEATURE FLAGS
-- ----------------------------------------------------------------------------
create table if not exists feature_flags (
  key text primary key,
  value boolean not null default false,
  description text,
  updated_at timestamptz not null default now()
);

-- Default flags
insert into feature_flags (key, value, description) values
  ('training_enabled', true, 'Master switch for training feature'),
  ('mood_tracking_enabled', true, 'Enable mood check-in feature'),
  ('social_sharing_enabled', false, 'Social sharing (Phase 4)'),
  ('trainer_accounts_enabled', true, 'Trainer account features')
on conflict (key) do nothing;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

alter table profiles enable row level security;
alter table enrollments enable row level security;
alter table intake_assessments enable row level security;
alter table completion_questionnaires enable row level security;
alter table training_sessions enable row level security;
alter table progress_entries enable row level security;
alter table mood_checkins enable row level security;
alter table trainer_client_relationships enable row level security;
alter table device_tokens enable row level security;
alter table access_codes enable row level security;

-- profiles
create policy "Users view own profile" on profiles for select using (auth.uid() = id);
create policy "Users update own profile" on profiles for update using (auth.uid() = id);

-- enrollments
create policy "Users manage own enrollments" on enrollments for all using (auth.uid() = user_id);
create policy "Trainers read client enrollments" on enrollments for select using (
  exists (select 1 from trainer_client_relationships
    where trainer_id = auth.uid() and client_id = enrollments.user_id and status = 'active')
);

-- intake_assessments (via enrollment ownership)
create policy "Users manage own assessments" on intake_assessments for all using (
  exists (select 1 from enrollments where id = intake_assessments.enrollment_id and user_id = auth.uid())
);

-- completion_questionnaires
create policy "Users manage own questionnaires" on completion_questionnaires for all using (
  exists (select 1 from enrollments where id = completion_questionnaires.enrollment_id and user_id = auth.uid())
);

-- training_sessions
create policy "Users manage own sessions" on training_sessions for all using (auth.uid() = user_id);
create policy "Trainers read client sessions" on training_sessions for select using (
  exists (select 1 from trainer_client_relationships
    where trainer_id = auth.uid() and client_id = training_sessions.user_id and status = 'active')
);

-- progress_entries
create policy "Users manage own progress" on progress_entries for all using (auth.uid() = user_id);
create policy "Trainers read client progress" on progress_entries for select using (
  exists (select 1 from trainer_client_relationships
    where trainer_id = auth.uid() and client_id = progress_entries.user_id and status = 'active')
);

-- mood_checkins
create policy "Users manage own mood" on mood_checkins for all using (auth.uid() = user_id);
create policy "Trainers read client mood" on mood_checkins for select using (
  exists (select 1 from trainer_client_relationships
    where trainer_id = auth.uid() and client_id = mood_checkins.user_id and status = 'active')
);

-- trainer_client_relationships
create policy "Users see own relationships" on trainer_client_relationships for select
  using (auth.uid() = trainer_id or auth.uid() = client_id);
create policy "Trainers manage relationships" on trainer_client_relationships for all
  using (auth.uid() = trainer_id);
create policy "Clients update their side" on trainer_client_relationships for update
  using (auth.uid() = client_id);

-- device_tokens
create policy "Users manage own tokens" on device_tokens for all using (auth.uid() = user_id);

-- access_codes — admins only (read for all authenticated to validate)
create policy "Authenticated users can read access codes" on access_codes for select
  using (auth.uid() is not null);

-- ============================================================================
-- SEED: REFLEX PACKAGES
-- ============================================================================
insert into reflex_packages (id, sequence_number, name_de, name_en, description_de, description_en, is_free, is_paywall_enabled) values
  ('moro', 1, 'Moro Reflex', 'Moro Reflex',
   'Der Moro-Reflex ist der erste Reflex, der integriert werden muss. Er liegt allen anderen zugrunde.',
   'The Moro reflex is the foundation — it must be integrated before all others.',
   true, false),
  ('spinal_galant', 2, 'Spinaler Galant + Amphibien', 'Spinal Galant + Amphibian', null, null, false, true),
  ('tlr', 3, 'Tonischer Labirint Reflex (TLR)', 'Tonic Labyrinthine Reflex (TLR)', null, null, false, true),
  ('babkin', 4, 'Babkin + Plantar + Greifen', 'Babkin + Plantar + Grasp', null, null, false, true),
  ('such_saug', 5, 'Such-Saug Reflex', 'Rooting-Sucking Reflex', null, null, false, true),
  ('atnr', 6, 'ATNR', 'ATNR', null, null, false, true),
  ('stnr', 7, 'STNR', 'STNR', null, null, false, true),
  ('babinski', 8, 'Babinski Reflex', 'Babinski Reflex', null, null, false, true),
  ('landau', 9, 'Landau Reflex', 'Landau Reflex', null, null, false, true)
on conflict (id) do nothing;

-- ============================================================================
-- SEED: MORO EXERCISES
-- ============================================================================
insert into exercises (id, package_id, sequence_number, title_de, title_en,
  position_instructions_de, position_instructions_en,
  movement_instructions_de, movement_instructions_en,
  hints_de, hints_en,
  execution_guide_de, execution_guide_en,
  duration_seconds, repetitions, image_path, video_path) values

('moro_ex1', 'moro', 1, 'Moro 5', 'Moro 5',
  array['Rückenlage','Beide Beine ausgestreckt','Arme ausgestreckt neben dem Körper, Handflächen am Boden'],
  array['Lie on your back','Both legs extended','Arms extended alongside the body, palms on the floor'],
  array['Nur ein Bein bewegt sich','Dieses Bein langsam in ca. drei Sekunden anheben und auf dem Schienbein des anderen Beins ablegen','Kurz halten','In drei Sekunden wieder zurück','Seitenwechsel'],
  array['Only one leg moves','Slowly raise this leg over about three seconds and rest it on the shin of the other leg','Hold briefly','Return in three seconds','Switch sides'],
  array['Das nicht bewegte Bein bleibt komplett ruhig und unverändert liegen'],
  array['The non-moving leg remains completely still'],
  'Bein anheben und auf dem Schienbein des anderen Beins ablegen.',
  'Raise leg and rest it on the shin of the other leg.',
  40, 3, 'assets/images/trainings/moro/moro5.png', 'moro/moro_5.mp4'),

('moro_ex2', 'moro', 2, 'Moro 3 – Halber Frosch', 'Moro 3 – Half Frog',
  array['Rückenlage','Beide Beine ausgestreckt','Neutrale Ausgangsposition'],
  array['Lie on your back','Both legs extended','Neutral starting position'],
  array['Ein Bein bewegt sich:','Fußsohle gleitet an der Innenseite des anderen Beins nach oben zum Körper, ca. drei Sekunden','Dann in drei Sekunden wieder vollständig zurück','Danach Seitenwechsel'],
  array['One leg moves:','The sole slides up the inside of the other leg toward the body, about three seconds','Slide back down over three seconds','Switch sides'],
  array['Fußsohle bleibt während der gesamten Bewegung am anderen Bein anliegend','Bewegungsweite richtet sich nach diesem Kontakt'],
  array['The sole remains in contact with the other leg throughout','Range of motion is guided by this contact'],
  'Fußsohle gleitet am anderen Bein entlang nach oben.',
  'Sole of foot slides up along the other leg.',
  40, 3, 'assets/images/trainings/moro/moro3.png', 'moro/moro_3.mp4'),

('moro_ex3', 'moro', 3, 'Moro 4 – Frosch', 'Moro 4 – Frog',
  array['Rückenlage','Beide Beine ausgestreckt','Fußsohlen zusammenführen'],
  array['Lie on your back','Both legs extended','Bring soles of the feet together'],
  array['Füße langsam drei Sekunden Richtung Körper führen','Knie gehen dabei nach außen','Füße anschließend drei Sekunden zurückführen'],
  array['Slowly bring feet toward the body over three seconds','Knees open outward','Return feet over three seconds'],
  array['Range of Motion nur so weit, wie die Fußsohlen während der gesamten Bewegung eng aneinander bleiben'],
  array['Only move as far as the soles can remain together throughout'],
  'Füße zum Körper führen, Knie gehen nach außen.',
  'Bring feet toward the body, knees open outward.',
  35, 3, 'assets/images/trainings/moro/moro4.png', 'moro/moro_4.mp4'),

('moro_ex4', 'moro', 4, 'Moro 1', 'Moro 1',
  array['Rückenlage','Beine zusammen und angewinkelt, Füße am Boden','Arme ausgestreckt neben dem Körper, Handflächen am Boden'],
  array['Lie on your back','Legs together and bent, feet on the floor','Arms extended alongside the body, palms on the floor'],
  array['Knie langsam drei Sekunden nach rechts führen','Drei Sekunden zurück zur Mitte','Knie drei Sekunden nach links führen','Zurück zur Mitte','Drei Durchgänge'],
  array['Slowly lower knees to the right over three seconds','Return to center over three seconds','Lower knees to the left over three seconds','Return to center','Three rounds'],
  array['Hüfte bleibt stabil am Boden, ohne sich abzuheben oder mitzudrehen','Bewegung nur so weit, wie die Hüfte neutral bleibt'],
  array['Hips remain stable on the floor, not lifting or rotating','Only move as far as the hips stay neutral'],
  'Knie langsam zur Seite führen. Hüfte bleibt stabil am Boden.',
  'Slowly lower knees to the side. Hips stay stable on the floor.',
  45, 3, 'assets/images/trainings/moro/moro1.png', 'moro/moro_1.mp4'),

('moro_ex5', 'moro', 5, 'Moro 2', 'Moro 2',
  array['Rückenlage','Beine zusammen und angewinkelt, Füße am Boden','Arme ausgestreckt neben dem Körper, Handflächen am Boden'],
  array['Lie on your back','Legs together and bent, feet on the floor','Arms extended alongside the body, palms on the floor'],
  array['Mit dem Ausatmen Kopf und Oberkörper langsam in ca. drei Sekunden anheben','Stirn bewegt sich Richtung Knie','Kurz halten','Langsam wieder ablegen'],
  array['While exhaling, slowly raise the head and upper body over about three seconds','Forehead moves toward the knees','Hold briefly','Slowly lower back down'],
  array['Wenn die Rumpfkraft nicht ausreicht: Hände an die Schienbeine legen, Handflächen offen lassen','Arme unterstützen nur leicht, nicht ziehen'],
  array['If core strength is insufficient: place hands on the shins, palms open','Arms only support lightly, do not pull'],
  'Kopf und Oberkörper langsam anheben, Stirn Richtung Knie.',
  'Slowly raise head and upper body, forehead toward knees.',
  30, 3, 'assets/images/trainings/moro/moro2.png', 'moro/moro_2.mp4'),

('moro_ex6', 'moro', 6, 'Moro 6 – Isometrischer Gegendruck', 'Moro 6 – Isometric Counterpressure',
  array['Rückenlage','Beine angewinkelt','Hände überkreuz auf den Knien oder Schienbeinen'],
  array['Lie on your back','Legs bent','Hands crossed on the knees or shins'],
  array['Leichter Gegendruck: Beine ziehen Richtung Körper, Hände halten dagegen','Kopf leicht anheben','Sieben Sekunden durch den Mund ausatmen','Drei Sekunden Pause','Drei Wiederholungen','Armkreuz wechseln','Drei weitere Wiederholungen'],
  array['Light counterpressure: legs pull toward body, hands push against','Slightly lift the head','Exhale through the mouth for seven seconds','Three seconds rest','Three repetitions','Switch arm cross','Three more repetitions'],
  array['Spannung gleichmäßig halten, nicht ruckartig'],
  array['Maintain even tension, no jerking'],
  'Gegendruck aufbauen. Sieben Sekunden ausatmen.',
  'Build counterpressure. Exhale for seven seconds.',
  90, 6, 'assets/images/trainings/moro/moro6.png', 'moro/moro_6.mp4'),

('moro_ex7', 'moro', 7, 'Moro 7 – Überkreuzter Gegendruck', 'Moro 7 – Crossed Counterpressure',
  array['Rückenlage','Beine angewinkelt','Hände überkreuz auf Oberschenkeln oder Knien'],
  array['Lie on your back','Legs bent','Hands crossed on the thighs or knees'],
  array['Beine Richtung Körper ziehen','Hände arbeiten dagegen','Kopf leicht zur Brust anheben','Sieben Sekunden ausatmen','Drei Sekunden Pause','Sechs Wiederholungen','Nach drei Wiederholungen Armkreuz wechseln'],
  array['Pull legs toward the body','Hands work against it','Slightly raise head toward chest','Exhale for seven seconds','Three seconds rest','Six repetitions','Switch arm cross after three repetitions'],
  array['Bewegung bleibt klein; Fokus auf kontrollierter Spannung'],
  array['Movement stays small; focus on controlled tension'],
  'Beine und Hände arbeiten gegeneinander. Sieben Sekunden ausatmen.',
  'Legs and hands work against each other. Exhale for seven seconds.',
  90, 6, 'assets/images/trainings/moro/moro7.png', 'moro/moro_7.mp4')

on conflict (id) do nothing;
