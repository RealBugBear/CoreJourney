import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';
import '../logging/app_logger.dart';
import 'connectivity_service.dart';

class SyncService {
  final AppDatabase _db;
  Timer? _periodicTimer;
  bool _isSyncing = false;

  SyncService(this._db);

  void start() {
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => drain(),
    );
  }

  void stop() {
    _periodicTimer?.cancel();
  }

  Future<void> drain() async {
    if (_isSyncing) return;
    if (!await ConnectivityService.isConnected()) return;

    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return;

    _isSyncing = true;
    try {
      await _processPendingJobs(client);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processPendingJobs(SupabaseClient client) async {
    final jobs = await (_db.select(_db.syncJobsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    // Coalesce: for each (table, recordId), keep only the latest job
    final coalesced = <String, SyncJobsTableData>{};
    for (final job in jobs) {
      final key = '${job.tableName_}:${job.recordId}';
      coalesced[key] = job;
    }

    for (final job in coalesced.values) {
      if (job.retryCount >= 5) {
        appLogger.w('Sync job ${job.id} exceeded max retries — skipping');
        continue;
      }

      try {
        if (job.action == 'upsert') {
          final payload = jsonDecode(job.payload) as Map<String, dynamic>;
          await client.from(job.tableName_).upsert(payload);
        } else if (job.action == 'delete') {
          await client.from(job.tableName_).delete().eq('id', job.recordId);
        }

        // Success — remove job
        await (_db.delete(_db.syncJobsTable)
              ..where((t) => t.id.equals(job.id)))
            .go();

        appLogger.d('Synced ${job.tableName_}:${job.recordId}');
      } on AuthException {
        appLogger.w('Auth error during sync — pausing');
        _isSyncing = false;
        return;
      } catch (e) {
        appLogger.e('Sync error for job ${job.id}', error: e);
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
            id: '${tableName}_${recordId}_${DateTime.now().millisecondsSinceEpoch}',
            action: 'upsert',
            tableName_: tableName,
            recordId: recordId,
            payload: jsonEncode(payload),
          ),
        );
  }

  Future<void> enqueueDelete({
    required String tableName,
    required String recordId,
  }) async {
    await _db.into(_db.syncJobsTable).insertOnConflictUpdate(
          SyncJobsTableCompanion.insert(
            id: '${tableName}_${recordId}_delete_${DateTime.now().millisecondsSinceEpoch}',
            action: 'delete',
            tableName_: tableName,
            recordId: recordId,
            payload: '{}',
          ),
        );
  }
}
