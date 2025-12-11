import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../models/progress_entry.dart';
import '../../../../core/services/notification_service.dart';
import '../models/user_preferences.dart';
import '../models/training_week.dart';
import '../../../training/domain/models/training_session.dart';

class ProgressService {
  final DatabaseService _db;
  final SyncService _sync;
  final NotificationService _notifications;
  final String _userId;

  ProgressService(
    this._db,
    this._sync,
    this._userId, {
    NotificationService? notifications,
  }) : _notifications = notifications ?? NotificationService();

  Future<ProgressEntry> initializeProgress() async {
    final now = DateTime.now();
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
    final now = DateTime.now();
    
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

    // Schedule notification for tomorrow
    await _notifications.scheduleDailyReminder(now);
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
    final lastWeekStart = progress.lastTrainingWeekStart ?? (lastActivity != null ? _getWeekStart(lastActivity) : null);

    if (lastWeekStart == null) {
      // First ever training
      progress.trainingsThisWeek = 1;
      progress.currentStreakWeeks = 0;
      progress.lastTrainingWeekStart = currentWeekStart;
    } else if (currentWeekStart.isAtSameMomentAs(lastWeekStart)) {
      // Same week
      progress.trainingsThisWeek++;
    } else {
      // New week
      // Check if previous week was successful (>= 5 trainings)
      // AND if the new week is consecutive (next week)
      final isConsecutiveWeek = currentWeekStart.difference(lastWeekStart).inDays == 7;
      
      if (progress.trainingsThisWeek >= 5 && isConsecutiveWeek) {
        progress.currentStreakWeeks++;
      } else {
        progress.currentStreakWeeks = 0;
      }

      progress.trainingsThisWeek = 1;
      progress.lastTrainingWeekStart = currentWeekStart;
      progress.plannedSkipsThisWeek = 0;
    }

    if (lastActivity != null) {
      final daysSinceLastActivity = now.difference(lastActivity).inDays;

      // Inactivity logic - kulante Zielverschiebung
      if (daysSinceLastActivity >= 7) {
        // Shift golden day by 7 days (one-time)
        if (progress.consecutiveInactiveDays == 0) {
          progress.goldenDayDate = progress.goldenDayDate.add(const Duration(days: 7));
        }
        
        // Continue shifting daily
        progress.goldenDayDate = progress.goldenDayDate.add(Duration(days: daysSinceLastActivity - 7));
        progress.consecutiveInactiveDays = daysSinceLastActivity;
      } else {
        progress.consecutiveInactiveDays = 0;
      }
    }

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

  Future<ProgressEntry?> getCurrentProgress() async {
    return await _db.isar.progressEntrys
        .filter()
        .userIdEqualTo(_userId)
        .sortByDateDesc()
        .findFirst();
  }

  Future<void> recordTrainingSession(String userId) async {
    // Get or create progress entry
    var progress = await _db.isar.progressEntrys
        .filter()
        .userIdEqualTo(userId)
        .sortByDateDesc()
        .findFirst();

    if (progress == null) {
      // Initialize progress if it doesn't exist
      progress = await initializeProgress();
    }

    // Record the activity
    await recordActivity(progress);
  }

  Future<void> registerPlannedSkip(ProgressEntry progress) async {
    final now = DateTime.now();
    final currentWeekStart = _getWeekStart(now);

    if (progress.lastTrainingWeekStart == null || !progress.lastTrainingWeekStart!.isAtSameMomentAs(currentWeekStart)) {
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
    final now = reference ?? DateTime.now();
    final weekStart = _getWeekStart(now);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final progress = await getCurrentProgress();
    final weeklyTarget = progress?.weeklyGoal ?? 5;

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
          plannedSkip: progress?.plannedSkipsThisWeek > 0 && !completed,
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
    progress.lastDisclaimerAcceptedAt = DateTime.now();
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
