import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/enrollments_table.dart';
import 'tables/exercises_table.dart';
import 'tables/training_sessions_table.dart';
import 'tables/progress_entries_table.dart';
import 'tables/mood_checkins_table.dart';
import 'tables/sync_jobs_table.dart';
import 'tables/intake_assessments_table.dart';
import 'tables/completion_questionnaires_table.dart';
import 'tables/journal_entries_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  EnrollmentsTable,
  ExercisesTable,
  TrainingSessionsTable,
  ProgressEntriesTable,
  MoodCheckinsTable,
  SyncJobsTable,
  IntakeAssessmentsTable,
  CompletionQuestionnairesTable,
  JournalEntriesTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.executor);

  /// Opens the database at the correct persistent path.
  ///
  /// Uses [getApplicationSupportDirectory] — the correct location for app data
  /// on all platforms (not user-visible, backed up on iOS, persists across
  /// launches). Falls back to an in-memory database ONLY if the directory
  /// cannot be obtained, and logs a warning in that case.
  static Future<AppDatabase> open() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, 'corejourney_db.sqlite'));
      return AppDatabase._internal(
        NativeDatabase.createInBackground(file),
      );
    } catch (e) {
      // Last-resort fallback — should not happen on any supported platform.
      // Data will not persist across launches in this state.
      assert(false, 'AppDatabase.open() fell back to in-memory: $e');
      return AppDatabase._internal(NativeDatabase.memory());
    }
  }

  /// In-memory database for unit tests.
  AppDatabase.inMemory() : super(NativeDatabase.memory());

  /// Deletes all user-specific rows from every table.
  /// Called on sign-out to prevent data leaking to the next user session.
  Future<void> clearUserData() async {
    await transaction(() async {
      await delete(enrollmentsTable).go();
      await delete(trainingSessionsTable).go();
      await delete(progressEntriesTable).go();
      await delete(moodCheckinsTable).go();
      await delete(syncJobsTable).go();
      await delete(intakeAssessmentsTable).go();
      await delete(completionQuestionnairesTable).go();
      await delete(journalEntriesTable).go();
      // exercisesTable is shared content (not user-specific) — keep it.
    });
  }

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(journalEntriesTable);
          }
          if (from < 3) {
            await m.createTable(exercisesTable);
          }
          if (from < 4) {
            // journal_entries schema extended — drop and recreate (was dead code,
            // no live rows existed before this version).
            await m.deleteTable('journal_entries');
            await m.createTable(journalEntriesTable);
          }
        },
      );
}
