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
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedStart =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEnd = normalizedStart.add(const Duration(days: 7));
    final remaining = weekEnd.difference(normalizedNow).inDays;
    return remaining.clamp(0, 7);
  }

  double get progress => targetCount == 0 ? 0 : completedCount / targetCount;

  int get remainingCalendarDaysFromToday {
    final now = DateTime.now();
    return calendarDaysRemaining(now);
  }
}
