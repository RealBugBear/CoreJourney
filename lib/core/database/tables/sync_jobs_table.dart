import 'package:drift/drift.dart';

class SyncJobsTable extends Table {
  @override
  String get tableName => 'sync_jobs';

  TextColumn get id => text()();
  // 'upsert' | 'delete'
  TextColumn get action => text()();
  TextColumn get tableName_ => text().named('table_name')();
  TextColumn get recordId => text()();
  TextColumn get payload => text()(); // JSON-encoded row data
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
