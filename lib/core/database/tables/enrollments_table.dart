import 'package:drift/drift.dart';

class EnrollmentsTable extends Table {
  @override
  String get tableName => 'enrollments';

  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get packageId => text()();
  // 'active' | 'paused' | 'completed' | 'abandoned'
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get assignedDurationWeeks => integer()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get targetCompletionDate => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get pausedAt => dateTime().nullable()();
  TextColumn get precedingEnrollmentId => text().nullable()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
