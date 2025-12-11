import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../database/database_service.dart';
import 'models/sync_job.dart';

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
      debugPrint('[SyncService] Firebase not configured - running in offline mode');
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
      final jobs = await _db.isar.syncJobs
          .where()
          .sortByCreatedAt()
          .limit(50)
          .findAll();

      debugPrint('[SyncService] Syncing ${jobs.length} jobs');

      for (final job in jobs) {
        if (job.retryCount >= 5) {
          debugPrint('[SyncService] Job ${job.id} exceeded retry limit');
          continue;
        }

        // Exponential backoff
        if (job.lastAttempt != null) {
          final backoffMs = min(pow(2, job.retryCount) * 1000, 60000).toInt();
          final elapsed =
              DateTime.now().difference(job.lastAttempt!).inMilliseconds;
          if (elapsed < backoffMs) continue;
        }

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
            await _db.isar.syncJobs.put(job);
          });
        }
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
    final job = SyncJob()
      ..collection = collection
      ..docId = docId
      ..action = action
      ..payload = jsonEncode(payload)
      ..createdAt = DateTime.now()
      ..retryCount = 0;

    await _db.isar.writeTxn(() async {
      await _db.isar.syncJobs.put(job);
    });

    syncPendingJobs();
  }
}
