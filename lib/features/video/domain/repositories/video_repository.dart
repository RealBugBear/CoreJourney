import '../models/video_call.dart';

abstract class VideoRepository {
  /// Trainer inserts a new video_calls row and returns the created call.
  Future<VideoCall> startCall(String channelId);

  /// Sets ended_at on the given call.
  Future<void> endCall(String callId);

  /// Fetches one call by id if the authenticated user can access it.
  Future<VideoCall?> getCallById(String callId);

  /// Fetches a signed Agora token from the Edge Function.
  /// Implementations may return an empty string only in explicit development
  /// mode when certificate enforcement is disabled.
  Future<String> getAgoraToken(
    String channelId,
    String agoraChannelName, {
    required int uid,
  });

  /// Streams the active call (ended_at IS NULL) for a given channel.
  /// Emits null when no active call exists or the call has ended.
  Stream<VideoCall?> watchActiveCall(String channelId);

  /// Streams all currently active calls visible to the authenticated user.
  /// Visibility is enforced by Supabase RLS on video_calls.
  Stream<List<VideoCall>> watchActiveCalls();
}
