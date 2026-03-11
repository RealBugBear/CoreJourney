import 'package:corejourney/core/services/notification_service.dart';
import 'package:corejourney/features/progress/domain/models/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = NotificationService();

  HabitWindow window(
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
  ) {
    return HabitWindow(
      start: TimeOfDay(hour: startHour, minute: startMinute),
      end: TimeOfDay(hour: endHour, minute: endMinute),
    );
  }

  QuietHours quiet(
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
  ) {
    return QuietHours(
      start: TimeOfDay(hour: startHour, minute: startMinute),
      end: TimeOfDay(hour: endHour, minute: endMinute),
    );
  }

  group('NotificationService quiet hours overlap', () {
    test('does not block non-overlapping daytime window', () {
      final blocked = service.isWithinQuietHoursForTesting(
        window(7, 0, 9, 0),
        quiet(13, 0, 15, 0),
      );
      expect(blocked, isFalse);
    });

    test('blocks overlapping daytime window', () {
      final blocked = service.isWithinQuietHoursForTesting(
        window(14, 0, 16, 0),
        quiet(13, 0, 15, 0),
      );
      expect(blocked, isTrue);
    });

    test('blocks overlap for overnight quiet hours', () {
      final blocked = service.isWithinQuietHoursForTesting(
        window(23, 0, 1, 0),
        quiet(22, 0, 6, 0),
      );
      expect(blocked, isTrue);
    });

    test('allows morning window outside overnight quiet hours', () {
      final blocked = service.isWithinQuietHoursForTesting(
        window(7, 0, 9, 0),
        quiet(22, 0, 6, 0),
      );
      expect(blocked, isFalse);
    });

    test('blocks when quiet hours intersect overnight window edge', () {
      final blocked = service.isWithinQuietHoursForTesting(
        window(21, 0, 23, 0),
        quiet(22, 0, 6, 0),
      );
      expect(blocked, isTrue);
    });
  });

  group('NotificationService next daily reminder date', () {
    test('schedules for next day at given reminder time', () {
      final now = DateTime(2026, 2, 22, 8, 30);
      final scheduled = service.computeNextDailyReminderDateForTesting(
        now: now,
        reminderTime: const TimeOfDay(hour: 7, minute: 0),
      );

      expect(scheduled, DateTime(2026, 2, 23, 7, 0));
    });

    test('near midnight still schedules next day at reminder time', () {
      final now = DateTime(2026, 2, 22, 23, 59);
      final scheduled = service.computeNextDailyReminderDateForTesting(
        now: now,
        reminderTime: const TimeOfDay(hour: 7, minute: 0),
      );

      expect(scheduled, DateTime(2026, 2, 23, 7, 0));
    });

    test('exact reminder time still resolves to next day', () {
      final now = DateTime(2026, 2, 22, 7, 0);
      final scheduled = service.computeNextDailyReminderDateForTesting(
        now: now,
        reminderTime: const TimeOfDay(hour: 7, minute: 0),
      );

      expect(scheduled, DateTime(2026, 2, 23, 7, 0));
    });
  });
}
