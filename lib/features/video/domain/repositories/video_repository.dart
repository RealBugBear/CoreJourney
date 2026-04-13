import '../models/video_call.dart';

abstract class VideoRepository {
  /// Trainer inserts a new video_calls row and returns the created call.
  Future<VideoCall> startCall(String channelId);

  /// Sets ended_at on the given call.
  Future<void> endCall(String callId);

  /// Fetches a signed Agora token from the Edge Function.
  /// Returns empty string in dev mode (certificate enforcement disabled).
  Future<String> getAgoraToken(String channelId, String agoraChannelName);

  /// Streams the active call (ended_at IS NULL) for a given channel.
  /// Emits null when no active call exists or the call has ended.
  Stream<VideoCall?> watchActiveCall(String channelId);
}
