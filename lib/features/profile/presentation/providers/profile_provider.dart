import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((_) => ProfileRepository());

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile?>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    // Re-run whenever the auth user changes (sign-in / sign-out / account switch).
    final authState = await ref.watch(authStateProvider.future);
    final userId = authState.session?.user.id;
    if (userId == null) return null;
    return ref.read(profileRepositoryProvider).getProfile(userId);
  }

  Future<void> save({String? displayName, bool? isAnonymousDefault}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final current = state.valueOrNull;
    final updated = Profile(
      userId: userId,
      displayName: displayName ?? current?.displayName,
      isAnonymousDefault: isAnonymousDefault ?? current?.isAnonymousDefault ?? false,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRepositoryProvider).upsertProfile(updated);
      return updated;
    });
  }
}
