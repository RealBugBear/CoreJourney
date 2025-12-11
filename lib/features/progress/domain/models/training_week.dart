import 'package:flutter/material.dart';

import 'user_preferences.dart';

class TrainingDayStatus {
  final DateTime date;
  final bool completed;
  final bool plannedSkip;
  final HabitWindow? predictedWindow;
  final String? locationLabel;

  const TrainingDayStatus({
    required this.date,
    required this.completed,
    this.plannedSkip = false,
    this.predictedWindow,
    this.locationLabel,
  });
}

class WeeklyProgressOverview {
  final DateTime weekStart;
  final List<TrainingDayStatus> days;
  final int targetCount;
  final int weeklyStreakWeeks;
  final int dailyStreakDays;
  final int plannedSkips;

  WeeklyProgressOverview({
    required this.weekStart,
    required this.days,
    required this.targetCount,
    required this.weeklyStreakWeeks,
    required this.dailyStreakDays,
    required this.plannedSkips,
  });

  int get completedCount => days.where((day) => day.completed).length;

  int get remainingBuffer => (targetCount - plannedSkips - completedCount).clamp(0, targetCount);

  int calendarDaysRemaining(DateTime now) {
    final difference = now.difference(weekStart).inDays;
    final daysConsumed = difference.clamp(0, 6);
    return (7 - daysConsumed - 1).clamp(0, 6);
  }

  double get progress => targetCount == 0 ? 0 : completedCount / targetCount;

  int get remainingCalendarDaysFromToday {
    final now = DateTime.now();
    return calendarDaysRemaining(now);
  }
}
