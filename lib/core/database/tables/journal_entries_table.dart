import 'package:drift/drift.dart';

class JournalEntriesTable extends Table {
  @override
  String get tableName => 'journal_entries';

  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get enrollmentId => text().nullable()();
  TextColumn get content => text()();
  IntColumn get dayKey => integer()(); // epoch days — links to mood_checkins
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
