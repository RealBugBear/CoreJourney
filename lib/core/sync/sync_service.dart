import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../logging/app_logger.dart';
import 'connectivity_service.dart';
import 'sync_status.dart';
import '../../features/trainer/domain/services/trainer_notification_service.dart';

const _uuid = Uuid();

class SyncService {
  final AppDatabase _db;
  Timer? _periodicTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncAt;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncService(this._db);

  void start() {
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => drain(),
    );
    // Emit initial status on start
    _emitStatus();
  }

  void stop() {
    _periodicTimer?.cancel();
    _statusController.close();
  }

  Future<void> drain() async {
    if (_isSyncing) return;
    if (!await ConnectivityService.isConnected()) return;

    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return;

    _isSyncing = true;
    _emitStatus();
    try {
      await _processPendingJobs(client);
      _lastSyncAt = DateTime.now();
    } finally {
      _isSyncing = false;
      _emitStatus();
    }
  }

  Future<void> _processPendingJobs(SupabaseClient client) async {
    final jobs = await (_db.select(_db.syncJobsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    // Coalesce: for each (table, recordId), keep only the latest job
    // and delete superseded older jobs immediately
    final supersededIds = <String>[];
    final coalesced = <String, SyncJobsTableData>{};
    for (final job in jobs) {
      final key = '${job.tableName_}:${job.recordId}';
      if (coalesced.containsKey(key)) {
        supersededIds.add(coalesced[key]!.id);
      }
      coalesced[key] = job;
    }

    if (supersededIds.isNotEmpty) {
      await (_db.delete(_db.syncJobsTable)
            ..where((t) => t.id.isIn(supersededIds)))
          .go();
      appLogger.d('Deleted ${supersededIds.length} superseded sync jobs');
    }

    for (final job in coalesced.values) {
      if (job.retryCount >= 5) {
        appLogger.w('Sync job ${job.id} exceeded max retries — skipping');
        continue;
      }

      // Exponential backoff: 30s, 60s, 120s, 240s, 480s
      if (job.retryCount > 0 && job.lastAttemptAt != null) {
        final backoffSeconds =
            min(30 * pow(2, job.retryCount - 1).toInt(), 1800);
        final nextRetryAt =
            job.lastAttemptAt!.add(Duration(seconds: backoffSeconds));
        if (DateTime.now().isBefore(nextRetryAt)) continue;
      }

      try {
        if (job.action == 'upsert') {
          final payload = jsonDecode(job.payload) as Map<String, dynamic>;
          await client.from(job.tableName_).upsert(payload);
          // Notify trainer after training session syncs
          if (job.tableName_ == 'training_sessions' &&
              payload['is_completed'] == true) {
            final traineeId = payload['user_id'] as String?;
            final dayNumber = payload['day_number'] as int?;
            if (traineeId != null && dayNumber != null) {
              unawaited(
                TrainerNotificationService.instance.checkAndNotifyTrainer(
                  traineeId,
                  dayNumber,
                ),
              );
            }
          }
        } else if (job.action == 'delete') {
          await client.from(job.tableName_).delete().eq('id', job.recordId);
        }

        await (_db.delete(_db.syncJobsTable)
              ..where((t) => t.id.equals(job.id)))
            .go();

        appLogger.d('Synced ${job.tableName_}:${job.recordId}');
      } on AuthException {
        appLogger.w('Auth error during sync — pausing');
        _isSyncing = false;
        return;
      } catch (e, st) {
        appLogger.e('Sync error for job ${job.id}', error: e, stackTrace: st);
        await (_db.update(_db.syncJobsTable)
              ..where((t) => t.id.equals(job.id)))
            .write(SyncJobsTableCompanion(
          retryCount: Value(job.retryCount + 1),
          lastAttemptAt: Value(DateTime.now()),
        ));
      }
    }
  }

  Future<void> enqueueUpsert({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    await _db.into(_db.syncJobsTable).insertOnConflictUpdate(
          SyncJobsTableCompanion.insert(
            id: _uuid.v4(),
            action: 'upsert',
            tableName_: tableName,
            recordId: recordId,
            payload: jsonEncode(payload),
          ),
        );
    _emitStatus();
  }

  Future<void> enqueueDelete({
    required String tableName,
    required String recordId,
  }) async {
    await _db.into(_db.syncJobsTable).insertOnConflictUpdate(
          SyncJobsTableCompanion.insert(
            id: _uuid.v4(),
            action: 'delete',
            tableName_: tableName,
            recordId: recordId,
            payload: '{}',
          ),
        );
    _emitStatus();
  }

  Future<void> _emitStatus() async {
    if (_statusController.isClosed) return;
    try {
      final all = await (_db.select(_db.syncJobsTable)).get();
      final failed = all.where((j) => j.retryCount >= 5).length;
      final pending = all.length - failed;
      _statusController.add(SyncStatus(
        isSyncing: _isSyncing,
        pendingCount: pending,
        failedCount: failed,
        lastSyncAt: _lastSyncAt,
      ));
    } catch (_) {
      // DB may not be ready yet on startup
    }
  }
}
