import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signInWithEmail(email: email, password: password),
    );
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signUpWithEmail(email: email, password: password),
    );
  }

  Future<void> sendPasswordReset({required String email}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.sendPasswordReset(email: email),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.signOut());
  }

  void clearError() {
    if (state.hasError) state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
