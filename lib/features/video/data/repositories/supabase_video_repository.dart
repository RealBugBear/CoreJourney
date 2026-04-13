// lib/features/video/data/repositories/supabase_video_repository.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/video_call.dart';
import '../../domain/repositories/video_repository.dart';

class SupabaseVideoRepository implements VideoRepository {
  final _client = Supabase.instance.client;

  @override
  Future<VideoCall> startCall(String channelId) async {
    final now = DateTime.now();
    // Short Agora channel name: prefix + first 8 chars of channel UUID (no dashes) + timestamp.
    // Agora channel names must be ≤ 64 chars, alphanumeric + underscore only.
    final shortId = channelId.replaceAll('-', '').substring(0, 8);
    final agoraChannelName = 'cj_${shortId}_${now.millisecondsSinceEpoch}';
    final userId = _client.auth.currentUser!.id;

    final data = await _client.from('video_calls').insert({
      'channel_id': channelId,
      'agora_channel_name': agoraChannelName,
      'started_by': userId,
    }).select().single();

    return VideoCall.fromJson(data);
  }

  @override
  Future<void> endCall(String callId) async {
    await _client
        .from('video_calls')
        .update({'ended_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', callId);
  }

  @override
  Future<String> getAgoraToken(
    String channelId,
    String agoraChannelName,
  ) async {
    try {
      final response = await _client.functions.invoke(
        'agora-token',
        body: {
          'channel_id': channelId,
          'agora_channel_name': agoraChannelName,
        },
      );
      final token =
          (response.data as Map<String, dynamic>)['token'] as String? ?? '';
      return token;
    } catch (e) {
      // Dev fallback: return empty string when Edge Function is not deployed yet.
      // Works when Agora project has certificate enforcement disabled.
      debugPrint('getAgoraToken error (using empty token): $e');
      return '';
    }
  }

  @override
  Stream<VideoCall?> watchActiveCall(String channelId) {
    return _client
        .from('video_calls')
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('started_at', ascending: false)
        .limit(10)
        .map((rows) {
          // Find the most recent row with ended_at = null.
          for (final row in rows) {
            if (row['ended_at'] == null) {
              return VideoCall.fromJson(row);
            }
          }
          return null;
        });
  }
}
