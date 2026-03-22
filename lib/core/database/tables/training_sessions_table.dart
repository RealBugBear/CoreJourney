import 'package:drift/drift.dart';

class TrainingSessionsTable extends Table {
  @override
  String get tableName => 'training_sessions';

  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get enrollmentId => text()();
  DateTimeColumn get sessionDate => dateTime()();
  IntColumn get dayNumber => integer()();
  TextColumn get completedExerciseIds => text()(); // JSON-encoded list
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
