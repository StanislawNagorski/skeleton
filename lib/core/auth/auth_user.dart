/// User identity exposed by `AuthService`.
///
/// Pure Dart entity -- mapping from provider-specific user types
/// (e.g. `firebase_auth.User`) happens in the service implementation.
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.emailVerified,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;

  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
  }) =>
      AuthUser(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        emailVerified: emailVerified ?? this.emailVerified,
      );
}
