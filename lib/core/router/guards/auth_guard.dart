import 'package:auto_route/auto_route.dart';

import 'package:skeleton/core/auth/auth_service.dart';
import 'package:skeleton/core/router/router.dart';

/// Redirects unauthenticated users to [LoginRoute].
///
/// Wired as a router-level guard via the `guards` override on [AppRouter].
/// Re-evaluated automatically via `reevaluateListenable` on every
/// [AuthService.authStateChanges] emission.
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._authService);

  final AuthService _authService;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_authService.currentUser != null) {
      resolver.next();
    } else {
      resolver.redirectUntil(const LoginRoute());
    }
  }
}
