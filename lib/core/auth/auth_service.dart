import 'package:skeleton/core/auth/auth_result.dart';
import 'package:skeleton/core/auth/auth_user.dart';

/// Central authentication boundary.
///
/// Exposes a reactive [authStateChanges] stream and request-response methods
/// for every supported sign-in provider.  Implementations:
/// - `FakeAuthService` — in-memory, ships with the skeleton (Phase 3)
/// - `FirebaseAuthService` — real Firebase Auth (Phase 5)
abstract class AuthService {
  /// Emits the current [AuthUser] on sign-in, `null` on sign-out.
  Stream<AuthUser?> get authStateChanges;

  /// The currently signed-in user, or `null` if signed out.
  AuthUser? get currentUser;

  /// Signs in with email + password.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates a new account with email + password.
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Initiates Google Sign-In flow.
  Future<AuthResult> signInWithGoogle();

  /// Initiates Apple Sign-In flow.
  Future<AuthResult> signInWithApple();

  /// Signs out of all active providers.
  Future<void> signOut();

  /// Sends a password-reset email.
  Future<AuthResult> sendPasswordReset({required String email});

  /// Releases resources (stream subscriptions, controllers).
  ///
  /// Called by `get_it` when disposing singletons.
  Future<void> dispose();
}
