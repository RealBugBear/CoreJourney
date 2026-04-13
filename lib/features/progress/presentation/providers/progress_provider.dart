import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _uuid = Uuid();

DateTime _weekStart(DateTime date) {
  return DateTime(date.year, date.month, date.day - (date.weekday - 1));
}

// ── Selected package (persisted to SharedPreferences, scoped per user) ───────
//
// Key format: 'selected_package_id_<userId>'
// This prevents user A's package selection from leaking into user B's session
// after a sign-out/sign-in within the same app lifetime or across reinstalls.
// When authStateProvider changes (sign-out/sign-in), Riverpod re-creates the
// notifier with the new userId, reading the correct user-scoped key.

class _SelectedPackageNotifier extends StateNotifier<String> {
  static String _prefKey(String? userId) =>
      userId != null ? 'selected_package_id_$userId' : 'selected_package_id';

  final SharedPreferences _prefs;
  final String _storageKey;

  _SelectedPackageNotifier(this._prefs, String? userId)
      : _storageKey = _prefKey(userId),
        super(_prefs.getString(_prefKey(userId)) ?? 'moro');

  void select(String packageId) {
    state = packageId;
    _prefs.setString(_storageKey, packageId);
  }
}

final selectedPackageIdProvider =
    StateNotifierProvider<_SelectedPackageNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  // Watch auth state so the notifier is re-created on sign-out/sign-in,
  // loading the correct user-scoped key from SharedPreferences.
  final userId = ref.watch(authStateProvider).valueOrNull?.session?.user.id
      ?? Supabase.instance.client.auth.currentUser?.id;
  return _SelectedPackageNotifier(prefs, userId);
});

// ── Active enrollment (for the currently selected package) ────────────────────

final activeEnrollmentProvider =
    StreamProvider<EnrollmentsTableData?>((ref) {
  final db = ref.watch(databaseProvider);
  // Watch auth state so this provider re-evaluates when the user changes.
  final userId = ref.watch(authStateProvider).valueOrNull?.session?.user.id
      ?? Supabase.instance.client.auth.currentUser?.id;
  final packageId = ref.watch(selectedPackageIdProvider);
  if (userId == null) return Stream.value(null);

  return (db.select(db.enrollmentsTable)
        ..where((t) =>
            t.userId.equals(userId) &
            t.packageId.equals(packageId) &
            t.status.equals('active'))
        ..limit(1))
      .watchSingleOrNull();
});

// ── Active progress entry ─────────────────────────────────────────────────────

final activeProgressProvider =
    StreamProvider<ProgressEntriesTableData?>((ref) {
  final db = ref.watch(databaseProvider);
  final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
  if (enrollment == null) return Stream.value(null);

  return (db.select(db.progressEntriesTable)
        ..where((t) => t.enrollmentId.equals(enrollment.id))
        ..limit(1))
      .watchSingleOrNull();
});

// ── Sessions completed this week ──────────────────────────────────────────────

final thisWeekSessionsProvider =
    StreamProvider<List<TrainingSessionsTableData>>((ref) {
  final db = ref.watch(databaseProvider);
  final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
  if (enrollment == null) return Stream.value([]);

  final weekStart = _weekStart(DateTime.now());

  return (db.select(db.trainingSessionsTable)
        ..where((t) =>
            t.enrollmentId.equals(enrollment.id) &
            t.sessionDate.isBiggerOrEqualValue(weekStart) &
            t.isCompleted.equals(true)))
      .watch();
});

// ── Create enrollment after intake assessment ─────────────────────────────────

// ── Create enrollment — idempotent on both local DB and Supabase ──────────────
//
// Idempotenz-Strategie (zwei Ebenen):
//   1. Lokale DB: prüfe vor dem Insert, ob bereits ein aktives Enrollment
//      für (userId, packageId) existiert → return early.
//   2. Supabase: SyncService nutzt UPSERT. Supabase hat zusätzlich einen
//      UNIQUE-Partial-Index auf (user_id, package_id) WHERE status='active'
//      (siehe supabase/idempotency_constraints.sql). Ein doppelter UPSERT
//      mit identischer enrollmentId ist ein No-op; eine andere ID schlägt
//      mit UniqueViolation fehl → verhindert Datenverlust.
//
// Sonderfall fresh device: Wenn die lokale DB leer ist (nach Reinstall),
// schlägt der lokale Check fehl und ein neues Enrollment wird erstellt.
// Der nachfolgende Supabase-UPSERT ÜBERSCHREIBT das existierende Enrollment
// NICHT (dank UNIQUE Index). Stattdessen schlägt er mit einem Conflict-Fehler
// fehl, der im SyncService als retry-fähiger Fehler behandelt wird.
// rehydrate() wird bei sign-in aufgerufen und lädt das echte Enrollment vor
// dem Intake-Assessment in die lokale DB, sodass der lokale Check greift.
Future<void> createEnrollment({
  required AppDatabase db,
  required SyncService syncService,
  required String userId,
  required String packageId,
  required int durationWeeks,
}) async {
  // Lokaler Idempotenz-Check — verhindert Duplicate in der Drift-DB.
  // Auf frischen Geräten ist die DB leer; rehydrate() lädt das Server-Enrollment
  // vor Ausführung dieser Funktion, sodass dieser Check auch dann greift.
  final existing = await (db.select(db.enrollmentsTable)
        ..where((t) =>
            t.userId.equals(userId) &
            t.packageId.equals(packageId) &
            t.status.equals('active'))
        ..limit(1))
      .getSingleOrNull();
  if (existing != null) return;

  final now = DateTime.now();
  final enrollmentId = _uuid.v4();
  final progressId = _uuid.v4();
  final target = now.add(Duration(days: durationWeeks * 7));

  await db.into(db.enrollmentsTable).insert(
        EnrollmentsTableCompanion.insert(
          id: enrollmentId,
          userId: userId,
          packageId: packageId,
          assignedDurationWeeks: durationWeeks,
          startDate: DateTime(now.year, now.month, now.day),
          targetCompletionDate:
              DateTime(target.year, target.month, target.day),
        ),
      );

  await db.into(db.progressEntriesTable).insert(
        ProgressEntriesTableCompanion.insert(
          id: progressId,
          userId: userId,
          enrollmentId: enrollmentId,
        ),
      );

  await syncService.enqueueUpsert(
    tableName: 'enrollments',
    recordId: enrollmentId,
    payload: {
      'id': enrollmentId,
      'user_id': userId,
      'package_id': packageId,
      'status': 'active',
      'assigned_duration_weeks': durationWeeks,
      'start_date': now.toIso8601String().substring(0, 10),
      'target_completion_date': target.toIso8601String().substring(0, 10),
    },
  );
  await syncService.enqueueUpsert(
    tableName: 'progress_entries',
    recordId: progressId,
    payload: {
      'id': progressId,
      'user_id': userId,
      'enrollment_id': enrollmentId,
      'current_day': 1,
    },
  );
}

// ── All enrollments for the current user (all packages) ──────────────────────

final allUserEnrollmentsProvider =
    StreamProvider<List<EnrollmentsTableData>>((ref) {
  final db = ref.watch(databaseProvider);
  final userId = ref.watch(authStateProvider).valueOrNull?.session?.user.id
      ?? Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value([]);

  return (db.select(db.enrollmentsTable)
        ..where((t) => t.userId.equals(userId)))
      .watch();
});

// ── Completion questionnaire ready? ──────────────────────────────────────────

final completionReadyProvider = Provider<bool>((ref) {
  final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
  if (enrollment == null || enrollment.status != 'active') return false;
  final today = DateTime.now();
  final target = enrollment.targetCompletionDate;
  // Ready when today is on or after the target date
  return !DateTime(today.year, today.month, today.day)
      .isBefore(DateTime(target.year, target.month, target.day));
});

// ── Complete enrollment (questionnaire passed) ────────────────────────────────

Future<void> completeEnrollment({
  required AppDatabase db,
  required SyncService syncService,
  required EnrollmentsTableData enrollment,
}) async {
  final now = DateTime.now();
  await (db.update(db.enrollmentsTable)
        ..where((t) => t.id.equals(enrollment.id)))
      .write(EnrollmentsTableCompanion(
    status: const drift.Value('completed'),
    completedAt: drift.Value(now),
    needsSync: const drift.Value(true),
    updatedAt: drift.Value(now),
  ));

  final qId = _uuid.v4();
  await db.into(db.completionQuestionnairesTable).insert(
        CompletionQuestionnairesTableCompanion.insert(
          id: qId,
          enrollmentId: enrollment.id,
          response: true,
          result: 'passed',
          submittedAt: now,
        ),
      );

  await syncService.enqueueUpsert(
    tableName: 'enrollments',
    recordId: enrollment.id,
    payload: {
      'id': enrollment.id,
      'status': 'completed',
      'completed_at': now.toIso8601String(),
    },
  );
  await syncService.enqueueUpsert(
    tableName: 'completion_questionnaires',
    recordId: qId,
    payload: {
      'id': qId,
      'enrollment_id': enrollment.id,
      'attempt_number': 1,
      'response': true,
      'result': 'passed',
      'submitted_at': now.toIso8601String(),
    },
  );
}

// ── Extend enrollment by N days (questionnaire not yet passed) ────────────────

Future<void> extendEnrollment({
  required AppDatabase db,
  required SyncService syncService,
  required EnrollmentsTableData enrollment,
  int days = 7,
}) async {
  final now = DateTime.now();
  final newTarget = enrollment.targetCompletionDate.add(Duration(days: days));

  await (db.update(db.enrollmentsTable)
        ..where((t) => t.id.equals(enrollment.id)))
      .write(EnrollmentsTableCompanion(
    targetCompletionDate: drift.Value(newTarget),
    needsSync: const drift.Value(true),
    updatedAt: drift.Value(now),
  ));

  final qId = _uuid.v4();
  // Record the "not yet" attempt
  final existing = await (db.select(db.completionQuestionnairesTable)
        ..where((t) => t.enrollmentId.equals(enrollment.id))
        ..orderBy([(t) => drift.OrderingTerm.desc(t.submittedAt)])
        ..limit(1))
      .getSingleOrNull();
  final attempt = (existing?.attemptNumber ?? 0) + 1;

  await db.into(db.completionQuestionnairesTable).insert(
        CompletionQuestionnairesTableCompanion.insert(
          id: qId,
          enrollmentId: enrollment.id,
          attemptNumber: drift.Value(attempt),
          response: false,
          result: 'extend',
          submittedAt: now,
        ),
      );

  await syncService.enqueueUpsert(
    tableName: 'enrollments',
    recordId: enrollment.id,
    payload: {
      'id': enrollment.id,
      'target_completion_date': newTarget.toIso8601String().substring(0, 10),
    },
  );
  await syncService.enqueueUpsert(
    tableName: 'completion_questionnaires',
    recordId: qId,
    payload: {
      'id': qId,
      'enrollment_id': enrollment.id,
      'attempt_number': attempt,
      'response': false,
      'result': 'extend',
      'submitted_at': now.toIso8601String(),
    },
  );
}

// ── Save a completed session and update progress ──────────────────────────────

Future<void> saveCompletedSession({
  required AppDatabase db,
  required SyncService syncService, // SyncService
  required EnrollmentsTableData enrollment,
  required ProgressEntriesTableData progress,
  required List<String> completedExerciseIds,
}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sessionId = _uuid.v4();

  // Save session
  await db.into(db.trainingSessionsTable).insert(
        TrainingSessionsTableCompanion.insert(
          id: sessionId,
          userId: userId,
          enrollmentId: enrollment.id,
          sessionDate: today,
          dayNumber: progress.currentDay,
          completedExerciseIds: jsonEncode(completedExerciseIds),
          isCompleted: const drift.Value(true),
          completedAt: drift.Value(now),
        ),
      );

  // Idempotency: skip if already recorded today
  final lastActivity = progress.lastActivityDate;
  final isToday = lastActivity != null &&
      lastActivity.year == today.year &&
      lastActivity.month == today.month &&
      lastActivity.day == today.day;
  if (isToday) return;

  final yesterday = today.subtract(const Duration(days: 1));

  // Daily streak
  int newDailyStreak = progress.dailyStreak;
  if (lastActivity == null ||
      (lastActivity.year == yesterday.year &&
          lastActivity.month == yesterday.month &&
          lastActivity.day == yesterday.day)) {
    newDailyStreak++;
  } else {
    newDailyStreak = 1;
  }

  // Weekly stats
  final thisWeekStart = _weekStart(today);
  final lastWeekStart = progress.lastTrainingWeekStart;
  final isNewWeek =
      lastWeekStart == null || lastWeekStart.isBefore(thisWeekStart);
  final newTrainingsThisWeek = isNewWeek ? 1 : progress.trainingsThisWeek + 1;

  // Weekly streak: increment when a new week hits the goal
  int newWeeklyStreak = progress.weeklyStreak;
  if (newTrainingsThisWeek >= progress.weeklyGoal && isNewWeek) {
    newWeeklyStreak++;
  }

  await (db.update(db.progressEntriesTable)
        ..where((t) => t.id.equals(progress.id)))
      .write(ProgressEntriesTableCompanion(
    currentDay: drift.Value(progress.currentDay + 1),
    lastActivityDate: drift.Value(today),
    consecutiveInactiveDays: const drift.Value(0),
    dailyStreak: drift.Value(newDailyStreak),
    weeklyStreak: drift.Value(newWeeklyStreak),
    trainingsThisWeek: drift.Value(newTrainingsThisWeek),
    lastTrainingWeekStart: drift.Value(thisWeekStart),
    totalSessionsSinceDisclaimer:
        drift.Value(progress.totalSessionsSinceDisclaimer + 1),
    needsSync: const drift.Value(true),
    updatedAt: drift.Value(now),
  ));

  await syncService.enqueueUpsert(
    tableName: 'training_sessions',
    recordId: sessionId,
    payload: {
      'id': sessionId,
      'user_id': userId,
      'enrollment_id': enrollment.id,
      'session_date': today.toIso8601String().substring(0, 10),
      'day_number': progress.currentDay,
      'completed_exercise_ids': completedExerciseIds,
      'is_completed': true,
      'completed_at': now.toIso8601String(),
    },
  );
  await syncService.enqueueUpsert(
    tableName: 'progress_entries',
    recordId: progress.id,
    payload: {
      'id': progress.id,
      'user_id': userId,
      'enrollment_id': enrollment.id,
      'current_day': progress.currentDay + 1,
      'last_activity_date': today.toIso8601String().substring(0, 10),
      'daily_streak': newDailyStreak,
      'weekly_streak': newWeeklyStreak,
      'trainings_this_week': newTrainingsThisWeek,
    },
  );
}
