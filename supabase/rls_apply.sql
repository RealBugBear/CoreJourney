-- ============================================================
-- CoreJourney — RLS Apply (idempotent, vollständig, safe to re-run)
-- ============================================================
-- Einfach komplett kopieren und im Supabase SQL Editor ausführen.
-- Keine Entscheidungen nötig. Kein Fehler wenn Policies bereits
-- existieren — alle werden zuerst gelöscht, dann neu gesetzt.
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- SCHRITT 1: RLS auf allen Tabellen aktivieren
-- (idempotent — kein Fehler wenn bereits aktiv)
-- ────────────────────────────────────────────────────────────
alter table profiles                  enable row level security;
alter table enrollments               enable row level security;
alter table intake_assessments        enable row level security;
alter table completion_questionnaires enable row level security;
alter table training_sessions         enable row level security;
alter table progress_entries          enable row level security;
alter table mood_checkins             enable row level security;
alter table trainer_client_relationships enable row level security;
alter table device_tokens             enable row level security;
alter table user_consents             enable row level security;
alter table appointments              enable row level security;


-- ────────────────────────────────────────────────────────────
-- SCHRITT 2: Alle existierenden Policies löschen
-- (DROP IF EXISTS — kein Fehler wenn Policy nicht existiert)
-- Alle bekannten Namensvarianten aus allen Migrations-Scripts
-- ────────────────────────────────────────────────────────────

-- profiles
drop policy if exists "Users view own profile"         on profiles;
drop policy if exists "Users update own profile"       on profiles;
drop policy if exists "Users can view own profile"     on profiles;
drop policy if exists "Users can update own profile"   on profiles;
drop policy if exists "Users can insert own profile"   on profiles;
drop policy if exists "corejourney_profiles_select"    on profiles;
drop policy if exists "corejourney_profiles_update"    on profiles;
drop policy if exists "corejourney_profiles_insert"    on profiles;

-- enrollments
drop policy if exists "Users manage own enrollments"        on enrollments;
drop policy if exists "Users can manage own enrollments"    on enrollments;
drop policy if exists "Trainers read client enrollments"    on enrollments;
drop policy if exists "Trainers can read client enrollments" on enrollments;

-- intake_assessments
drop policy if exists "Users manage own assessments"         on intake_assessments;
drop policy if exists "Users manage own intake assessments"  on intake_assessments;

-- completion_questionnaires
drop policy if exists "Users manage own questionnaires"              on completion_questionnaires;
drop policy if exists "Users manage own completion questionnaires"   on completion_questionnaires;

-- training_sessions
drop policy if exists "Users manage own sessions"             on training_sessions;
drop policy if exists "Users can manage own sessions"         on training_sessions;
drop policy if exists "Trainers read client sessions"         on training_sessions;
drop policy if exists "Trainers can read client sessions"     on training_sessions;

-- progress_entries
drop policy if exists "Users manage own progress"       on progress_entries;
drop policy if exists "Trainers read client progress"   on progress_entries;

-- mood_checkins
drop policy if exists "Users manage own mood"       on mood_checkins;
drop policy if exists "Trainers read client mood"   on mood_checkins;

-- trainer_client_relationships
drop policy if exists "Users see own relationships"     on trainer_client_relationships;
drop policy if exists "Trainers manage relationships"   on trainer_client_relationships;
drop policy if exists "Clients update their side"       on trainer_client_relationships;

-- device_tokens
drop policy if exists "Users manage own tokens" on device_tokens;

-- user_consents
drop policy if exists "Users manage own consent" on user_consents;

-- appointments
drop policy if exists "Trainers manage own appointments"  on appointments;
drop policy if exists "Trainees read own appointments"    on appointments;

-- access_codes (falls vorhanden)
drop policy if exists "Authenticated users can read access codes" on access_codes;

-- cj: prefixed policies (from previous runs of this script)
drop policy if exists "cj: profiles select own"                    on profiles;
drop policy if exists "cj: profiles insert own"                    on profiles;
drop policy if exists "cj: profiles update own"                    on profiles;
drop policy if exists "cj: enrollments all own"                    on enrollments;
drop policy if exists "cj: enrollments trainer read"               on enrollments;
drop policy if exists "cj: intake_assessments all own"             on intake_assessments;
drop policy if exists "cj: completion_questionnaires all own"      on completion_questionnaires;
drop policy if exists "cj: training_sessions all own"              on training_sessions;
drop policy if exists "cj: training_sessions trainer read"         on training_sessions;
drop policy if exists "cj: progress_entries all own"               on progress_entries;
drop policy if exists "cj: progress_entries trainer read"          on progress_entries;
drop policy if exists "cj: mood_checkins all own"                  on mood_checkins;
drop policy if exists "cj: mood_checkins trainer read"             on mood_checkins;
drop policy if exists "cj: tcr select participant"                 on trainer_client_relationships;
drop policy if exists "cj: tcr all trainer"                        on trainer_client_relationships;
drop policy if exists "cj: tcr update client"                      on trainer_client_relationships;
drop policy if exists "cj: device_tokens all own"                  on device_tokens;
drop policy if exists "cj: user_consents all own"                  on user_consents;
drop policy if exists "cj: appointments all trainer"               on appointments;
drop policy if exists "cj: appointments select trainee"            on appointments;


-- ────────────────────────────────────────────────────────────
-- SCHRITT 3: Alle Policies korrekt neu setzen
-- ────────────────────────────────────────────────────────────

-- ── profiles ─────────────────────────────────────────────────
-- id = auth.uid() (kein user_id — profiles.id IS die User-UUID)
create policy "cj: profiles select own"
  on profiles for select
  using (auth.uid() = id);

create policy "cj: profiles insert own"
  on profiles for insert
  with check (auth.uid() = id);

create policy "cj: profiles update own"
  on profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);


-- ── enrollments ───────────────────────────────────────────────
create policy "cj: enrollments all own"
  on enrollments for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Trainer liest Enrollments seiner aktiven Trainees
create policy "cj: enrollments trainer read"
  on enrollments for select
  using (
    exists (
      select 1 from trainer_client_relationships
      where trainer_id = auth.uid()
        and client_id = enrollments.user_id
        and status = 'active'
    )
  );


-- ── intake_assessments ────────────────────────────────────────
-- Kein user_id — Ownership via enrollment_id → enrollments.user_id
create policy "cj: intake_assessments all own"
  on intake_assessments for all
  using (
    exists (
      select 1 from enrollments
      where id = intake_assessments.enrollment_id
        and user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from enrollments
      where id = intake_assessments.enrollment_id
        and user_id = auth.uid()
    )
  );


-- ── completion_questionnaires ─────────────────────────────────
-- Kein user_id — Ownership via enrollment_id → enrollments.user_id
create policy "cj: completion_questionnaires all own"
  on completion_questionnaires for all
  using (
    exists (
      select 1 from enrollments
      where id = completion_questionnaires.enrollment_id
        and user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from enrollments
      where id = completion_questionnaires.enrollment_id
        and user_id = auth.uid()
    )
  );


-- ── training_sessions ─────────────────────────────────────────
create policy "cj: training_sessions all own"
  on training_sessions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "cj: training_sessions trainer read"
  on training_sessions for select
  using (
    exists (
      select 1 from trainer_client_relationships
      where trainer_id = auth.uid()
        and client_id = training_sessions.user_id
        and status = 'active'
    )
  );


-- ── progress_entries ──────────────────────────────────────────
create policy "cj: progress_entries all own"
  on progress_entries for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "cj: progress_entries trainer read"
  on progress_entries for select
  using (
    exists (
      select 1 from trainer_client_relationships
      where trainer_id = auth.uid()
        and client_id = progress_entries.user_id
        and status = 'active'
    )
  );


-- ── mood_checkins ─────────────────────────────────────────────
create policy "cj: mood_checkins all own"
  on mood_checkins for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "cj: mood_checkins trainer read"
  on mood_checkins for select
  using (
    exists (
      select 1 from trainer_client_relationships
      where trainer_id = auth.uid()
        and client_id = mood_checkins.user_id
        and status = 'active'
    )
  );


-- ── trainer_client_relationships ──────────────────────────────
-- Jeder Beteiligte (trainer_id ODER client_id) sieht die Zeile
create policy "cj: tcr select participant"
  on trainer_client_relationships for select
  using (auth.uid() = trainer_id or auth.uid() = client_id);

-- Trainer verwaltet seine Relationships vollständig
create policy "cj: tcr all trainer"
  on trainer_client_relationships for all
  using (auth.uid() = trainer_id)
  with check (auth.uid() = trainer_id);

-- Trainee darf nur Updates (Invite annehmen, Status ändern)
create policy "cj: tcr update client"
  on trainer_client_relationships for update
  using (auth.uid() = client_id)
  with check (auth.uid() = client_id);


-- ── device_tokens ─────────────────────────────────────────────
create policy "cj: device_tokens all own"
  on device_tokens for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);


-- ── user_consents ─────────────────────────────────────────────
create policy "cj: user_consents all own"
  on user_consents for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);


-- ── appointments ──────────────────────────────────────────────
-- trainer_id verwaltet, trainee_id liest
create policy "cj: appointments all trainer"
  on appointments for all
  using (auth.uid() = trainer_id)
  with check (auth.uid() = trainer_id);

create policy "cj: appointments select trainee"
  on appointments for select
  using (auth.uid() = trainee_id);


-- ────────────────────────────────────────────────────────────
-- SCHRITT 4: Verifikation — muss am Ende grüne Werte zeigen
-- ────────────────────────────────────────────────────────────
select
  t.tablename,
  t.rowsecurity                          as rls_active,
  count(p.policyname)                    as policy_count
from pg_tables t
left join pg_policies p
  on p.tablename = t.tablename
  and p.schemaname = 'public'
where t.schemaname = 'public'
  and t.tablename in (
    'profiles','enrollments','intake_assessments',
    'completion_questionnaires','training_sessions',
    'progress_entries','mood_checkins',
    'trainer_client_relationships','device_tokens',
    'user_consents','appointments'
  )
group by t.tablename, t.rowsecurity
order by t.tablename;
