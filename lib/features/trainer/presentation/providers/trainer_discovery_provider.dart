import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_trainer_profile_repository.dart';
import '../../domain/models/trainer_discovery_request.dart';
import '../../domain/models/trainer_profile.dart';
import '../../domain/repositories/trainer_profile_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final trainerProfileRepositoryProvider = Provider<TrainerProfileRepository>(
  (ref) => SupabaseTrainerProfileRepository(Supabase.instance.client),
);

// ── Own trainer profile ───────────────────────────────────────────────────────

final ownTrainerProfileProvider = FutureProvider<TrainerProfile?>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(trainerProfileRepositoryProvider).getOwnProfile();
});

// ── Nearby trainer search ─────────────────────────────────────────────────────

class NearbyParams {
  const NearbyParams({
    required this.lat,
    required this.lng,
    required this.radiusKm,
  });
  final double lat;
  final double lng;
  final double radiusKm;
}

final nearbyTrainersProvider =
    FutureProvider.family<List<TrainerProfile>, NearbyParams>(
  (ref, params) => ref.read(trainerProfileRepositoryProvider).findNearby(
        lat: params.lat,
        lng: params.lng,
        radiusKm: params.radiusKm,
      ),
);

// ── Pending trainers (admin) ──────────────────────────────────────────────────

class PendingTrainersNotifier extends AsyncNotifier<List<TrainerProfile>> {
  @override
  Future<List<TrainerProfile>> build() {
    ref.watch(authStateProvider);
    return ref.read(trainerProfileRepositoryProvider).getPendingTrainers();
  }

  Future<void> approve(String trainerId) async {
    await ref.read(trainerProfileRepositoryProvider).approveTrainer(trainerId);
    ref.invalidateSelf();
  }

  Future<void> suspend(String trainerId) async {
    await ref.read(trainerProfileRepositoryProvider).suspendTrainer(trainerId);
    ref.invalidateSelf();
  }
}

final pendingTrainersProvider =
    AsyncNotifierProvider<PendingTrainersNotifier, List<TrainerProfile>>(
  PendingTrainersNotifier.new,
);

// ── Incoming discovery requests (trainer) ─────────────────────────────────────

class IncomingRequestsNotifier
    extends AsyncNotifier<List<TrainerDiscoveryRequest>> {
  @override
  Future<List<TrainerDiscoveryRequest>> build() {
    ref.watch(authStateProvider);
    return ref
        .read(trainerProfileRepositoryProvider)
        .getIncomingRequests();
  }

  Future<void> respond(String relationshipId, {required bool accept}) async {
    await ref
        .read(trainerProfileRepositoryProvider)
        .respondToRequest(relationshipId, accept: accept);
    ref.invalidateSelf();
  }
}

final incomingRequestsProvider =
    AsyncNotifierProvider<IncomingRequestsNotifier,
        List<TrainerDiscoveryRequest>>(
  IncomingRequestsNotifier.new,
);

// ── Send connection request ───────────────────────────────────────────────────

Future<void> sendDiscoveryRequest(Ref ref, String trainerId) {
  return ref.read(trainerProfileRepositoryProvider).sendConnectionRequest(trainerId);
}
