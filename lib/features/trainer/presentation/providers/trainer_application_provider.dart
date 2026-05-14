import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_trainer_application_repository.dart';
import '../../domain/models/trainer_application.dart';
import '../../domain/repositories/trainer_application_repository.dart';

final trainerApplicationRepositoryProvider =
    Provider<TrainerApplicationRepository>(
  (ref) => SupabaseTrainerApplicationRepository(Supabase.instance.client),
);

final ownTrainerApplicationProvider =
    FutureProvider<TrainerApplication?>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(trainerApplicationRepositoryProvider).getOwnApplication();
});

class TrainerApplicationsReviewNotifier
    extends AsyncNotifier<List<TrainerApplication>> {
  @override
  Future<List<TrainerApplication>> build() {
    ref.watch(authStateProvider);
    return ref
        .read(trainerApplicationRepositoryProvider)
        .getApplicationsForReview();
  }

  Future<void> markBackgroundCheckSeen(String applicationId) async {
    await ref
        .read(trainerApplicationRepositoryProvider)
        .markBackgroundCheckSeen(applicationId);
    ref.invalidateSelf();
  }

  Future<String> approve(String applicationId) async {
    final code = await ref
        .read(trainerApplicationRepositoryProvider)
        .approve(applicationId);
    ref.invalidateSelf();
    return code;
  }

  Future<void> needsMoreInfo(String applicationId) async {
    await ref
        .read(trainerApplicationRepositoryProvider)
        .setStatus(applicationId, 'needs_more_info');
    ref.invalidateSelf();
  }

  Future<void> reject(String applicationId, {String? reason}) async {
    await ref
        .read(trainerApplicationRepositoryProvider)
        .setStatus(applicationId, 'rejected', reason: reason);
    ref.invalidateSelf();
  }
}

final trainerApplicationsForReviewProvider = AsyncNotifierProvider<
    TrainerApplicationsReviewNotifier, List<TrainerApplication>>(
  TrainerApplicationsReviewNotifier.new,
);
