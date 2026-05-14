import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/models/profile.dart';

class ProfileRepository {
  final _client = Supabase.instance.client;

  Future<Profile?> getProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return Profile.fromJson(data);
    } catch (e, st) {
      appLogger.e('ProfileRepository.getProfile failed', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> upsertProfile(Profile profile) async {
    try {
      await _client.from('profiles').upsert(
            profile.toJson(),
            onConflict: 'id',
          );
      appLogger.d('ProfileRepository: upserted profile for ${profile.userId}');
    } catch (e, st) {
      appLogger.e('ProfileRepository.upsertProfile failed', error: e, stackTrace: st);
      rethrow;
    }
  }
}
