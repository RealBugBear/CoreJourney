import 'package:drift/drift.dart';

/// First-class journal entries — separate from mood checkins.
///
/// A journal entry may optionally reference a [MoodCheckinsTable] row via
/// [checkinId] so the UI can surface mood context alongside the note.
/// Entries without [checkinId] are standalone text notes.
///
/// Mood snapshot fields ([mood], [energy], [stress]) are denormalised here so
/// the journal can be displayed without a join, and so entries remain
/// self-contained after the originating checkin is deleted.
class JournalEntriesTable extends Table {
  @override
  String get tableName => 'journal_entries';

  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get enrollmentId => text().nullable()();

  /// FK to the mood_checkin that was submitted alongside this note, or null for
  /// standalone entries.
  TextColumn get checkinId => text().nullable()();

  TextColumn get content => text()();

  /// Snapshot of mood at the time of writing (1–5, nullable).
  IntColumn get mood => integer().nullable()();
  IntColumn get energy => integer().nullable()();
  IntColumn get stress => integer().nullable()();

  /// Epoch-day key (days since 1970-01-01) — matches mood_checkins.day_key.
  IntColumn get dayKey => integer()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
