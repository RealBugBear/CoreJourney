import 'package:drift/drift.dart';

class MoodCheckinsTable extends Table {
  @override
  String get tableName => 'mood_checkins';

  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get enrollmentId => text()();
  TextColumn get sessionId => text().nullable()();
  DateTimeColumn get recordedAt => dateTime()();
  IntColumn get dayKey => integer()(); // epoch days
  IntColumn get mood => integer().nullable()(); // 1-5
  IntColumn get energy => integer().nullable()(); // 1-5
  IntColumn get stress => integer().nullable()(); // 1-5
  TextColumn get note => text().nullable()();
  // 'post_training' | 'manual'
  TextColumn get source => text()();
  TextColumn get subjectProfileId => text().nullable()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
