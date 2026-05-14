import 'package:drift/drift.dart';

/// Local cache of Supabase's `exercises` table.
/// Arrays are stored as JSON-encoded strings (SQLite has no native array type).
/// Timer config columns mirror the server schema added in exercises_migration.sql.
class ExercisesTable extends Table {
  @override
  String get tableName => 'exercises';

  // ── Identity ────────────────────────────────────────────────────────────────
  TextColumn get id => text()();
  TextColumn get packageId => text()();
  IntColumn get sequenceNumber => integer()();

  // ── Localised content ───────────────────────────────────────────────────────
  TextColumn get titleDe => text()();
  TextColumn get titleEn => text()();

  // Stored as JSON: ["step1", "step2", ...]
  TextColumn get positionInstructionsDe => text()();
  TextColumn get positionInstructionsEn => text()();
  TextColumn get movementInstructionsDe => text()();
  TextColumn get movementInstructionsEn => text()();
  TextColumn get hintsDe => text().nullable()(); // JSON or null
  TextColumn get hintsEn => text().nullable()(); // JSON or null

  TextColumn get executionGuideDe => text()();
  TextColumn get executionGuideEn => text()();

  // ── Base timing ─────────────────────────────────────────────────────────────
  IntColumn get durationSeconds => integer()();
  IntColumn get repetitions => integer()();

  // ── Assets ──────────────────────────────────────────────────────────────────
  TextColumn get imagePath => text()();
  TextColumn get videoPath => text().nullable()();
  TextColumn get audioCuePath => text().nullable()();

  // ── Timer config ────────────────────────────────────────────────────────────
  // 'phased' = counted phases; 'holdRest' = hold N s, rest M s
  TextColumn get rhythmType => text().withDefault(const Constant('holdRest'))();
  // JSON: [{"labelDe":"Hoch","labelEn":"Up","durationSeconds":3}, ...]
  TextColumn get phasesJson => text().withDefault(const Constant('[]'))();
  BoolColumn get hasRepSwitch => boolean().withDefault(const Constant(false))();
  TextColumn get holdCueDe => text().withDefault(const Constant('Halten'))();
  TextColumn get holdCueEn => text().withDefault(const Constant('Hold'))();
  IntColumn get holdSeconds => integer().withDefault(const Constant(7))();
  IntColumn get restSeconds => integer().withDefault(const Constant(3))();
  BoolColumn get halfwaySwitch =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
