// lib/features/video/presentation/providers/video_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supabase_video_repository.dart';
import '../../domain/models/video_call.dart';
import '../../domain/repositories/video_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return SupabaseVideoRepository();
});

// ── Active call stream ────────────────────────────────────────────────────────

/// Streams the currently active VideoCall for a given channelId.
/// Emits null when no call is active or the call has ended.
final activeCallProvider =
    StreamProvider.autoDispose.family<VideoCall?, String>((ref, channelId) {
  return ref.read(videoRepositoryProvider).watchActiveCall(channelId);
});

// ── Start call notifier ───────────────────────────────────────────────────────

class StartCallNotifier extends AutoDisposeAsyncNotifier<VideoCall?> {
  @override
  Future<VideoCall?> build() async => null;

  /// Returns the created VideoCall on success, null on error.
  Future<VideoCall?> start(String channelId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(videoRepositoryProvider).startCall(channelId),
    );
    state = result;
    return result.valueOrNull;
  }
}

final startCallProvider =
    AsyncNotifierProvider.autoDispose<StartCallNotifier, VideoCall?>(
  StartCallNotifier.new,
);

// ── End call notifier ─────────────────────────────────────────────────────────

class EndCallNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> end(String callId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(videoRepositoryProvider).endCall(callId),
    );
  }
}

final endCallProvider =
    AsyncNotifierProvider.autoDispose<EndCallNotifier, void>(
  EndCallNotifier.new,
);
