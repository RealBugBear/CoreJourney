import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/models/training_session.dart';

class TrainingRepository {
  final DatabaseService _db;
  final SyncService _sync;
  final String _userId;

  TrainingRepository(this._db, this._sync, this._userId);

  Future<TrainingSession> createSession({
    required int dayNumber,
    required String exercisePackage,
  }) async {
    final session = TrainingSession()
      ..userId = _userId
      ..date = DateTime.now()
      ..dayNumber = dayNumber
      ..exercisePackage = exercisePackage
      ..completedExercises = []
      ..isCompleted = false
      ..firestoreId = const Uuid().v4()
      ..needsSync = true;

    await _db.isar.writeTxn(() async {
      await _db.isar.trainingSessions.put(session);
    });

    // Queue for sync
    await _sync.addJob(
      collection: 'trainingSessions',
      docId: session.firestoreId,
      action: 'create',
      payload: {
        'userId': session.userId,
        'date': session.date.toIso8601String(),
        'dayNumber': session.dayNumber,
        'exercisePackage': session.exercisePackage,
        'completedExercises': session.completedExercises,
        'isCompleted': session.isCompleted,
      },
    );

    return session;
  }

  Future<void> completeSession(TrainingSession session) async {
    session.isCompleted = true;
    session.completedAt = DateTime.now();
    session.needsSync = true;

    await _db.isar.writeTxn(() async {
      await _db.isar.trainingSessions.put(session);
    });

    await _sync.addJob(
      collection: 'trainingSessions',
      docId: session.firestoreId,
      action: 'update',
      payload: {
        'isCompleted': true,
        'completedAt': session.completedAt!.toIso8601String(),
      },
    );
  }

  Future<TrainingSession?> getTodaySession() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await _db.isar.trainingSessions
        .filter()
        .userIdEqualTo(_userId)
        .dateBetween(startOfDay, endOfDay)
        .findFirst();
  }

  Stream<List<TrainingSession>> watchAllSessions() {
    return _db.isar.trainingSessions
        .filter()
        .userIdEqualTo(_userId)
        .watch(fireImmediately: true);
  }
}
