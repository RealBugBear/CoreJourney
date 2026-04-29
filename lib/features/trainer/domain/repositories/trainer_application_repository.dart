import '../models/trainer_application.dart';

abstract class TrainerApplicationRepository {
  Future<TrainerApplication?> getOwnApplication();

  Future<String> submitApplication({
    required String fullName,
    required String email,
    String? phone,
    String? city,
    required String professionalBackground,
    String? motivation,
    String? desiredDisplayName,
    String? desiredBio,
    double? lat,
    double? lng,
  });

  Future<List<TrainerApplication>> getApplicationsForReview();

  Future<void> markBackgroundCheckSeen(String applicationId);

  Future<void> setStatus(
    String applicationId,
    String status, {
    String? reason,
  });

  Future<String> approve(String applicationId);
}
