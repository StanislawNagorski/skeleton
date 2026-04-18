import 'dart:async';

import 'package:injectable/injectable.dart';

import 'package:skeleton/core/auth/auth_result.dart';
import 'package:skeleton/core/auth/auth_service.dart';
import 'package:skeleton/core/auth/auth_user.dart';

/// In-memory [AuthService] for development without Firebase.
///
/// Signs in any email/password combination, returns a deterministic
/// [AuthUser] with `uid` derived from the email.  Kept permanently as a
/// test double and as the fallback when no Firebase config is present.
@LazySingleton(as: AuthService, env: [Environment.dev])
class FakeAuthService implements AuthService {
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  AuthUser? _currentUser;

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final user = AuthUser(
      uid: 'fake-${email.hashCode}',
      email: email,
      displayName: null,
      photoUrl: null,
      emailVerified: false,
    );
    _currentUser = user;
    _controller.add(user);
    return AuthSuccess(user);
  }

  @override
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final user = AuthUser(
      uid: 'fake-${email.hashCode}',
      email: email,
      displayName: null,
      photoUrl: null,
      emailVerified: false,
    );
    _currentUser = user;
    _controller.add(user);
    return AuthSuccess(user);
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    return const AuthCancelled();
  }

  @override
  Future<AuthResult> signInWithApple() async {
    return const AuthCancelled();
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<AuthResult> sendPasswordReset({required String email}) async {
    return AuthSuccess(
      AuthUser(
        uid: 'fake-${email.hashCode}',
        email: email,
        displayName: null,
        photoUrl: null,
        emailVerified: false,
      ),
    );
  }

  /// Releases the internal [StreamController].
  ///
  /// Called by `get_it.disposeDependencies()` during test teardown.
  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
