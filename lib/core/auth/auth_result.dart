import 'package:skeleton/core/auth/auth_user.dart';
import 'package:skeleton/core/errors/failures.dart';

/// Sealed result type for authentication operations.
///
/// Unlike [Result<T>], auth operations have a third state — cancellation
/// (e.g. user dismisses the Google/Apple sign-in sheet).
///
/// Use exhaustive `switch` pattern matching to consume:
/// ```dart
/// switch (result) {
///   case AuthSuccess(:final user): // handle success
///   case AuthFailure(:final failure): // handle failure
///   case AuthCancelled(): // handle cancellation
/// }
/// ```
sealed class AuthResult {
  const AuthResult();
}

/// Authentication succeeded, carrying the authenticated [user].
final class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user);
  final AuthUser user;
}

/// Authentication failed with an [AppFailure].
final class AuthFailure extends AuthResult {
  const AuthFailure(this.failure);
  final AppFailure failure;
}

/// Authentication was cancelled by the user.
final class AuthCancelled extends AuthResult {
  const AuthCancelled();
}
