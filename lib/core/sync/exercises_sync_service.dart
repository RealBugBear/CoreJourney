import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';
import '../logging/app_logger.dart';
import 'connectivity_service.dart';

/// Syncs static exercise content from Supabase into the local Drift cache.
///
/// Exercises are static content — they don't change per user and must be
/// available offline. This service fetches them once after app start and
/// whenever the local cache is empty. The server is authoritative; local rows
/// are always overwritten.
///
/// Call [syncIfNeeded] once after the database is ready. It is idempotent and
/// no-ops if the local cache already contains rows (avoids redundant fetches
/// on every cold start). Call [forceSync] to refresh unconditionally.
class ExercisesSyncService {
  final AppDatabase _db;

  ExercisesSyncService(this._db);

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Fetches exercises from Supabase if the local cache is empty.
  Future<void> syncIfNeeded() async {
    final count = await (_db.select(_db.exercisesTable)).get();
    if (count.isNotEmpty) {
      appLogger.d('ExercisesSyncService: cache has ${count.length} rows — skipping');
      return;
    }
    await _fetchAndCache();
  }

  /// Forces a full refresh from Supabase regardless of cache state.
  Future<void> forceSync() async => _fetchAndCache();

  // ── Internal ────────────────────────────────────────────────────────────────

  Future<void> _fetchAndCache() async {
    if (!await ConnectivityService.isConnected()) {
      appLogger.d('ExercisesSyncService: offline — using hardcoded fallback');
      return;
    }

    try {
      final client = Supabase.instance.client;

      final rows = await client
          .from('exercises')
          .select()
          .order('package_id')
          .order('sequence_number') as List<dynamic>;

      await _db.transaction(() async {
        for (final raw in rows) {
          final row = raw as Map<String, dynamic>;

          // Encode Postgres array fields to JSON strings for SQLite storage
          final companion = ExercisesTableCompanion.insert(
            id:                     row['id'] as String,
            packageId:              row['package_id'] as String,
            sequenceNumber:         row['sequence_number'] as int,
            titleDe:                row['title_de'] as String,
            titleEn:                row['title_en'] as String,
            positionInstructionsDe: _encodeList(row['position_instructions_de']),
            positionInstructionsEn: _encodeList(row['position_instructions_en']),
            movementInstructionsDe: _encodeList(row['movement_instructions_de']),
            movementInstructionsEn: _encodeList(row['movement_instructions_en']),
            hintsDe:                Value(_encodeNullableList(row['hints_de'])),
            hintsEn:                Value(_encodeNullableList(row['hints_en'])),
            executionGuideDe:       row['execution_guide_de'] as String,
            executionGuideEn:       row['execution_guide_en'] as String,
            durationSeconds:        row['duration_seconds'] as int,
            repetitions:            row['repetitions'] as int,
            imagePath:              row['image_path'] as String,
            videoPath:              Value(row['video_path'] as String?),
            audioCuePath:           Value(row['audio_cue_path'] as String?),
            rhythmType:             Value(row['rhythm_type'] as String? ?? 'holdRest'),
            phasesJson:             Value(_encodePhasesJson(row['phases_json'])),
            hasRepSwitch:           Value(row['has_rep_switch'] as bool? ?? false),
            holdCueDe:              Value(row['hold_cue_de'] as String? ?? 'Halten'),
            holdCueEn:              Value(row['hold_cue_en'] as String? ?? 'Hold'),
            holdSeconds:            Value(row['hold_seconds'] as int? ?? 7),
            restSeconds:            Value(row['rest_seconds'] as int? ?? 3),
            halfwaySwitch:          Value(row['halfway_switch'] as bool? ?? false),
          );

          await _db.into(_db.exercisesTable).insertOnConflictUpdate(companion);
        }
      });

      appLogger.i('ExercisesSyncService: cached ${rows.length} exercises from Supabase');
    } on AuthException {
      appLogger.w('ExercisesSyncService: auth error — using fallback');
    } catch (e, st) {
      appLogger.e('ExercisesSyncService: fetch failed', error: e, stackTrace: st);
    }
  }

  // ── Encoding helpers ────────────────────────────────────────────────────────

  /// Supabase returns text[] as List<dynamic>. Drift stores as JSON string.
  static String _encodeList(dynamic value) {
    if (value == null) return '[]';
    if (value is String) return value; // already JSON
    return jsonEncode((value as List).cast<String>());
  }

  static String? _encodeNullableList(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    final list = (value as List).cast<String>();
    if (list.isEmpty) return null;
    return jsonEncode(list);
  }

  /// phases_json is already jsonb on the server — encode to string for SQLite.
  static String _encodePhasesJson(dynamic value) {
    if (value == null) return '[]';
    if (value is String) return value;
    return jsonEncode(value); // List<Map<String, dynamic>>
  }
}
