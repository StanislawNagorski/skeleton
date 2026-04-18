import 'package:auto_route/auto_route.dart';

import 'package:skeleton/core/router/router.dart';

/// Redirects first-run users to [OnboardingRoute].
///
/// Wired as a global guard on [AppRouter]. The [_hasSeenOnboarding] flag
/// is pre-read during startup and cached -- the guard never performs
/// async I/O inside [onNavigation] (avoids white-flash on cold start).
///
/// Re-evaluated via `reevaluateListenable` when the onboarding
/// notifier fires after the user completes onboarding.
class OnboardingGuard extends AutoRouteGuard {
  OnboardingGuard({required bool hasSeenOnboarding})
      : _hasSeenOnboarding = hasSeenOnboarding;

  bool _hasSeenOnboarding;

  /// Called by the onboarding flow to update the cached flag
  /// so the guard passes on re-evaluation.
  void markOnboardingSeen() {
    _hasSeenOnboarding = true;
  }

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_hasSeenOnboarding ||
        resolver.route.name == OnboardingRoute.name) {
      resolver.next();
    } else {
      resolver.redirectUntil(const OnboardingRoute());
    }
  }
}
