import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;
  User? get currentUser;
  Future<void> signInWithEmail({required String email, required String password});
  Future<void> signUpWithEmail({required String email, required String password});
  Future<void> sendPasswordReset({required String email});
  Future<void> signOut();
}
