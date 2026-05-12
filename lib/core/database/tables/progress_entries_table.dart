import 'package:drift/drift.dart';

class ProgressEntriesTable extends Table {
  @override
  String get tableName => 'progress_entries';

  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get subjectProfileId => text().nullable()();
  TextColumn get enrollmentId => text()();
  IntColumn get currentDay => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastActivityDate => dateTime().nullable()();
  IntColumn get consecutiveInactiveDays =>
      integer().withDefault(const Constant(0))();
  IntColumn get dailyStreak => integer().withDefault(const Constant(0))();
  IntColumn get weeklyStreak => integer().withDefault(const Constant(0))();
  IntColumn get trainingsThisWeek => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastTrainingWeekStart => dateTime().nullable()();
  IntColumn get weeklyGoal => integer().withDefault(const Constant(5))();
  IntColumn get totalSessionsSinceDisclaimer =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get lastDisclaimerAcceptedAt => dateTime().nullable()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
