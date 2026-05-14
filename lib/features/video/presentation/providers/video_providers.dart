// lib/features/video/presentation/providers/video_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../bootstrap/providers.dart';
import '../../data/repositories/supabase_video_repository.dart';
import '../../domain/models/video_call.dart';
import '../../domain/repositories/video_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return SupabaseVideoRepository(allowEmptyDevToken: config.isDevelopment);
});

// ── Active call stream ────────────────────────────────────────────────────────

/// Streams the currently active VideoCall for a given channelId.
/// Emits null when no call is active or the call has ended.
final activeCallProvider =
    StreamProvider.autoDispose.family<VideoCall?, String>((ref, channelId) {
  return ref.read(videoRepositoryProvider).watchActiveCall(channelId);
});

/// Streams every active call visible to the current user. Used by the app-wide
/// incoming-call listener so it does not depend on a refreshed chat channel list.
final activeCallsProvider = StreamProvider.autoDispose<List<VideoCall>>((ref) {
  return ref.read(videoRepositoryProvider).watchActiveCalls();
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
