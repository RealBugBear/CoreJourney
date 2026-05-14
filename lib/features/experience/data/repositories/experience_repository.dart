import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/models/experience_share.dart';

class ExperienceRepository {
  final _client = Supabase.instance.client;

  /// Fetches the latest 50 shares for a package, ordered newest first.
  Future<List<ExperienceShare>> getShares(String packageId) async {
    try {
      final data = await _client
          .from('experience_shares')
          .select()
          .eq('package_id', packageId)
          .order('created_at', ascending: false)
          .limit(50);
      return (data as List)
          .map((e) => ExperienceShare.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      appLogger.e('ExperienceRepository.getShares failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> createShare(ExperienceShareInsert insert) async {
    try {
      await _client.from('experience_shares').insert(insert.toJson());
      appLogger.d('ExperienceRepository: share created for package ${insert.packageId}');
    } catch (e, st) {
      appLogger.e('ExperienceRepository.createShare failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes own share. Moderators call [moderatorDeleteShare].
  Future<void> deleteOwnShare(String shareId) async {
    try {
      await _client.from('experience_shares').delete().eq('id', shareId);
      appLogger.d('ExperienceRepository: deleted share $shareId');
    } catch (e, st) {
      appLogger.e('ExperienceRepository.deleteOwnShare failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Calls the SECURITY DEFINER RPC so moderators can delete any share.
  Future<void> moderatorDeleteShare(String shareId) async {
    try {
      await _client.rpc('moderator_delete_experience_share', params: {'share_id': shareId});
      appLogger.d('ExperienceRepository: moderator deleted share $shareId');
    } catch (e, st) {
      appLogger.e('ExperienceRepository.moderatorDeleteShare failed', error: e, stackTrace: st);
      rethrow;
    }
  }
}
