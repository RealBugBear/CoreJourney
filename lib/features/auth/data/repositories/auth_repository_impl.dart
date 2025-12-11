import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/models/user.dart' as domain;
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final fb.FirebaseAuth _auth;

  AuthRepositoryImpl({fb.FirebaseAuth? auth})
      : _auth = auth ?? fb.FirebaseAuth.instance;

  @override
  Stream<domain.User?> get authStateChanges {
    return _auth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  domain.User? get currentUser {
    final user = _auth.currentUser;
    return user != null ? _mapFirebaseUser(user) : null;
  }

  @override
  Future<domain.User> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapFirebaseUser(credential.user)!;
  }

  @override
  Future<domain.User> signUpWithEmail(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapFirebaseUser(credential.user)!;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  domain.User? _mapFirebaseUser(fb.User? user) {
    if (user == null) return null;
    
    return domain.User(
      id: user.uid,
      email: user.email!,
      displayName: user.displayName,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }
}
