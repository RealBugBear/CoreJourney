import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:corejourney/features/progress/domain/services/progress_service.dart';
import 'package:corejourney/features/progress/domain/models/progress_entry.dart';
import 'package:corejourney/core/database/database_service.dart';
import 'package:corejourney/core/sync/sync_service.dart';

import 'package:corejourney/core/services/notification_service.dart';
import 'package:corejourney/core/time/app_clock.dart';
import 'package:corejourney/features/progress/domain/models/user_preferences.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockSyncService extends Mock implements SyncService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late ProgressService progressService;
  late MockDatabaseService mockDb;
  late MockSyncService mockSync;
  late MockNotificationService mockNotifications;

  setUp(() {
    mockDb = MockDatabaseService();
    mockSync = MockSyncService();
    mockNotifications = MockNotificationService();

    // Mock scheduleDailyReminder to do nothing
    when(() => mockNotifications.scheduleDailyReminder(any()))
        .thenAnswer((_) async {});

    progressService = ProgressService(
      mockDb,
      mockSync,
      'test_user',
      clock: AppClock(),
      notifications: mockNotifications,
    );
  });

  group('Streak Logic', () {
    test('First training initializes streak', () {
      final entry = ProgressEntry()
        ..date = DateTime(2023, 1, 1)
        ..currentDay = 1
        ..totalDays = 28
        ..goldenDayDate = DateTime(2023, 1, 28)
        ..hasReachedGoldenDay = false
        ..consecutiveInactiveDays = 0
        ..totalTrainingsSinceLastDisclaimer = 0
        ..firestoreId = 'id'
        ..needsSync = false;

      final now = DateTime(2023, 1, 1); // Sunday
      progressService.updateStreakAndActivity(entry, now);

      expect(entry.trainingsThisWeek, 1);
      expect(entry.currentStreakWeeks, 0);
      expect(
          entry.lastTrainingWeekStart, DateTime(2022, 12, 26)); // Monday before
    });

    test('Training in same week increments counter', () {
      final now = DateTime(2023, 1, 2); // Monday
      final entry = ProgressEntry()
        ..date = DateTime(2023, 1, 1)
        ..currentDay = 1
        ..totalDays = 28
        ..goldenDayDate = DateTime(2023, 1, 28)
        ..hasReachedGoldenDay = false
        ..consecutiveInactiveDays = 0
        ..totalTrainingsSinceLastDisclaimer = 0
        ..firestoreId = 'id'
        ..needsSync = false
        ..trainingsThisWeek = 1
        ..currentStreakWeeks = 0
        ..lastTrainingWeekStart = DateTime(2023, 1, 2) // Same week start
        ..lastActivityDate = DateTime(2023, 1, 2);

      progressService.updateStreakAndActivity(entry, now);

      expect(entry.trainingsThisWeek, 2);
      expect(entry.currentStreakWeeks, 0);
    });

    test('New week with >= 5 trainings increments streak', () {
      // Last week: 5 trainings.
      // New week: consecutive.
      final lastWeekStart = DateTime(2023, 1, 2); // Monday
      final now = DateTime(2023, 1, 9); // Next Monday

      final entry = ProgressEntry()
        ..date = DateTime(2023, 1, 1)
        ..currentDay = 1
        ..totalDays = 28
        ..goldenDayDate = DateTime(2023, 1, 28)
        ..hasReachedGoldenDay = false
        ..consecutiveInactiveDays = 0
        ..totalTrainingsSinceLastDisclaimer = 0
        ..firestoreId = 'id'
        ..needsSync = false
        ..trainingsThisWeek = 5
        ..currentStreakWeeks = 0
        ..lastTrainingWeekStart = lastWeekStart
        ..lastActivityDate = DateTime(2023, 1, 8); // Sunday

      progressService.updateStreakAndActivity(entry, now);

      expect(entry.trainingsThisWeek, 1);
      expect(entry.currentStreakWeeks, 1);
      expect(entry.lastTrainingWeekStart, now);
    });

    test('New week with < 5 trainings resets streak', () {
      // Last week: 4 trainings.
      // New week: consecutive.
      final lastWeekStart = DateTime(2023, 1, 2); // Monday
      final now = DateTime(2023, 1, 9); // Next Monday

      final entry = ProgressEntry()
        ..date = DateTime(2023, 1, 1)
        ..currentDay = 1
        ..totalDays = 28
        ..goldenDayDate = DateTime(2023, 1, 28)
        ..hasReachedGoldenDay = false
        ..consecutiveInactiveDays = 0
        ..totalTrainingsSinceLastDisclaimer = 0
        ..firestoreId = 'id'
        ..needsSync = false
        ..trainingsThisWeek = 4
        ..currentStreakWeeks = 10
        ..lastTrainingWeekStart = lastWeekStart
        ..lastActivityDate = DateTime(2023, 1, 8); // Sunday

      progressService.updateStreakAndActivity(entry, now);

      expect(entry.trainingsThisWeek, 1);
      expect(entry.currentStreakWeeks, 0); // Reset
    });

    test('Skipped week resets streak', () {
      // Last week: 5 trainings.
      // New week: NOT consecutive (gap).
      final lastWeekStart = DateTime(2023, 1, 2); // Monday
      final now = DateTime(2023, 1, 16); // 2 weeks later

      final entry = ProgressEntry()
        ..date = DateTime(2023, 1, 1)
        ..currentDay = 1
        ..totalDays = 28
        ..goldenDayDate = DateTime(2023, 1, 28)
        ..hasReachedGoldenDay = false
        ..consecutiveInactiveDays = 0
        ..totalTrainingsSinceLastDisclaimer = 0
        ..firestoreId = 'id'
        ..needsSync = false
        ..trainingsThisWeek = 5
        ..currentStreakWeeks = 10
        ..lastTrainingWeekStart = lastWeekStart
        ..lastActivityDate = DateTime(2023, 1, 8); // Sunday

      progressService.updateStreakAndActivity(entry, now);

      expect(entry.trainingsThisWeek, 1);
      expect(entry.currentStreakWeeks, 0); // Reset
    });

    test('Week with fewer than 3 trainings delays golden day by one week', () {
      final lastWeekStart = DateTime(2023, 1, 2);
      final now = DateTime(2023, 1, 9);
      final entry = ProgressEntry()
        ..date = DateTime(2023, 1, 1)
        ..currentDay = 1
        ..totalDays = 28
        ..goldenDayDate = DateTime(2023, 1, 30)
        ..hasReachedGoldenDay = false
        ..consecutiveInactiveDays = 0
        ..totalTrainingsSinceLastDisclaimer = 0
        ..firestoreId = 'id'
        ..needsSync = false
        ..trainingsThisWeek = 2
        ..currentStreakWeeks = 0
        ..lastTrainingWeekStart = lastWeekStart
        ..lastActivityDate = DateTime(2023, 1, 8);

      progressService.updateStreakAndActivity(entry, now);

      expect(entry.goldenDayDate, DateTime(2023, 2, 6));
    });

    test('Week with 3+ trainings keeps golden day date', () {
      final lastWeekStart = DateTime(2023, 1, 2);
      final now = DateTime(2023, 1, 9);
      final entry = ProgressEntry()
        ..date = DateTime(2023, 1, 1)
        ..currentDay = 1
        ..totalDays = 28
        ..goldenDayDate = DateTime(2023, 1, 30)
        ..hasReachedGoldenDay = false
        ..consecutiveInactiveDays = 0
        ..totalTrainingsSinceLastDisclaimer = 0
        ..firestoreId = 'id'
        ..needsSync = false
        ..trainingsThisWeek = 3
        ..currentStreakWeeks = 0
        ..lastTrainingWeekStart = lastWeekStart
        ..lastActivityDate = DateTime(2023, 1, 8);

      progressService.updateStreakAndActivity(entry, now);

      expect(entry.goldenDayDate, DateTime(2023, 1, 30));
    });

    test('Multiple missed weeks push golden day for each week', () {
      final lastWeekStart = DateTime(2023, 1, 2);
      final now = DateTime(2023, 1, 23); // three weeks later
      final entry = ProgressEntry()
        ..date = DateTime(2023, 1, 1)
        ..currentDay = 1
        ..totalDays = 28
        ..goldenDayDate = DateTime(2023, 1, 30)
        ..hasReachedGoldenDay = false
        ..consecutiveInactiveDays = 0
        ..totalTrainingsSinceLastDisclaimer = 0
        ..firestoreId = 'id'
        ..needsSync = false
        ..trainingsThisWeek = 1
        ..currentStreakWeeks = 0
        ..lastTrainingWeekStart = lastWeekStart
        ..lastActivityDate = DateTime(2023, 1, 8);

      progressService.updateStreakAndActivity(entry, now);

      expect(entry.goldenDayDate, DateTime(2023, 2, 20));
    });
  });

  group('Reminder Scheduling Plan', () {
    const baseWindow = HabitWindow(
      start: TimeOfDay(hour: 7, minute: 0),
      end: TimeOfDay(hour: 9, minute: 0),
      locationLabel: 'Home',
    );

    test('completed today schedules for tomorrow', () {
      final now = DateTime(2026, 2, 22, 8, 0);
      final plan = progressService.buildReminderSchedulePlan(
        now: now,
        baseWindow: baseWindow,
        completedToday: true,
        lastActivity: now.subtract(const Duration(hours: 1)),
        recentlyActiveThreshold: const Duration(hours: 10),
        inWindowDelay: const Duration(minutes: 20),
      );

      expect(plan.startDate, DateTime(2026, 2, 23));
      expect(plan.window.start, const TimeOfDay(hour: 7, minute: 0));
    });

    test('recent activity schedules for tomorrow', () {
      final now = DateTime(2026, 2, 22, 8, 0);
      final plan = progressService.buildReminderSchedulePlan(
        now: now,
        baseWindow: baseWindow,
        completedToday: false,
        lastActivity: now.subtract(const Duration(hours: 5)),
        recentlyActiveThreshold: const Duration(hours: 10),
        inWindowDelay: const Duration(minutes: 20),
      );

      expect(plan.startDate, DateTime(2026, 2, 23));
      expect(plan.recentlyActive, isTrue);
    });

    test('inside window delays reminder today', () {
      final now = DateTime(2026, 2, 22, 8, 10);
      final plan = progressService.buildReminderSchedulePlan(
        now: now,
        baseWindow: baseWindow,
        completedToday: false,
        lastActivity: null,
        recentlyActiveThreshold: const Duration(hours: 10),
        inWindowDelay: const Duration(minutes: 20),
      );

      expect(plan.startDate, DateTime(2026, 2, 22));
      expect(plan.window.start, const TimeOfDay(hour: 8, minute: 30));
    });

    test('after window schedules tomorrow', () {
      final now = DateTime(2026, 2, 22, 10, 0);
      final plan = progressService.buildReminderSchedulePlan(
        now: now,
        baseWindow: baseWindow,
        completedToday: false,
        lastActivity: null,
        recentlyActiveThreshold: const Duration(hours: 10),
        inWindowDelay: const Duration(minutes: 20),
      );

      expect(plan.startDate, DateTime(2026, 2, 23));
      expect(plan.window.start, const TimeOfDay(hour: 7, minute: 0));
    });

    test('at window start delays reminder today', () {
      final now = DateTime(2026, 2, 22, 7, 0);
      final plan = progressService.buildReminderSchedulePlan(
        now: now,
        baseWindow: baseWindow,
        completedToday: false,
        lastActivity: null,
        recentlyActiveThreshold: const Duration(hours: 10),
        inWindowDelay: const Duration(minutes: 20),
      );

      expect(plan.startDate, DateTime(2026, 2, 22));
      expect(plan.window.start, const TimeOfDay(hour: 7, minute: 20));
    });

    test('at window end schedules tomorrow', () {
      final now = DateTime(2026, 2, 22, 9, 0);
      final plan = progressService.buildReminderSchedulePlan(
        now: now,
        baseWindow: baseWindow,
        completedToday: false,
        lastActivity: null,
        recentlyActiveThreshold: const Duration(hours: 10),
        inWindowDelay: const Duration(minutes: 20),
      );

      expect(plan.startDate, DateTime(2026, 2, 23));
      expect(plan.window.start, const TimeOfDay(hour: 7, minute: 0));
    });
  });

  group('Dashboard Snapshot Helpers', () {
    test('fallback today completion increases weekly count by one', () {
      final weekStart = DateTime(2026, 2, 16);
      final today = DateTime(2026, 2, 22);
      final weekEnd = DateTime(2026, 2, 23);
      final completed = <int>{
        DateTime(2026, 2, 18).millisecondsSinceEpoch,
        DateTime(2026, 2, 20).millisecondsSinceEpoch,
      };

      final result = progressService.deriveCompletedThisWeekCount(
        completedDayEpochs: completed,
        today: today,
        weekStart: weekStart,
        weekEnd: weekEnd,
        fallbackTodayCompleted: true,
      );

      expect(result, 3);
    });

    test('fallback today completion does not double count existing day', () {
      final weekStart = DateTime(2026, 2, 16);
      final today = DateTime(2026, 2, 22);
      final weekEnd = DateTime(2026, 2, 23);
      final completed = <int>{
        DateTime(2026, 2, 18).millisecondsSinceEpoch,
        today.millisecondsSinceEpoch,
      };

      final result = progressService.deriveCompletedThisWeekCount(
        completedDayEpochs: completed,
        today: today,
        weekStart: weekStart,
        weekEnd: weekEnd,
        fallbackTodayCompleted: true,
      );

      expect(result, 2);
    });

    test('weekly count is clamped to seven', () {
      final weekStart = DateTime(2026, 2, 16);
      final today = DateTime(2026, 2, 22);
      final weekEnd = DateTime(2026, 2, 23);
      final completed = <int>{
        DateTime(2026, 2, 16).millisecondsSinceEpoch,
        DateTime(2026, 2, 17).millisecondsSinceEpoch,
        DateTime(2026, 2, 18).millisecondsSinceEpoch,
        DateTime(2026, 2, 19).millisecondsSinceEpoch,
        DateTime(2026, 2, 20).millisecondsSinceEpoch,
        DateTime(2026, 2, 21).millisecondsSinceEpoch,
        DateTime(2026, 2, 22).millisecondsSinceEpoch,
        DateTime(2026, 2, 23).millisecondsSinceEpoch,
      };

      final result = progressService.deriveCompletedThisWeekCount(
        completedDayEpochs: completed,
        today: today,
        weekStart: weekStart,
        weekEnd: weekEnd,
        fallbackTodayCompleted: true,
      );

      expect(result, 7);
    });
  });
}
