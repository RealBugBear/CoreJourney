import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/models/mood_checkin.dart';

class MoodDailyAggregate {
  final DateTime day;
  final double? avgMood;
  final double? minMood;
  final double? maxMood;
  final double? avgEnergy;
  final double? minEnergy;
  final double? maxEnergy;
  final double? avgStress;
  final double? minStress;
  final double? maxStress;
  final int entriesCount;
  final int noteCount;

  const MoodDailyAggregate({
    required this.day,
    required this.avgMood,
    required this.minMood,
    required this.maxMood,
    required this.avgEnergy,
    required this.minEnergy,
    required this.maxEnergy,
    required this.avgStress,
    required this.minStress,
    required this.maxStress,
    required this.entriesCount,
    required this.noteCount,
  });
}

class MoodRepository {
  final DatabaseService _db;
  final SyncService _sync;
  final String _userId;

  MoodRepository(this._db, this._sync, this._userId);

  Future<MoodCheckin> createCheckin({
    required String packageId,
    required MoodCheckinSource source,
    DateTime? recordedAt,
    String? sessionId,
    int? mood,
    int? energy,
    int? stress,
    String? note,
  }) async {
    final timestamp = recordedAt ?? DateTime.now();
    final normalizedDay =
        DateTime(timestamp.year, timestamp.month, timestamp.day);
    final entry = MoodCheckin()
      ..userId = _userId
      ..packageId = packageId
      ..recordedAt = timestamp
      ..dayKey = normalizedDay.millisecondsSinceEpoch
      ..sessionId = sessionId
      ..mood = _normalizeScore(mood)
      ..energy = _normalizeScore(energy)
      ..stress = _normalizeScore(stress)
      ..note = _normalizeNote(note)
      ..source = source
      ..firestoreId = const Uuid().v4()
      ..needsSync = true;

    await _db.isar.writeTxn(() async {
      await _db.isar.moodCheckins.put(entry);
    });

    await _sync.addJob(
      collection: 'moodCheckins',
      docId: entry.firestoreId,
      action: 'create',
      payload: _toSyncPayload(entry),
    );

    return entry;
  }

  Future<void> updateCheckin(MoodCheckin entry) async {
    entry.mood = _normalizeScore(entry.mood);
    entry.energy = _normalizeScore(entry.energy);
    entry.stress = _normalizeScore(entry.stress);
    entry.note = _normalizeNote(entry.note);
    entry.needsSync = true;

    await _db.isar.writeTxn(() async {
      await _db.isar.moodCheckins.put(entry);
    });

    await _sync.addJob(
      collection: 'moodCheckins',
      docId: entry.firestoreId,
      action: 'update',
      payload: _toSyncPayload(entry),
    );
  }

  Future<void> deleteCheckin(MoodCheckin entry) async {
    await _db.isar.writeTxn(() async {
      await _db.isar.moodCheckins.delete(entry.id);
    });

    await _sync.addJob(
      collection: 'moodCheckins',
      docId: entry.firestoreId,
      action: 'delete',
      payload: {
        'deletedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<MoodCheckin>> getCheckinsInRange({
    required DateTime fromInclusive,
    required DateTime toExclusive,
    String? packageId,
  }) async {
    final query = _db.isar.moodCheckins
        .filter()
        .userIdEqualTo(_userId)
        .recordedAtBetween(fromInclusive, toExclusive);

    if (packageId != null && packageId.isNotEmpty) {
      return query.packageIdEqualTo(packageId).sortByRecordedAt().findAll();
    }
    return query.sortByRecordedAt().findAll();
  }

  Future<List<MoodCheckin>> getNotesInRange({
    required DateTime fromInclusive,
    required DateTime toExclusive,
    String? packageId,
  }) async {
    final items = await getCheckinsInRange(
      fromInclusive: fromInclusive,
      toExclusive: toExclusive,
      packageId: packageId,
    );
    return items
        .where((entry) => entry.note != null && entry.note!.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<List<MoodDailyAggregate>> getDailyAggregatesInRange({
    required DateTime fromInclusive,
    required DateTime toExclusive,
    String? packageId,
  }) async {
    final items = await getCheckinsInRange(
      fromInclusive: fromInclusive,
      toExclusive: toExclusive,
      packageId: packageId,
    );
    final byDay = <int, List<MoodCheckin>>{};
    for (final item in items) {
      byDay.putIfAbsent(item.dayKey, () => <MoodCheckin>[]).add(item);
    }

    final keys = byDay.keys.toList()..sort();
    final aggregates = <MoodDailyAggregate>[];
    for (final dayKey in keys) {
      final dailyItems = byDay[dayKey]!;
      aggregates.add(
        MoodDailyAggregate(
          day: DateTime.fromMillisecondsSinceEpoch(dayKey),
          avgMood: _averageScore(dailyItems, (entry) => entry.mood),
          minMood: _minScore(dailyItems, (entry) => entry.mood),
          maxMood: _maxScore(dailyItems, (entry) => entry.mood),
          avgEnergy: _averageScore(dailyItems, (entry) => entry.energy),
          minEnergy: _minScore(dailyItems, (entry) => entry.energy),
          maxEnergy: _maxScore(dailyItems, (entry) => entry.energy),
          avgStress: _averageScore(dailyItems, (entry) => entry.stress),
          minStress: _minScore(dailyItems, (entry) => entry.stress),
          maxStress: _maxScore(dailyItems, (entry) => entry.stress),
          entriesCount: dailyItems.length,
          noteCount: dailyItems
              .where((entry) =>
                  entry.note != null && entry.note!.trim().isNotEmpty)
              .length,
        ),
      );
    }
    return aggregates;
  }

  int? _normalizeScore(int? value) {
    if (value == null) return null;
    return value.clamp(1, 5);
  }

  String? _normalizeNote(String? note) {
    final trimmed = note?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  double? _averageScore(
    List<MoodCheckin> values,
    int? Function(MoodCheckin entry) selector,
  ) {
    final scores =
        values.map(selector).whereType<int>().toList(growable: false);
    if (scores.isEmpty) return null;
    final sum = scores.reduce((a, b) => a + b);
    return sum / scores.length;
  }

  double? _minScore(
    List<MoodCheckin> values,
    int? Function(MoodCheckin entry) selector,
  ) {
    final scores =
        values.map(selector).whereType<int>().toList(growable: false);
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a < b ? a : b).toDouble();
  }

  double? _maxScore(
    List<MoodCheckin> values,
    int? Function(MoodCheckin entry) selector,
  ) {
    final scores =
        values.map(selector).whereType<int>().toList(growable: false);
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a > b ? a : b).toDouble();
  }

  Map<String, dynamic> _toSyncPayload(MoodCheckin entry) {
    return {
      'userId': entry.userId,
      'packageId': entry.packageId,
      'recordedAt': entry.recordedAt.toIso8601String(),
      'dayKey': entry.dayKey,
      'sessionId': entry.sessionId,
      'mood': entry.mood,
      'energy': entry.energy,
      'stress': entry.stress,
      'note': entry.note,
      'source': entry.source.name,
    };
  }
}
