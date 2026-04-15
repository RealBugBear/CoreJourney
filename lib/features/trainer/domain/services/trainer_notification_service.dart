import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/notifications/notification_service.dart';

/// Checks whether a trainer should be notified after a trainee completes
/// a training day, and fires a local notification if so.
///
/// Notification IDs 500–899 are reserved for trainer alerts.
/// No conflict with _kReminderId = 1.
class TrainerNotificationService {
  TrainerNotificationService._();
  static final TrainerNotificationService instance =
      TrainerNotificationService._();

  final _client = Supabase.instance.client;

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Called after successfully syncing a training session.
  /// Checks if the trainee has a trainer and fires the appropriate alert.
  Future<void> checkAndNotifyTrainer(
    String traineeId,
    int completedDayNumber,
  ) async {
    if (completedDayNumber != 25 && completedDayNumber != 28) return;

    try {
      final relation = await _getRelation(traineeId);
      if (relation == null) return;

      if (completedDayNumber == 25) {
        await _notify(
          traineeId: traineeId,
          title: 'Termin vorbereiten — ${relation.traineeName}',
          body:
              '${relation.traineeName} ist bei Tag 25. In ~3 Tagen ist die Isometrische Partnerübung fällig.',
          trigger: 'early_warning',
        );
      } else {
        await _notify(
          traineeId: traineeId,
          title: '${relation.traineeName} hat Tag 28 erreicht!',
          body: 'Jetzt Termin für die Isometrische Partnerübung buchen.',
          trigger: 'completion_day',
        );
      }
    } catch (e, st) {
      appLogger.e('TrainerNotificationService error', error: e, stackTrace: st);
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────────────

  Future<_TrainerRelation?> _getRelation(String traineeId) async {
    try {
      // Check the current user is the trainer of this trainee
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final rows = await _client
          .from('trainer_client_relationships')
          .select(
              'trainer_id, client_id, profiles!client_id(display_name, email)')
          .eq('client_id', traineeId)
          .eq('trainer_id', currentUserId)
          .eq('status', 'active')
          .limit(1);

      if ((rows as List).isEmpty) return null;

      final row = (rows as List).first as Map<String, dynamic>;
      final profile = row['profiles'] as Map<String, dynamic>?;
      final traineeName = (profile?['display_name'] as String?) ??
          (profile?['email'] as String?)?.split('@').first ??
          'Dein Trainee';

      return _TrainerRelation(
        trainerId: row['trainer_id'] as String,
        traineeId: traineeId,
        traineeName: traineeName,
      );
    } catch (e) {
      appLogger.w('Could not load trainer relation: $e');
      return null;
    }
  }

  Future<void> _notify({
    required String traineeId,
    required String title,
    required String body,
    required String trigger,
  }) async {
    final id = _notificationId(traineeId);
    await NotificationService.instance.showInstantNotification(
      id: id,
      title: title,
      body: body,
      payload: 'trainer_alert:$traineeId:$trigger',
    );
    appLogger.d('Trainer notification fired (id=$id, trigger=$trigger)');
  }

  /// Deterministic ID in range 500–899.
  int _notificationId(String traineeId) => 500 + traineeId.hashCode.abs() % 400;
}

class _TrainerRelation {
  final String trainerId;
  final String traineeId;
  final String traineeName;

  const _TrainerRelation({
    required this.trainerId,
    required this.traineeId,
    required this.traineeName,
  });
}
