import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../database/database_service.dart';
import 'models/sync_job.dart';

class SyncQueueStats {
  final int pendingJobs;
  final int createJobs;
  final int updateJobs;
  final int deleteJobs;
  final DateTime? oldestJobAt;

  const SyncQueueStats({
    required this.pendingJobs,
    required this.createJobs,
    required this.updateJobs,
    required this.deleteJobs,
    required this.oldestJobAt,
  });
}

class SyncService {
  final DatabaseService _db;
  final FirebaseFirestore? _firestore;
  final Connectivity _connectivity;

  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;
  Timer? _periodicSyncTimer;

  SyncService(
    this._db, {
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
  })  : _firestore = firestore,
        _connectivity = connectivity ?? Connectivity();

  void init() {
    // Skip sync initialization if Firebase is not configured
    if (_firestore == null) {
      debugPrint(
          '[SyncService] Firebase not configured - running in offline mode');
      return;
    }

    // Listen to connectivity changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        debugPrint('[SyncService] Online - triggering sync');
        syncPendingJobs();
      }
    });

    // Periodic sync every 5 minutes
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncPendingJobs(),
    );

    // Initial sync after 2 seconds
    Future.delayed(const Duration(seconds: 2), syncPendingJobs);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
  }

  Future<void> syncPendingJobs() async {
    if (_isSyncing || _firestore == null) return;
    _isSyncing = true;

    try {
      while (true) {
        final jobs = await _db.isar.syncJobs
            .where()
            .sortByCreatedAt()
            .limit(50)
            .findAll();
        if (jobs.isEmpty) break;

        debugPrint('[SyncService] Syncing ${jobs.length} jobs');
        var attemptedJob = false;

        for (final job in jobs) {
          if (job.retryCount >= 5) {
            attemptedJob = true;
            debugPrint(
              '[SyncService] Dropping job ${job.id} after retry limit '
              '(collection=${job.collection}, docId=${job.docId})',
            );
            await _db.isar.writeTxn(() async {
              await _db.isar.syncJobs.delete(job.id);
            });
            continue;
          }

          // Exponential backoff
          if (job.lastAttempt != null) {
            final backoffMs = min(pow(2, job.retryCount) * 1000, 60000).toInt();
            final elapsed =
                DateTime.now().difference(job.lastAttempt!).inMilliseconds;
            if (elapsed < backoffMs) continue;
          }

          attemptedJob = true;
          try {
            await _processJob(job);
            await _db.isar.writeTxn(() async {
              await _db.isar.syncJobs.delete(job.id);
            });
          } catch (e) {
            debugPrint('[SyncService] Job ${job.id} failed: $e');
            await _db.isar.writeTxn(() async {
              job.retryCount++;
              job.lastAttempt = DateTime.now();
              if (job.retryCount >= 5) {
                await _db.isar.syncJobs.delete(job.id);
              } else {
                await _db.isar.syncJobs.put(job);
              }
            });
          }
        }

        // Avoid busy-looping when all fetched jobs are still in backoff.
        if (!attemptedJob) break;
        if (jobs.length < 50) break;
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processJob(SyncJob job) async {
    if (_firestore == null) return;

    final data = jsonDecode(job.payload) as Map<String, dynamic>;
    final ref = _firestore.collection(job.collection).doc(job.docId);

    switch (job.action) {
      case 'create':
      case 'update':
        await ref.set(data, SetOptions(merge: true));
        break;
      case 'delete':
        await ref.delete();
        break;
    }
  }

  Future<void> addJob({
    required String collection,
    required String docId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    await _db.isar.writeTxn(() async {
      final existingForDoc = await _db.isar.syncJobs
          .filter()
          .collectionEqualTo(collection)
          .docIdEqualTo(docId)
          .findAll();
      final hasPendingDelete = existingForDoc.any((j) => j.action == 'delete');

      if (action == 'delete') {
        if (existingForDoc.isNotEmpty) {
          await _db.isar.syncJobs
              .deleteAll(existingForDoc.map((j) => j.id).toList());
        }

        final deleteJob = SyncJob()
          ..collection = collection
          ..docId = docId
          ..action = 'delete'
          ..payload = jsonEncode(payload)
          ..createdAt = DateTime.now()
          ..retryCount = 0;
        await _db.isar.syncJobs.put(deleteJob);
        return;
      }

      if (hasPendingDelete) {
        debugPrint(
          '[SyncService] Ignoring $action for $collection/$docId '
          'because a delete job is pending',
        );
        return;
      }

      final nonDeleteJobs =
          existingForDoc.where((j) => j.action != 'delete').toList();
      final hasPendingCreate = nonDeleteJobs.any((j) => j.action == 'create');

      if (nonDeleteJobs.isEmpty) {
        if (existingForDoc.isNotEmpty) {
          await _db.isar.syncJobs
              .deleteAll(existingForDoc.map((j) => j.id).toList());
        }

        final newJob = SyncJob()
          ..collection = collection
          ..docId = docId
          ..action = action
          ..payload = jsonEncode(payload)
          ..createdAt = DateTime.now()
          ..retryCount = 0;
        await _db.isar.syncJobs.put(newJob);
        return;
      }

      nonDeleteJobs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final primary = nonDeleteJobs.first;
      final mergedPayload = <String, dynamic>{};
      for (final job in nonDeleteJobs) {
        final decoded = jsonDecode(job.payload) as Map<String, dynamic>;
        mergedPayload.addAll(decoded);
      }
      mergedPayload.addAll(payload);

      primary
        ..action =
            (hasPendingCreate || action == 'create') ? 'create' : 'update'
        ..payload = jsonEncode(mergedPayload)
        ..lastAttempt = null
        ..retryCount = 0;
      await _db.isar.syncJobs.put(primary);

      final redundantIds =
          nonDeleteJobs.skip(1).map((job) => job.id).toList(growable: false);
      if (redundantIds.isNotEmpty) {
        await _db.isar.syncJobs.deleteAll(redundantIds);
      }
    });

    syncPendingJobs();
  }

  Future<SyncQueueStats> getQueueStats() async {
    final jobs = await _db.isar.syncJobs.where().sortByCreatedAt().findAll();
    final createJobs = jobs.where((job) => job.action == 'create').length;
    final updateJobs = jobs.where((job) => job.action == 'update').length;
    final deleteJobs = jobs.where((job) => job.action == 'delete').length;

    return SyncQueueStats(
      pendingJobs: jobs.length,
      createJobs: createJobs,
      updateJobs: updateJobs,
      deleteJobs: deleteJobs,
      oldestJobAt: jobs.isEmpty ? null : jobs.first.createdAt,
    );
  }

  Future<void> clearPendingJobs() async {
    final jobs = await _db.isar.syncJobs.where().findAll();
    final ids = jobs.map((job) => job.id).toList(growable: false);
    await _db.isar.writeTxn(() async {
      await _db.isar.syncJobs.deleteAll(ids);
    });
  }
}
