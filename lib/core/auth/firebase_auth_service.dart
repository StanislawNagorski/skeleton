import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:skeleton/core/auth/auth_result.dart';
import 'package:skeleton/core/auth/auth_service.dart';
import 'package:skeleton/core/auth/auth_user.dart';
import 'package:skeleton/core/errors/failures.dart';

/// Production [AuthService] backed by Firebase Auth.
///
/// Registered in the `'prod'` DI environment -- only available when
/// `Firebase.initializeApp` succeeds (i.e. `flutterfire configure`
/// has been run).
///
/// Supports three sign-in providers:
/// - Email + Password (AUTH-02)
/// - Google Sign-In via google_sign_in 7.x (AUTH-03)
/// - Apple Sign-In with SHA-256 nonce replay protection (AUTH-04)
@LazySingleton(as: AuthService, env: [Environment.prod])
class FirebaseAuthService implements AuthService {
  FirebaseAuthService() {
    _subscription = FirebaseAuth.instance
        .authStateChanges()
        .map(_mapUser)
        .listen(_controller.add);
  }

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();
  late final StreamSubscription<AuthUser?> _subscription;

  /// Tracks whether Google Sign-In has been initialized this session.
  bool _googleSignInInitialized = false;

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _mapUser(FirebaseAuth.instance.currentUser);

  // -- Email + Password (AUTH-02) --

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return AuthSuccess(_mapUser(credential.user)!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(AuthError(_mapAuthErrorCode(e.code)));
    } on Exception catch (e) {
      return AuthFailure(AuthError(e.toString()));
    }
  }

  @override
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return AuthSuccess(_mapUser(credential.user)!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(AuthError(_mapAuthErrorCode(e.code)));
    } on Exception catch (e) {
      return AuthFailure(AuthError(e.toString()));
    }
  }

  // -- Google Sign-In (AUTH-03) --
  //
  // Uses google_sign_in 7.x singleton API:
  //   1. initialize(serverClientId) -- once per session
  //   2. authenticate() -- returns GoogleSignInAccount
  //   3. account.authentication.idToken -- for Firebase credential
  //
  // The serverClientId (Web OAuth client ID) is auto-detected from
  // google-services.json on Android. On iOS it is read from
  // GoogleService-Info.plist. Per D-05, zero manual config is needed
  // after `flutterfire configure`.

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;

      // Initialize once per app session. On Android, serverClientId is
      // auto-read from google-services.json if present. On iOS, the
      // client ID comes from GoogleService-Info.plist.
      if (!_googleSignInInitialized) {
        await googleSignIn.initialize();
        _googleSignInInitialized = true;
      }

      // Trigger the interactive sign-in flow.
      final account = await googleSignIn.authenticate();

      // Extract the idToken from the authentication result.
      final idToken = account.authentication.idToken;

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      return AuthSuccess(_mapUser(userCredential.user)!);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const AuthCancelled();
      }
      return AuthFailure(AuthError(e.description ?? e.code.name));
    } on FirebaseAuthException catch (e) {
      return AuthFailure(AuthError(_mapAuthErrorCode(e.code)));
    } on Exception catch (e) {
      return AuthFailure(AuthError(e.toString()));
    }
  }

  // -- Apple Sign-In (AUTH-04) --
  //
  // SHA-256 nonce prevents replay attacks (T-04-07).
  // Apple returns email/name only on first sign-in (Pitfall 2).

  @override
  Future<AuthResult> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      return AuthSuccess(_mapUser(userCredential.user)!);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const AuthCancelled();
      }
      return AuthFailure(AuthError(e.toString()));
    } on FirebaseAuthException catch (e) {
      return AuthFailure(AuthError(_mapAuthErrorCode(e.code)));
    } on Exception catch (e) {
      return AuthFailure(AuthError(e.toString()));
    }
  }

  // -- Sign Out (AUTH-06) --

  @override
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
    // authStateChanges emits null via the Firebase stream subscription.
  }

  // -- Password Reset --

  @override
  Future<AuthResult> sendPasswordReset({required String email}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      // Firebase sends the reset email regardless of whether the account
      // exists, preventing user enumeration (T-04-12).
      return AuthSuccess(AuthUser(
        uid: email,
        email: email,
        displayName: null,
        photoUrl: null,
        emailVerified: false,
      ));
    } on FirebaseAuthException catch (e) {
      return AuthFailure(AuthError(_mapAuthErrorCode(e.code)));
    } on Exception catch (e) {
      return AuthFailure(AuthError(e.toString()));
    }
  }

  // -- Helpers --

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  /// Maps Firebase error codes to user-readable messages.
  ///
  /// Generic enough that internal Firebase details do not leak to the UI
  /// (T-04-09), while still being actionable for the end user.
  String _mapAuthErrorCode(String code) => switch (code) {
        'user-not-found' => 'No account found with this email.',
        'wrong-password' => 'Incorrect password.',
        'invalid-email' => 'Invalid email address.',
        'user-disabled' => 'This account has been disabled.',
        'email-already-in-use' =>
          'An account already exists with this email.',
        'weak-password' => 'Password is too weak.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'operation-not-allowed' => 'This sign-in method is not enabled.',
        'invalid-credential' => 'Invalid credentials.',
        _ => 'Authentication error: $code',
      };

  /// Generates a cryptographically secure random nonce string.
  ///
  /// Used for Apple Sign-In replay protection. Produces a 32-byte random
  /// value encoded as a 64-character hex string.
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Releases resources. Called by get_it during app teardown.
  @override
  @disposeMethod
  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
  }
}
