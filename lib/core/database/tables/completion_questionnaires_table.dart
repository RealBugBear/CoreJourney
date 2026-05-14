import 'package:drift/drift.dart';

class CompletionQuestionnairesTable extends Table {
  @override
  String get tableName => 'completion_questionnaires';

  TextColumn get id => text()();
  TextColumn get enrollmentId => text()();
  IntColumn get attemptNumber => integer().withDefault(const Constant(1))();
  BoolColumn get response => boolean()();
  // 'passed' | 'extend'
  TextColumn get result => text()();
  BoolColumn get nextEnrollmentCreated =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
  TextColumn get subjectProfileId => text().nullable()();
  DateTimeColumn get submittedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
