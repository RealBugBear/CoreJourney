import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/enrollments_table.dart';
import 'tables/training_sessions_table.dart';
import 'tables/progress_entries_table.dart';
import 'tables/mood_checkins_table.dart';
import 'tables/sync_jobs_table.dart';
import 'tables/intake_assessments_table.dart';
import 'tables/completion_questionnaires_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  EnrollmentsTable,
  TrainingSessionsTable,
  ProgressEntriesTable,
  MoodCheckinsTable,
  SyncJobsTable,
  IntakeAssessmentsTable,
  CompletionQuestionnairesTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'corejourney_db');
  }
}
