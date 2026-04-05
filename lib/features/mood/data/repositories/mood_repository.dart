import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/time/app_clock.dart';
import '../../domain/models/mood_daily_aggregate.dart';

const _uuid = Uuid();

class MoodRepository {
  final AppDatabase _db;
  final SyncService _syncService;
  final AppClock _clock;

  MoodRepository(this._db, this._syncService, this._clock);

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  Future<List<MoodCheckinsTableData>> getCheckinsInRange({
    required String enrollmentId,
    required DateTime from,
    required DateTime to,
  }) async {
    final userId = _userId;
    if (userId == null) return [];

    return (_db.select(_db.moodCheckinsTable)
          ..where((t) =>
              t.userId.equals(userId) &
              t.enrollmentId.equals(enrollmentId) &
              t.recordedAt.isBiggerOrEqualValue(from) &
              t.recordedAt.isSmallerOrEqualValue(to))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.recordedAt)]))
        .get();
  }

  Future<List<MoodCheckinsTableData>> getNotesInRange({
    required String enrollmentId,
    required DateTime from,
    required DateTime to,
  }) async {
    final userId = _userId;
    if (userId == null) return [];

    return (_db.select(_db.moodCheckinsTable)
          ..where((t) =>
              t.userId.equals(userId) &
              t.enrollmentId.equals(enrollmentId) &
              t.recordedAt.isBiggerOrEqualValue(from) &
              t.recordedAt.isSmallerOrEqualValue(to) &
              t.note.isNotNull() &
              t.note.isNotValue(''))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.recordedAt)]))
        .get();
  }

  Future<List<MoodDailyAggregate>> getDailyAggregatesInRange({
    required String enrollmentId,
    required DateTime from,
    required DateTime to,
  }) async {
    final checkins = await getCheckinsInRange(
      enrollmentId: enrollmentId,
      from: from,
      to: to,
    );

    final grouped = <int, List<MoodCheckinsTableData>>{};
    for (final checkin in checkins) {
      grouped.putIfAbsent(checkin.dayKey, () => []).add(checkin);
    }

    final dayKeys = grouped.keys.toList()..sort();
    return dayKeys.map((dayKey) {
      final values = grouped[dayKey]!;
      return MoodDailyAggregate(
        dayKey: dayKey,
        day: DateTime(1970).add(Duration(days: dayKey)),
        mood: _avg(values.map((e) => e.mood)),
        energy: _avg(values.map((e) => e.energy)),
        stress: _avg(values.map((e) => e.stress)),
      );
    }).toList();
  }

  Future<void> createCheckin({
    required String enrollmentId,
    int? mood,
    int? energy,
    int? stress,
    String? note,
    required String source,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final now = _clock.now();
    final id = _uuid.v4();
    final dayKey = now.difference(DateTime(1970)).inDays;
    final normalizedNote = _normalizeNote(note);

    await _db.into(_db.moodCheckinsTable).insert(
          MoodCheckinsTableCompanion.insert(
            id: id,
            userId: userId,
            enrollmentId: enrollmentId,
            recordedAt: now,
            dayKey: dayKey,
            mood: drift.Value(mood),
            energy: drift.Value(energy),
            stress: drift.Value(stress),
            note: drift.Value(normalizedNote),
            source: source,
          ),
        );

    await _syncService.enqueueUpsert(
      tableName: 'mood_checkins',
      recordId: id,
      payload: {
        'id': id,
        'user_id': userId,
        'enrollment_id': enrollmentId,
        'recorded_at': now.toIso8601String(),
        'day_key': dayKey,
        'mood': mood,
        'energy': energy,
        'stress': stress,
        'note': normalizedNote,
        'source': source,
      },
    );
  }

  Future<void> updateCheckin({
    required String id,
    int? mood,
    int? energy,
    int? stress,
    String? note,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final normalizedNote = _normalizeNote(note);

    await (_db.update(_db.moodCheckinsTable)..where((t) => t.id.equals(id)))
        .write(
      MoodCheckinsTableCompanion(
        mood: drift.Value(mood),
        energy: drift.Value(energy),
        stress: drift.Value(stress),
        note: drift.Value(normalizedNote),
        needsSync: const drift.Value(true),
      ),
    );

    final updated = await (_db.select(_db.moodCheckinsTable)
          ..where((t) => t.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
    if (updated == null) return;

    await _syncService.enqueueUpsert(
      tableName: 'mood_checkins',
      recordId: id,
      payload: {
        'id': id,
        'user_id': userId,
        'enrollment_id': updated.enrollmentId,
        'session_id': updated.sessionId,
        'recorded_at': updated.recordedAt.toIso8601String(),
        'day_key': updated.dayKey,
        'mood': updated.mood,
        'energy': updated.energy,
        'stress': updated.stress,
        'note': updated.note,
        'source': updated.source,
      },
    );
  }

  Future<void> deleteCheckin({required String id}) async {
    await (_db.delete(_db.moodCheckinsTable)..where((t) => t.id.equals(id)))
        .go();
    await _syncService.enqueueDelete(tableName: 'mood_checkins', recordId: id);
  }

  String? _normalizeNote(String? input) {
    final trimmed = input?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  double? _avg(Iterable<int?> values) {
    final nonNull = values.whereType<int>().toList();
    if (nonNull.isEmpty) return null;
    final sum = nonNull.reduce((a, b) => a + b);
    return sum / nonNull.length;
  }
}
