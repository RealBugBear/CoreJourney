import 'package:isar/isar.dart';

part 'progress_entry.g.dart';

@collection
class ProgressEntry {
  Id id = Isar.autoIncrement;
  
  @Index()
  late String userId;
  
  late DateTime date;
  late int currentDay; // 1-28
  late int totalDays; // Always 28
  
  late DateTime goldenDayDate; // Target end date
  late bool hasReachedGoldenDay;
  
  // Inactivity tracking
  DateTime? lastActivityDate;
  late int consecutiveInactiveDays;
  
  // Disclaimer tracking
  late int totalTrainingsSinceLastDisclaimer; // Reset to 0 after disclaimer acceptance
  DateTime? lastDisclaimerAcceptedAt;

  // Streak tracking
  int currentStreakWeeks = 0;
  int trainingsThisWeek = 0;
  DateTime? lastTrainingWeekStart;
  
  // Sync
  late String firestoreId;
  late bool needsSync;
}
