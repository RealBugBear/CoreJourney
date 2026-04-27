import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/trainer_discovery_request.dart';
import '../../domain/models/trainer_profile.dart';
import '../../domain/repositories/trainer_profile_repository.dart';

class SupabaseTrainerProfileRepository implements TrainerProfileRepository {
  SupabaseTrainerProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<TrainerProfile>> findNearby({
    required double lat,
    required double lng,
    double radiusKm = 25,
  }) async {
    final res = await _client.rpc('find_trainers_nearby', params: {
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
    });
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(TrainerProfile.fromJson)
        .toList();
  }

  @override
  Future<TrainerProfile?> getOwnProfile() async {
    final res = await _client.rpc('get_own_trainer_profile');
    final list = (res as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    return TrainerProfile.fromJson(list.first);
  }

  @override
  Future<void> upsertProfile({
    required String displayName,
    String? bio,
    String? photoUrl,
    required String contactEmail,
    String? contactPhone,
  }) async {
    await _client.rpc('upsert_trainer_profile', params: {
      'p_display_name': displayName,
      'p_bio': bio,
      'p_photo_url': photoUrl,
      'p_contact_email': contactEmail,
      'p_contact_phone': contactPhone,
    });
  }

  @override
  Future<void> updateLocation(double lat, double lng) async {
    await _client.rpc('upsert_trainer_location', params: {
      'p_lat': lat,
      'p_lng': lng,
    });
  }

  @override
  Future<List<TrainerProfile>> getPendingTrainers() async {
    final res = await _client.rpc('get_pending_trainers');
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(TrainerProfile.fromJson)
        .toList();
  }

  @override
  Future<void> approveTrainer(String trainerId) async {
    await _client.rpc('admin_approve_trainer', params: {
      'p_trainer_id': trainerId,
    });
  }

  @override
  Future<void> suspendTrainer(String trainerId) async {
    await _client.rpc('admin_suspend_trainer', params: {
      'p_trainer_id': trainerId,
    });
  }

  @override
  Future<void> sendConnectionRequest(String trainerId) async {
    await _client.rpc('send_discovery_request', params: {
      'p_trainer_id': trainerId,
    });
  }

  @override
  Future<List<TrainerDiscoveryRequest>> getIncomingRequests() async {
    final res = await _client.rpc('get_incoming_discovery_requests');
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(TrainerDiscoveryRequest.fromJson)
        .toList();
  }

  @override
  Future<void> respondToRequest(
    String relationshipId, {
    required bool accept,
  }) async {
    await _client.rpc('respond_discovery_request', params: {
      'p_relationship_id': relationshipId,
      'p_accept': accept,
    });
  }
}
