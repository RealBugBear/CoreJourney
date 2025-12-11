import 'package:flutter/material.dart';

class HabitWindow {
  final TimeOfDay start;
  final TimeOfDay end;
  final String? locationLabel;

  const HabitWindow({
    required this.start,
    required this.end,
    this.locationLabel,
  });

  DateTime resolveStartDate(DateTime date) => DateTime(
        date.year,
        date.month,
        date.day,
        start.hour,
        start.minute,
      );

  DateTime resolveEndDate(DateTime date) => DateTime(
        date.year,
        date.month,
        date.day,
        end.hour,
        end.minute,
      );
}

class QuietHours {
  final TimeOfDay start;
  final TimeOfDay end;

  const QuietHours({
    required this.start,
    required this.end,
  });
}

class UserPreferences {
  final List<HabitWindow> preferredWindows;
  final QuietHours quietHours;
  final String timezone;
  final bool locationConsent;
  final bool dailyReminderEnabled;
  final bool midweekCheckinEnabled;
  final bool locationNudgesEnabled;
  final bool silentMode;

  const UserPreferences({
    required this.preferredWindows,
    required this.quietHours,
    required this.timezone,
    required this.locationConsent,
    this.dailyReminderEnabled = true,
    this.midweekCheckinEnabled = true,
    this.locationNudgesEnabled = false,
    this.silentMode = false,
  });

  HabitWindow? primaryWindowForWeekday(int weekday) {
    if (preferredWindows.isEmpty) return null;
    final index = weekday % preferredWindows.length;
    return preferredWindows[index];
  }

  factory UserPreferences.defaultPreferences() {
    return UserPreferences(
      preferredWindows: const [
        HabitWindow(
          start: TimeOfDay(hour: 7, minute: 0),
          end: TimeOfDay(hour: 9, minute: 0),
          locationLabel: 'Home',
        ),
        HabitWindow(
          start: TimeOfDay(hour: 18, minute: 0),
          end: TimeOfDay(hour: 20, minute: 0),
          locationLabel: 'Gym',
        ),
      ],
      quietHours: const QuietHours(
        start: TimeOfDay(hour: 22, minute: 0),
        end: TimeOfDay(hour: 6, minute: 0),
      ),
      timezone: 'local',
      locationConsent: false,
      dailyReminderEnabled: true,
      midweekCheckinEnabled: true,
      locationNudgesEnabled: false,
      silentMode: false,
    );
  }
}
