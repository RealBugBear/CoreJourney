-- Enable RLS on all tables
alter table profiles enable row level security;
alter table enrollments enable row level security;
alter table intake_assessments enable row level security;
alter table completion_questionnaires enable row level security;
alter table training_sessions enable row level security;
alter table progress_entries enable row level security;
alter table mood_checkins enable row level security;
alter table trainer_client_relationships enable row level security;
alter table device_tokens enable row level security;

-- profiles
create policy "Users can view own profile" on profiles
  for select using (auth.uid() = id);
create policy "Users can update own profile" on profiles
  for update using (auth.uid() = id);
create policy "Users can insert own profile" on profiles
  for insert with check (auth.uid() = id);

-- enrollments
create policy "Users can manage own enrollments" on enrollments
  for all using (auth.uid() = user_id);
create policy "Trainers can read client enrollments" on enrollments
  for select using (
    exists (
      select 1 from trainer_client_relationships
      where trainer_id = auth.uid()
        and client_id = enrollments.user_id
        and status = 'active'
    )
  );

-- intake_assessments
create policy "Users manage own intake assessments" on intake_assessments
  for all using (
    exists (
      select 1 from enrollments
      where id = intake_assessments.enrollment_id
        and user_id = auth.uid()
    )
  );

-- completion_questionnaires
create policy "Users manage own completion questionnaires" on completion_questionnaires
  for all using (
    exists (
      select 1 from enrollments
      where id = completion_questionnaires.enrollment_id
        and user_id = auth.uid()
    )
  );

-- training_sessions
create policy "Users can manage own sessions" on training_sessions
  for all using (auth.uid() = user_id);
create policy "Trainers can read client sessions" on training_sessions
  for select using (
    exists (
      select 1 from trainer_client_relationships
      where trainer_id = auth.uid()
        and client_id = training_sessions.user_id
        and status = 'active'
    )
  );

-- progress_entries
create policy "Users manage own progress" on progress_entries
  for all using (auth.uid() = user_id);
create policy "Trainers read client progress" on progress_entries
  for select using (
    exists (
      select 1 from trainer_client_relationships
      where trainer_id = auth.uid()
        and client_id = progress_entries.user_id
        and status = 'active'
    )
  );

-- mood_checkins
create policy "Users manage own mood" on mood_checkins
  for all using (auth.uid() = user_id);
create policy "Trainers read client mood" on mood_checkins
  for select using (
    exists (
      select 1 from trainer_client_relationships
      where trainer_id = auth.uid()
        and client_id = mood_checkins.user_id
        and status = 'active'
    )
  );

-- trainer_client_relationships
create policy "Users see own relationships" on trainer_client_relationships
  for select using (auth.uid() = trainer_id or auth.uid() = client_id);
create policy "Trainers manage relationships" on trainer_client_relationships
  for all using (auth.uid() = trainer_id);
create policy "Clients update their side" on trainer_client_relationships
  for update using (auth.uid() = client_id);

-- device_tokens
create policy "Users manage own tokens" on device_tokens
  for all using (auth.uid() = user_id);
