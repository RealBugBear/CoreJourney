import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:corejourney/features/progress/domain/services/progress_service.dart';
import 'package:corejourney/features/progress/domain/models/progress_entry.dart';
import 'package:corejourney/core/database/database_service.dart';
import 'package:corejourney/core/sync/sync_service.dart';

import 'package:corejourney/core/services/notification_service.dart';

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
    when(() => mockNotifications.scheduleDailyReminder(any())).thenAnswer((_) async {});
    
    progressService = ProgressService(mockDb, mockSync, mockNotifications, 'test_user');
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
      expect(entry.lastTrainingWeekStart, DateTime(2022, 12, 26)); // Monday before
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
  });
}
