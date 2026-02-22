import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../models/progress_entry.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/reminders/reminder_settings.dart';
import '../../../../core/reminders/reminder_profile_settings.dart';
import '../models/user_preferences.dart';
import '../models/training_week.dart';
import '../models/golden_day_status.dart';
import '../../../training/domain/models/training_session.dart';
import '../../../../core/time/app_clock.dart';

class DashboardProgressSnapshot {
  final bool todayCompleted;
  final int completedThisWeek;
  final bool isWeeklyQualified;
  final int weeklyTarget;
  final int dailyStreakDays;
  final int currentDay;

  const DashboardProgressSnapshot({
    required this.todayCompleted,
    required this.completedThisWeek,
    required this.isWeeklyQualified,
    required this.weeklyTarget,
    required this.dailyStreakDays,
    required this.currentDay,
  });
}

class ReminderSchedulePlan {
  final DateTime startDate;
  final HabitWindow window;
  final bool recentlyActive;

  const ReminderSchedulePlan({
    required this.startDate,
    required this.window,
    required this.recentlyActive,
  });
}

class ProgressService {
  final DatabaseService _db;
  final SyncService _sync;
  final NotificationService _notifications;
  final String _userId;
  final AppClock _clock;

  ProgressService(
    this._db,
    this._sync,
    this._userId, {
    AppClock? clock,
    NotificationService? notifications,
  })  : _clock = clock ?? AppClock(),
        _notifications = notifications ?? NotificationService();

  Future<ProgressEntry> initializeProgress() async {
    final now = _clock.now();
    final goldenDay = now.add(const Duration(days: 28));

    final entry = ProgressEntry()
      ..userId = _userId
      ..date = now
      ..currentDay = 1
      ..totalDays = 28
      ..goldenDayDate = goldenDay
      ..hasReachedGoldenDay = false
      ..lastActivityDate = now
      ..consecutiveInactiveDays = 0
      ..totalTrainingsSinceLastDisclaimer = 0
      ..lastDisclaimerAcceptedAt = null
      ..firestoreId = const Uuid().v4()
      ..needsSync = true;

    await _db.isar.writeTxn(() async {
      await _db.isar.progressEntrys.put(entry);
    });

    await _sync.addJob(
      collection: 'progress',
      docId: entry.firestoreId,
      action: 'create',
      payload: entry.toJson(),
    );

    return entry;
  }

  Future<void> recordActivity(ProgressEntry progress) async {
    final now = _clock.now();

    updateStreakAndActivity(progress, now);

    await _db.isar.writeTxn(() async {
      await _db.isar.progressEntrys.put(progress);
    });

    await _sync.addJob(
      collection: 'progress',
      docId: progress.firestoreId,
      action: 'update',
      payload: progress.toJson(),
    );

    await syncReminderSchedule(reference: now);
  }

  Future<void> syncReminderSchedule({DateTime? reference}) async {
    final prefs = await SharedPreferences.getInstance();
    final remindersEnabled = ReminderSettings.dailyRemindersEnabled(prefs);

    if (!remindersEnabled) {
      debugPrint('[Reminders] Disabled by user settings; cancelling schedule');
      await _notifications.cancelDailyRepeatingReminders();
      return;
    }

    final preferences = ReminderSettings.loadUserPreferences(prefs);
    await rescheduleAdaptiveReminders(
      preferences: preferences,
      reference: reference,
    );
  }

  @visibleForTesting
  void updateStreakAndActivity(ProgressEntry progress, DateTime now) {
    final lastActivity = progress.lastActivityDate;

    // Daily streak logic
    if (lastActivity == null) {
      progress.dailyStreak = 1;
    } else {
      final daysSinceLastActivity = now.difference(lastActivity).inDays;
      if (daysSinceLastActivity == 0) {
        // Already trained today, keep streak as is
      } else if (daysSinceLastActivity == 1) {
        progress.dailyStreak += 1;
      } else {
        progress.dailyStreak = 1;
      }
    }

    // Streak Logic
    final currentWeekStart = _getWeekStart(now);
    final storedWeekStart = progress.lastTrainingWeekStart ??
        (lastActivity != null ? _getWeekStart(lastActivity) : null);

    if (storedWeekStart == null) {
      progress.trainingsThisWeek = 1;
      progress.currentStreakWeeks = 0;
      progress.lastTrainingWeekStart = currentWeekStart;
    } else if (currentWeekStart.isAtSameMomentAs(storedWeekStart)) {
      progress.trainingsThisWeek++;
    } else {
      final diffWeeks =
          currentWeekStart.difference(storedWeekStart).inDays ~/ 7;
      final weeksBetween = diffWeeks <= 0 ? 1 : diffWeeks;
      _applyWeeklyResult(
        progress,
        trainings: progress.trainingsThisWeek,
        isConsecutiveWeek: weeksBetween == 1,
      );

      if (weeksBetween > 1) {
        for (var skipped = 1; skipped < weeksBetween; skipped++) {
          _applyWeeklyResult(
            progress,
            trainings: 0,
            isConsecutiveWeek: false,
          );
        }
      }

      progress.trainingsThisWeek = 1;
      progress.lastTrainingWeekStart = currentWeekStart;
      progress.plannedSkipsThisWeek = 0;
    }
    // Golden day should only move in whole-week increments based on weekly
    // training qualification; keep inactivity notice reset.
    progress.consecutiveInactiveDays = 0;

    progress.lastActivityDate = now;
    progress.currentDay = (progress.currentDay + 1).clamp(1, 28);
    progress.needsSync = true;
  }

  DateTime _getWeekStart(DateTime date) {
    // Monday is 1, Sunday is 7
    // Subtract (weekday - 1) days to get to Monday
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<Set<int>> _completedDayEpochsInRange(
    DateTime fromInclusive,
    DateTime toExclusive,
  ) async {
    final sessions = await _db.isar.trainingSessions
        .filter()
        .userIdEqualTo(_userId)
        .dateBetween(fromInclusive, toExclusive)
        .isCompletedEqualTo(true)
        .findAll();

    final days = <int>{};
    for (final session in sessions) {
      final dt = session.completedAt ?? session.date;
      final day = _startOfDay(dt);
      days.add(day.millisecondsSinceEpoch);
    }
    return days;
  }

  void _applyWeeklyResult(
    ProgressEntry progress, {
    required int trainings,
    required bool isConsecutiveWeek,
  }) {
    if (trainings < 3) {
      progress.goldenDayDate =
          progress.goldenDayDate.add(const Duration(days: 7));
    }

    if (trainings >= 5 && isConsecutiveWeek) {
      progress.currentStreakWeeks++;
    } else {
      progress.currentStreakWeeks = 0;
    }
  }

  Future<GoldenDayStatus> computeGoldenDayStatus({
    DateTime? reference,
  }) async {
    final now = reference ?? _clock.now();
    final progress = await getCurrentProgress();
    if (progress == null) {
      final today = _startOfDay(now);
      return GoldenDayStatus(
        goldenDayDate: today,
        hasReachedGoldenDay: false,
        trainingsInCurrentBlock: 0,
        currentBlockIndex: 0,
        trainingsByBlock: const [0, 0, 0, 0],
        isCurrentBlockQualified: false,
        isDelayed: false,
        qualifiedWeeks: 0,
        requiredQualifiedWeeks: 4,
        penaltyWeeks: 0,
      );
    }

    // Anchor weeks to the first completed training day (not the install date),
    // so users who start on any weekday are still aligned in 7-day blocks.
    // This also lets admin/test tools backfill historical trainings.
    final progressAnchor = _startOfDay(progress.date);
    final earliestCompleted = await _db.isar.trainingSessions
        .filter()
        .userIdEqualTo(_userId)
        .isCompletedEqualTo(true)
        .sortByDate()
        .findFirst();
    final earliestAnchor = earliestCompleted == null
        ? progressAnchor
        : _startOfDay(earliestCompleted.completedAt ?? earliestCompleted.date);
    final anchor = earliestAnchor.isBefore(progressAnchor)
        ? earliestAnchor
        : progressAnchor;
    final today = _startOfDay(now);
    final rangeEndExclusive = today.add(const Duration(days: 1));

    final completedSessions = await _db.isar.trainingSessions
        .filter()
        .userIdEqualTo(_userId)
        .dateBetween(anchor, rangeEndExclusive)
        .isCompletedEqualTo(true)
        .findAll();

    final currentBlockIndex =
        today.isBefore(anchor) ? 0 : (today.difference(anchor).inDays ~/ 7);

    final trainingsPerBlock = <int, Set<int>>{};
    for (final session in completedSessions) {
      final completedAt = session.completedAt ?? session.date;
      final day = _startOfDay(completedAt);
      final daysSinceAnchor = day.difference(anchor).inDays;
      if (daysSinceAnchor < 0) continue;
      final blockIndex = daysSinceAnchor ~/ 7;
      final dayKey = day.millisecondsSinceEpoch;
      (trainingsPerBlock.putIfAbsent(blockIndex, () => <int>{})).add(dayKey);
    }

    var penaltyWeeks = 0;
    var qualifiedWeeks = 0;
    for (var block = 0; block < currentBlockIndex; block++) {
      final count = trainingsPerBlock[block]?.length ?? 0;
      if (count < 3) {
        penaltyWeeks++;
      } else {
        qualifiedWeeks++;
      }
    }

    final trainingsThisBlock =
        trainingsPerBlock[currentBlockIndex]?.length ?? 0;
    final isQualified = trainingsThisBlock >= 3;
    final qualifiedIncludingCurrent = qualifiedWeeks + (isQualified ? 1 : 0);

    final baseGoldenDay = anchor.add(const Duration(days: 28));
    final goldenDayDate = baseGoldenDay.add(Duration(days: 7 * penaltyWeeks));
    final hasReachedGoldenDay = !today.isBefore(goldenDayDate);

    final trainingsByBlock = List<int>.generate(
      4,
      (i) => trainingsPerBlock[i]?.length ?? 0,
      growable: false,
    );

    return GoldenDayStatus(
      goldenDayDate: goldenDayDate,
      hasReachedGoldenDay: hasReachedGoldenDay,
      trainingsInCurrentBlock: trainingsThisBlock,
      currentBlockIndex: currentBlockIndex,
      trainingsByBlock: trainingsByBlock,
      isCurrentBlockQualified: isQualified,
      isDelayed: penaltyWeeks > 0,
      qualifiedWeeks: qualifiedIncludingCurrent,
      requiredQualifiedWeeks: 4,
      penaltyWeeks: penaltyWeeks,
    );
  }

  Future<bool> hasCompletedTrainingToday({DateTime? reference}) async {
    final now = reference ?? _clock.now();
    final today = _startOfDay(now);
    final rangeEndExclusive = today.add(const Duration(days: 1));
    final completedDays =
        await _completedDayEpochsInRange(today, rangeEndExclusive);
    if (completedDays.contains(today.millisecondsSinceEpoch)) return true;

    // Fallback for older installs where trainingSessions weren't persisted yet.
    final progress = await getCurrentProgress();
    final last = progress?.lastActivityDate;
    return last != null && _isSameDay(last, now);
  }

  Future<DashboardProgressSnapshot> buildDashboardSnapshot({
    DateTime? reference,
  }) async {
    final now = reference ?? _clock.now();
    final today = _startOfDay(now);
    final weekStart = _getWeekStart(today);
    final weekEnd = weekStart.add(const Duration(days: 7));

    final progress = await getCurrentProgress();
    final completedDays = await _completedDayEpochsInRange(weekStart, weekEnd);

    final todayCompletedFromSessions =
        completedDays.contains(today.millisecondsSinceEpoch);
    final fallbackTodayCompleted = progress?.lastActivityDate != null &&
        _isSameDay(progress!.lastActivityDate!, now);
    final todayCompleted = todayCompletedFromSessions || fallbackTodayCompleted;
    final completedThisWeek = deriveCompletedThisWeekCount(
      completedDayEpochs: completedDays,
      today: today,
      weekStart: weekStart,
      weekEnd: weekEnd,
      fallbackTodayCompleted: fallbackTodayCompleted,
    );
    final weeklyTarget = (progress?.weeklyGoal ?? 5).clamp(1, 7);

    return DashboardProgressSnapshot(
      todayCompleted: todayCompleted,
      completedThisWeek: completedThisWeek,
      isWeeklyQualified: completedThisWeek >= 3,
      weeklyTarget: weeklyTarget,
      dailyStreakDays: (progress?.dailyStreak ?? 0).clamp(0, 999),
      currentDay: (progress?.currentDay ?? 1).clamp(1, 28),
    );
  }

  @visibleForTesting
  int deriveCompletedThisWeekCount({
    required Set<int> completedDayEpochs,
    required DateTime today,
    required DateTime weekStart,
    required DateTime weekEnd,
    required bool fallbackTodayCompleted,
  }) {
    var count = completedDayEpochs.length;
    final todayEpoch = today.millisecondsSinceEpoch;
    final todayAlreadyCounted = completedDayEpochs.contains(todayEpoch);
    final isTodayInsideWeek =
        !today.isBefore(weekStart) && today.isBefore(weekEnd);

    if (!todayAlreadyCounted && fallbackTodayCompleted && isTodayInsideWeek) {
      count += 1;
    }
    return count.clamp(0, 7);
  }

  Future<void> rescheduleAdaptiveReminders({
    required UserPreferences preferences,
    DateTime? reference,
  }) async {
    if (preferences.silentMode || !preferences.dailyReminderEnabled) {
      await _notifications.cancelDailyRepeatingReminders();
      return;
    }

    final now = reference ?? _clock.now();
    final today = _startOfDay(now);
    final rangeEndExclusive = today.add(const Duration(days: 1));

    final completedToday = await _db.isar.trainingSessions
        .filter()
        .userIdEqualTo(_userId)
        .dateBetween(today, rangeEndExclusive)
        .isCompletedEqualTo(true)
        .findFirst();

    final progress = await getCurrentProgress();
    final lastActivity = progress?.lastActivityDate;
    final prefs = await SharedPreferences.getInstance();
    final cadence = ReminderProfileSettings.cadence(prefs);
    final recentlyActiveThreshold = cadence == ReminderCadence.minimal
        ? const Duration(hours: 14)
        : const Duration(hours: 10);
    final inWindowDelay = cadence == ReminderCadence.minimal
        ? const Duration(minutes: 45)
        : const Duration(minutes: 20);

    final learnedTime = await _inferRoutineTime(reference: now);
    final baseWindow = _selectWindowForTime(preferences, learnedTime);
    final plan = buildReminderSchedulePlan(
      now: now,
      baseWindow: baseWindow,
      completedToday: completedToday != null,
      lastActivity: lastActivity,
      recentlyActiveThreshold: recentlyActiveThreshold,
      inWindowDelay: inWindowDelay,
    );

    await _notifications.cancelDailyRepeatingReminders();

    final location = plan.window.locationLabel;
    final msg = location != null && location.trim().isNotEmpty
        ? 'Deine Routine wartet in $location.'
        : 'Eine kurze Einheit bringt dich weiter.';

    await _notifications.scheduleDailyRepeatingWindow(
      window: plan.window,
      quietHours: preferences.quietHours,
      firstDate: plan.startDate,
      message: msg,
    );
    debugPrint(
      '[Reminders] Scheduled daily reminder at '
      '${plan.window.start.hour.toString().padLeft(2, '0')}:'
      '${plan.window.start.minute.toString().padLeft(2, '0')} '
      '(startDate=${plan.startDate.toIso8601String()}, '
      'completedToday=${completedToday != null}, recentlyActive=${plan.recentlyActive}, '
      'cadence=${cadence.name})',
    );
  }

  @visibleForTesting
  ReminderSchedulePlan buildReminderSchedulePlan({
    required DateTime now,
    required HabitWindow baseWindow,
    required bool completedToday,
    required DateTime? lastActivity,
    required Duration recentlyActiveThreshold,
    required Duration inWindowDelay,
  }) {
    final today = _startOfDay(now);

    final recentlyActive = lastActivity != null &&
        now.difference(lastActivity) < recentlyActiveThreshold;

    if (completedToday || recentlyActive) {
      return ReminderSchedulePlan(
        startDate: today.add(const Duration(days: 1)),
        window: baseWindow,
        recentlyActive: recentlyActive,
      );
    }

    final windowStart = DateTime(
      now.year,
      now.month,
      now.day,
      baseWindow.start.hour,
      baseWindow.start.minute,
    );
    final windowEnd = DateTime(
      now.year,
      now.month,
      now.day,
      baseWindow.end.hour,
      baseWindow.end.minute,
    );

    if (!now.isBefore(windowEnd)) {
      return ReminderSchedulePlan(
        startDate: today.add(const Duration(days: 1)),
        window: baseWindow,
        recentlyActive: false,
      );
    }

    if (!now.isBefore(windowStart) && now.isBefore(windowEnd)) {
      final delayed = now.add(inWindowDelay);
      return ReminderSchedulePlan(
        startDate: today,
        window: HabitWindow(
          start: TimeOfDay(hour: delayed.hour, minute: delayed.minute),
          end: baseWindow.end,
          locationLabel: baseWindow.locationLabel,
        ),
        recentlyActive: false,
      );
    }

    return ReminderSchedulePlan(
      startDate: today,
      window: baseWindow,
      recentlyActive: false,
    );
  }

  Future<TimeOfDay> _inferRoutineTime({
    DateTime? reference,
    int lookbackDays = 21,
    int maxSamples = 12,
  }) async {
    final now = reference ?? _clock.now();
    final today = _startOfDay(now);
    final from = today.subtract(Duration(days: lookbackDays));
    final to = today.add(const Duration(days: 1));

    final sessions = await _db.isar.trainingSessions
        .filter()
        .userIdEqualTo(_userId)
        .dateBetween(from, to)
        .isCompletedEqualTo(true)
        .sortByDateDesc()
        .findAll();

    if (sessions.isEmpty) {
      return const TimeOfDay(hour: 8, minute: 0);
    }

    final minutes = <int>[];
    for (final session in sessions.take(maxSamples)) {
      final completedAt = session.completedAt ?? session.date;
      minutes.add(completedAt.hour * 60 + completedAt.minute);
    }
    minutes.sort();
    final median = minutes[minutes.length ~/ 2];
    final hour = median ~/ 60;
    final minute = median % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  HabitWindow _selectWindowForTime(
      UserPreferences preferences, TimeOfDay time) {
    if (preferences.preferredWindows.isEmpty) {
      final end = _addMinutes(time, 120);
      return HabitWindow(start: time, end: end);
    }

    final targetMinutes = time.hour * 60 + time.minute;
    HabitWindow? best;
    var bestDistance = 1 << 30;

    for (final window in preferences.preferredWindows) {
      final startMinutes = window.start.hour * 60 + window.start.minute;
      final endMinutes = window.end.hour * 60 + window.end.minute;
      final within =
          targetMinutes >= startMinutes && targetMinutes <= endMinutes;
      final distance =
          within ? 0 : (targetMinutes - startMinutes).abs().clamp(0, 24 * 60);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = window;
      }
    }

    return best!;
  }

  TimeOfDay _addMinutes(TimeOfDay start, int minutesToAdd) {
    final total = (start.hour * 60 + start.minute + minutesToAdd) % (24 * 60);
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  Future<ProgressEntry?> getCurrentProgress() async {
    return await _db.isar.progressEntrys
        .filter()
        .userIdEqualTo(_userId)
        .sortByDateDesc()
        .findFirst();
  }

  Future<void> recordTrainingSession(String userId) async {
    // Get or create progress entry
    final now = _clock.now();
    var progress = await _db.isar.progressEntrys
        .filter()
        .userIdEqualTo(userId)
        .sortByDateDesc()
        .findFirst();

    // Initialize progress if it doesn't exist
    progress ??= await initializeProgress();

    final dayNumberBefore = progress.currentDay.clamp(1, 28);
    final alreadyDoneToday = progress.lastActivityDate != null &&
        progress.lastActivityDate!.year == now.year &&
        progress.lastActivityDate!.month == now.month &&
        progress.lastActivityDate!.day == now.day;

    // If the user already trained today, don't count it twice.
    if (!alreadyDoneToday) {
      await recordActivity(progress);
    }

    // Ensure a completed TrainingSession exists for "today" so the dashboard
    // and golden-day logic can count unique days.
    await _upsertCompletedTrainingSession(
      dayNumber: dayNumberBefore,
      completedAt: now,
    );
  }

  Future<void> _upsertCompletedTrainingSession({
    required int dayNumber,
    required DateTime completedAt,
  }) async {
    final day = _startOfDay(completedAt);
    final rangeEndExclusive = day.add(const Duration(days: 1));

    final existing = await _db.isar.trainingSessions
        .filter()
        .userIdEqualTo(_userId)
        .dateBetween(day, rangeEndExclusive)
        .findFirst();

    if (existing != null && existing.isCompleted) {
      return;
    }

    final session = existing ??
        (TrainingSession()
          ..userId = _userId
          ..date = day
          ..dayNumber = dayNumber
          ..exercisePackage = 'core'
          ..completedExercises = const <String>[]
          ..isCompleted = true
          ..completedAt = completedAt
          ..firestoreId = const Uuid().v4()
          ..needsSync = true);

    if (existing != null) {
      session
        ..date = day
        ..dayNumber = dayNumber
        ..isCompleted = true
        ..completedAt = completedAt
        ..needsSync = true;
    }

    await _db.isar.writeTxn(() async {
      await _db.isar.trainingSessions.put(session);
    });

    await _sync.addJob(
      collection: 'trainingSessions',
      docId: session.firestoreId,
      action: existing == null ? 'create' : 'update',
      payload: {
        'userId': session.userId,
        'date': session.date.toIso8601String(),
        'dayNumber': session.dayNumber,
        'exercisePackage': session.exercisePackage,
        'completedExercises': session.completedExercises,
        'isCompleted': session.isCompleted,
        'completedAt': session.completedAt?.toIso8601String(),
      },
    );
  }

  Future<void> debugDeleteTrainingSessionForDay(DateTime day) async {
    final normalized = _startOfDay(day);
    final rangeEndExclusive = normalized.add(const Duration(days: 1));
    final existing = await _db.isar.trainingSessions
        .filter()
        .userIdEqualTo(_userId)
        .dateBetween(normalized, rangeEndExclusive)
        .findFirst();
    if (existing == null) return;

    await _db.isar.writeTxn(() async {
      await _db.isar.trainingSessions.delete(existing.id);
    });
  }

  Future<void> debugSetTrainingSessionForDay(DateTime day) async {
    final normalized = _startOfDay(day);
    final progress = await getCurrentProgress();
    final anchor = progress == null ? normalized : _startOfDay(progress.date);
    final dayNumber = (normalized.difference(anchor).inDays + 1).clamp(1, 28);

    // Use a stable midday completion time for consistency.
    final completedAt = DateTime(
      normalized.year,
      normalized.month,
      normalized.day,
      12,
      0,
      0,
    );

    await _upsertCompletedTrainingSession(
      dayNumber: dayNumber,
      completedAt: completedAt,
    );
  }

  Future<bool> debugHasTrainingSessionForDay(DateTime day) async {
    final normalized = _startOfDay(day);
    final rangeEndExclusive = normalized.add(const Duration(days: 1));
    final existing = await _db.isar.trainingSessions
        .filter()
        .userIdEqualTo(_userId)
        .dateBetween(normalized, rangeEndExclusive)
        .isCompletedEqualTo(true)
        .findFirst();
    return existing != null;
  }

  Future<Set<int>> debugCompletedDayEpochsInRange(
    DateTime fromInclusive,
    DateTime toExclusive,
  ) async {
    final sessions = await _db.isar.trainingSessions
        .filter()
        .userIdEqualTo(_userId)
        .dateBetween(fromInclusive, toExclusive)
        .isCompletedEqualTo(true)
        .findAll();

    final days = <int>{};
    for (final s in sessions) {
      final dt = s.completedAt ?? s.date;
      final d = _startOfDay(dt);
      days.add(d.millisecondsSinceEpoch);
    }
    return days;
  }

  Future<void> debugClearAllTrainingSessions() async {
    await _db.isar.writeTxn(() async {
      await _db.isar.trainingSessions
          .filter()
          .userIdEqualTo(_userId)
          .deleteAll();
    });
  }

  Future<void> registerPlannedSkip(ProgressEntry progress) async {
    final now = _clock.now();
    final currentWeekStart = _getWeekStart(now);

    if (progress.lastTrainingWeekStart == null ||
        !progress.lastTrainingWeekStart!.isAtSameMomentAs(currentWeekStart)) {
      progress.plannedSkipsThisWeek = 0;
      progress.lastTrainingWeekStart = currentWeekStart;
    }

    if (progress.plannedSkipsThisWeek < 1) {
      progress.plannedSkipsThisWeek += 1;
      progress.needsSync = true;

      await _db.isar.writeTxn(() async {
        await _db.isar.progressEntrys.put(progress);
      });

      await _sync.addJob(
        collection: 'progress',
        docId: progress.firestoreId,
        action: 'update',
        payload: progress.toJson(),
      );
    }
  }

  Future<WeeklyProgressOverview> buildWeeklyOverview({
    DateTime? reference,
    UserPreferences? preferences,
  }) async {
    final now = reference ?? _clock.now();
    final progress = await getCurrentProgress();
    final today = _startOfDay(now);
    final weeklyTarget = progress?.weeklyGoal ?? 5;

    final recentWindowStart = today.subtract(const Duration(days: 6));
    final recentWindowEnd = today.add(const Duration(days: 1));

    final recentCompletedSessions = await _db.isar.trainingSessions
        .filter()
        .userIdEqualTo(_userId)
        .dateBetween(recentWindowStart, recentWindowEnd)
        .isCompletedEqualTo(true)
        .findAll();

    DateTime weekStart;
    if (recentCompletedSessions.isEmpty) {
      weekStart = today;
    } else {
      recentCompletedSessions.sort((a, b) {
        final aDate = a.completedAt ?? a.date;
        final bDate = b.completedAt ?? b.date;
        return aDate.compareTo(bDate);
      });
      final firstSessionDate = recentCompletedSessions.first.completedAt ??
          recentCompletedSessions.first.date;
      final normalizedFirst = _startOfDay(firstSessionDate);
      weekStart = normalizedFirst.isAfter(today) ? today : normalizedFirst;
    }

    final weekEnd = weekStart.add(const Duration(days: 7));

    final List<TrainingSession> sessions = await _db.isar.trainingSessions
        .filter()
        .userIdEqualTo(_userId)
        .dateBetween(weekStart, weekEnd)
        .findAll();

    final days = <TrainingDayStatus>[];
    for (var i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final completed = sessions.any((session) {
        final completedAt = session.completedAt ?? session.date;
        return completedAt.year == date.year &&
            completedAt.month == date.month &&
            completedAt.day == date.day &&
            session.isCompleted;
      });

      final window = preferences?.primaryWindowForWeekday(date.weekday);
      days.add(
        TrainingDayStatus(
          date: date,
          completed: completed,
          plannedSkip: (progress?.plannedSkipsThisWeek ?? 0) > 0 && !completed,
          predictedWindow: window,
          locationLabel: window?.locationLabel,
        ),
      );
    }

    return WeeklyProgressOverview(
      weekStart: weekStart,
      days: days,
      targetCount: weeklyTarget,
      weeklyStreakWeeks: progress?.currentStreakWeeks ?? 0,
      dailyStreakDays: progress?.dailyStreak ?? 0,
      plannedSkips: progress?.plannedSkipsThisWeek ?? 0,
    );
  }

  /// Check if disclaimer should be shown
  /// Shows on first training and every 7th training thereafter
  bool shouldShowDisclaimer(ProgressEntry progress) {
    // Show on first training (no previous acceptance)
    if (progress.lastDisclaimerAcceptedAt == null) {
      return true;
    }

    // Show every 7th training
    if (progress.totalTrainingsSinceLastDisclaimer >= 7) {
      return true;
    }

    return false;
  }

  /// Record disclaimer acceptance
  Future<void> recordDisclaimerAcceptance(ProgressEntry progress) async {
    progress.lastDisclaimerAcceptedAt = _clock.now();
    progress.totalTrainingsSinceLastDisclaimer = 0;
    progress.needsSync = true;

    await _db.isar.writeTxn(() async {
      await _db.isar.progressEntrys.put(progress);
    });

    await _sync.addJob(
      collection: 'progress',
      docId: progress.firestoreId,
      action: 'update',
      payload: progress.toJson(),
    );
  }

  /// Increment disclaimer counter when training is completed
  Future<void> incrementDisclaimerCounter(ProgressEntry progress) async {
    progress.totalTrainingsSinceLastDisclaimer += 1;
    progress.needsSync = true;

    await _db.isar.writeTxn(() async {
      await _db.isar.progressEntrys.put(progress);
    });

    await _sync.addJob(
      collection: 'progress',
      docId: progress.firestoreId,
      action: 'update',
      payload: progress.toJson(),
    );
  }
}

extension ProgressEntryJson on ProgressEntry {
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'currentDay': currentDay,
      'totalDays': totalDays,
      'goldenDayDate': goldenDayDate.toIso8601String(),
      'hasReachedGoldenDay': hasReachedGoldenDay,
      'lastActivityDate': lastActivityDate?.toIso8601String(),
      'consecutiveInactiveDays': consecutiveInactiveDays,
      'totalTrainingsSinceLastDisclaimer': totalTrainingsSinceLastDisclaimer,
      'lastDisclaimerAcceptedAt': lastDisclaimerAcceptedAt?.toIso8601String(),
      'currentStreakWeeks': currentStreakWeeks,
      'trainingsThisWeek': trainingsThisWeek,
      'lastTrainingWeekStart': lastTrainingWeekStart?.toIso8601String(),
      'dailyStreak': dailyStreak,
      'plannedSkipsThisWeek': plannedSkipsThisWeek,
      'weeklyGoal': weeklyGoal,
    };
  }
}
