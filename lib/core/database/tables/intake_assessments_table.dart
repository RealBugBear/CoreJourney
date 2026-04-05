import 'package:drift/drift.dart';

class IntakeAssessmentsTable extends Table {
  @override
  String get tableName => 'intake_assessments';

  TextColumn get id => text()();
  TextColumn get enrollmentId => text()();
  BoolColumn get hadIsometricWithTrainer => boolean()();
  TextColumn get additionalAnswers => text().nullable()(); // JSON
  IntColumn get recommendedDurationWeeks => integer()();
  BoolColumn get userAcceptedRecommendation => boolean()();
  IntColumn get finalDurationWeeks => integer()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
