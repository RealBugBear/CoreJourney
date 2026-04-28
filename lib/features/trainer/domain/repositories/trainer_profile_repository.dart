import '../models/trainer_discovery_request.dart';
import '../models/trainer_profile.dart';

abstract class TrainerProfileRepository {
  Future<List<TrainerProfile>> findNearby({
    required double lat,
    required double lng,
    double radiusKm = 25,
  });

  Future<TrainerProfile?> getOwnProfile();

  Future<void> upsertProfile({
    required String displayName,
    String? bio,
    String? photoUrl,
    required String contactEmail,
    String? contactPhone,
  });

  Future<void> updateLocation(double lat, double lng);

  Future<List<TrainerProfile>> getPendingTrainers();

  Future<void> approveTrainer(String trainerId);

  Future<void> suspendTrainer(String trainerId);

  Future<void> sendConnectionRequest(String trainerId);

  Future<List<TrainerDiscoveryRequest>> getIncomingRequests();

  Future<void> respondToRequest(String relationshipId, {required bool accept});
}
