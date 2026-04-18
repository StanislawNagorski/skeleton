---
phase: 05-ux-patterns-onboarding-rive-splash-coach-marks
reviewed: 2026-04-18T12:00:00Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - lib/app.dart
  - lib/core/coach_mark/coach_mark_service.dart
  - lib/core/injectable/injection.config.dart
  - lib/core/preferences/preferences_keys.dart
  - lib/core/presentation/app_dimensions.dart
  - lib/core/router/guards/onboarding_guard.dart
  - lib/core/router/router.dart
  - lib/features/home_page/presentation/home_page.dart
  - lib/features/onboarding/presentation/cubit/onboarding_cubit.dart
  - lib/features/onboarding/presentation/cubit/onboarding_state.dart
  - lib/features/onboarding/presentation/onboarding_page.dart
  - lib/features/onboarding/presentation/widgets/dot_indicator.dart
  - lib/features/onboarding/presentation/widgets/onboarding_slide.dart
  - lib/features/rive_demo/presentation/cubit/rive_demo_cubit.dart
  - lib/features/rive_demo/presentation/cubit/rive_demo_state.dart
  - lib/features/rive_demo/presentation/rive_demo_page.dart
  - lib/main.dart
  - lib/startup_service.dart
findings:
  critical: 1
  warning: 5
  info: 3
  total: 9
status: issues_found
---

# Phase 5: Code Review Report

**Reviewed:** 2026-04-18T12:00:00Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

This review covers the Phase 5 UX patterns implementation: onboarding flow, RIVE demo page, coach marks service, and supporting infrastructure (router guards, preferences, DI wiring). The architecture is solid -- clean separation between cubit logic and presentation, proper guard-based onboarding gating, and correct RIVE resource lifecycle management. However, there is one critical resource leak in the startup service, several missing error-handling paths, and a key consistency issue between `PreferencesKeys` and `CoachMarkService`.

## Critical Issues

### CR-01: RawReceivePort never closed -- resource leak and prevents clean isolate shutdown

**File:** `lib/startup_service.dart:83-94`
**Issue:** `_configureCrashlytics()` creates a `RawReceivePort` for isolate error listening but never stores or closes it. The port remains open for the lifetime of the app, which is normally fine for a main isolate, but it also means the main isolate can never cleanly shut down (the open port keeps the event loop alive). More importantly, if `_configureCrashlytics()` were ever called more than once (e.g., during hot restart in debug -- though currently guarded by `kReleaseMode` for collection, the listener itself is always registered), duplicate ports accumulate with no way to close them.
**Fix:** Store the `RawReceivePort` in a static field so it can be closed if needed, and guard against double-registration:
```dart
static RawReceivePort? _errorPort;

static void _configureCrashlytics() {
  FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(kReleaseMode);

  FlutterError.onError =
      FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance
        .recordError(error, stack, fatal: true);
    return true;
  };

  // Guard against duplicate registration on hot restart.
  _errorPort?.close();
  _errorPort = RawReceivePort((dynamic pair) async {
    final errorAndStack = pair as List<dynamic>;
    await FirebaseCrashlytics.instance.recordError(
      errorAndStack[0],
      StackTrace.fromString(errorAndStack[1] as String),
      fatal: true,
    );
  });
  Isolate.current.addErrorListener(_errorPort!.sendPort);
}
```

## Warnings

### WR-01: CoachMarkService uses inline key string instead of PreferencesKeys constant

**File:** `lib/core/coach_mark/coach_mark_service.dart:49`
**Issue:** The coach mark service constructs its preference key as `'tour_${tourId}_seen'` inline. Meanwhile, `PreferencesKeys` already defines `tourHomeCompleted = 'tour_home_seen'` for the home tour. This creates a fragile coupling -- if someone changes the constant in `PreferencesKeys`, the `CoachMarkService` will still use the old format, and vice versa. There is also no centralized visibility into which preference keys exist.
**Fix:** Either have `CoachMarkService` accept the full key from callers (so they can use `PreferencesKeys` constants), or document clearly that the key format is owned by `CoachMarkService` and remove the redundant constant from `PreferencesKeys`:
```dart
// Option A: Remove PreferencesKeys.tourHomeCompleted, document that
// CoachMarkService owns the 'tour_{tourId}_seen' pattern.

// Option B: Accept explicit key:
Future<void> showTour(String tourId, BuildContext context, {String? prefKey}) async {
  final key = prefKey ?? 'tour_${tourId}_seen';
  // ...
}
```

### WR-02: OnboardingCubit registered as factory but depends on OnboardingGuard singleton registered manually

**File:** `lib/core/injectable/injection.config.dart:80-85`
**Issue:** The generated DI code shows `OnboardingCubit` depends on `gh<OnboardingGuard>()`, but `OnboardingGuard` is registered manually in `main.dart:29` via `getIt.registerSingleton<OnboardingGuard>(onboardingGuard)`. This works at runtime because `main()` runs before any cubit is resolved. However, the generated code references `OnboardingGuard` as if it were a standard injectable -- if someone runs `build_runner` and the generator does not find the manual registration, it may fail or produce incorrect code. The coupling between manual and generated registration is fragile.
**Fix:** Consider annotating `OnboardingGuard` with `@injectable` and using a factory method or `@module` to supply the `hasSeenOnboarding` parameter, keeping all DI declarations in one system. Alternatively, add a comment in `main.dart` explaining the deliberate manual registration and its ordering requirement.

### WR-03: _buildLoadedAnimation sets state-machine input during build -- side effect in build method

**File:** `lib/features/rive_demo/presentation/rive_demo_page.dart:130-141`
**Issue:** `_buildLoadedAnimation` reads cubit state and writes to `_toggleInput?.value` every time the widget rebuilds. Setting RIVE state-machine inputs is a side effect that should not occur during the build phase. If the widget rebuilds for unrelated reasons (e.g., theme change, parent rebuild), it will redundantly set the toggle input.
**Fix:** Move the input sync to the `onChanged` callback only (already done at line 108), and set the initial value once when acquiring the handle:
```dart
Widget _buildLoadedAnimation(
  BuildContext context,
  RiveWidgetController controller,
) {
  if (_toggleInput == null) {
    // ignore: deprecated_member_use
    _toggleInput = controller.stateMachine.boolean('Toggle');
    // Set initial value from cubit state.
    _toggleInput?.value = context.read<RiveDemoCubit>().state.isToggled;
  }
  return RiveWidget(controller: controller);
}
```

### WR-04: CoachMarkService.showTour captures BuildContext across async gap

**File:** `lib/core/coach_mark/coach_mark_service.dart:48-127`
**Issue:** `showTour` is an async method that receives a `BuildContext`, awaits `_preferencesService.getBool(prefKey)`, and then uses the context in `addPostFrameCallback`. While there is a `context.mounted` check at line 57, the context is captured in the closure at line 56. If the widget is disposed between the `await` and the callback execution, the `mounted` check catches it -- but a cleaner pattern would be to check `mounted` immediately after the await as well, before scheduling the callback.
**Fix:** Add an early return after the async gap:
```dart
final seen = await _preferencesService.getBool(prefKey);
if (seen ?? false) return;

final targets = _tours[tourId];
if (targets == null || targets.isEmpty) return;

// Check mounted before scheduling (context may have been disposed
// during the async gap above).
if (!context.mounted) return;

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!context.mounted) return;
  // ...
});
```

### WR-05: OnboardingPage uses magic number for button height

**File:** `lib/features/onboarding/presentation/onboarding_page.dart:127`
**Issue:** The `FilledButton` has a hardcoded `height: 48`. This should be an `AppDimensions` constant for consistency with the rest of the design system.
**Fix:**
```dart
// In app_dimensions.dart:
static const double buttonHeight = 48;

// In onboarding_page.dart:
height: AppDimensions.buttonHeight,
```

## Info

### IN-01: OnboardingSlide image dimensions are hardcoded

**File:** `lib/features/onboarding/presentation/widgets/onboarding_slide.dart:29-30`
**Issue:** `Image.asset` uses hardcoded `width: 200, height: 200`. These could be `AppDimensions` constants for easier theming across downstream apps.
**Fix:** Extract to `AppDimensions.onboardingImageSize = 200`.

### IN-02: RIVE demo page has hardcoded height for animation card

**File:** `lib/features/rive_demo/presentation/rive_demo_page.dart:74`
**Issue:** `height: 300` is a magic number. Consider extracting to an `AppDimensions` constant.
**Fix:** `AppDimensions.riveCanvasHeight = 300` or similar.

### IN-03: AuthGuard applied only to LoginRoute, not as a global guard

**File:** `lib/core/router/router.dart:32-36`
**Issue:** `AuthGuard` is applied per-route on `LoginRoute` only. This is likely intentional (the login page itself does not need auth guarding in most flows -- it is the destination for unauthenticated users). However, the naming is slightly misleading: an `AuthGuard` on the login route suggests it requires authentication to access the login page. Verify this matches the intended behavior -- typically auth guards redirect unauthenticated users TO the login page, not guard the login page itself.
**Fix:** Review `AuthGuard` implementation to confirm it redirects authenticated users away from login (common pattern) rather than requiring auth to access login. If correct, consider renaming to `AuthenticatedRedirectGuard` for clarity.

---

_Reviewed: 2026-04-18T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
