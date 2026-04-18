# Phase 5: UX Patterns (Onboarding + RIVE Splash + Coach Marks) - Research

**Researched:** 2026-04-17
**Domain:** Flutter UX patterns -- onboarding flows, coach marks, RIVE animations, auto_route guards
**Confidence:** HIGH

## Summary

Phase 5 adds three user-facing features to the skeleton: a 3-slide onboarding flow gated by an `OnboardingGuard`, a `CoachMarkService` wrapping `tutorial_coach_mark` with a two-target demo on the counter page, and a dedicated RIVE demo page showcasing `.riv` loading with state-machine interaction. It also refactors `AuthGuard` from global to per-route.

The RIVE animated splash screen originally scoped in UX-07 has been **explicitly dropped** by user decision (D-01). The native splash is the only splash. `RiveNative.init()` is still called in `StartUpService` to initialize the RIVE C++ runtime, but it drives no splash -- only the demo page and downstream features.

All three libraries (`rive 0.14.5`, `tutorial_coach_mark 1.3.3`, `auto_route 11.1.0`) are verified current on pub.dev. The existing `PreferencesService` (Phase 2) provides all persistence needed for `hasSeenOnboarding` and coach mark tour flags. No new persistence layer is required.

**Primary recommendation:** Build three independent features (onboarding, coach marks, RIVE demo) sharing the existing `PreferencesService` for flag persistence, then wire them together via routing changes (add `OnboardingGuard`, refactor `AuthGuard` to per-route, add new routes).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** No RIVE animated splash screen. No `SplashRoute`. Native splash only. Animated splashes are an anti-pattern.
- **D-02:** `RiveNative.init()` called in `StartUpService` before `runApp` -- initializes RIVE engine for demo page, NOT for splash.
- **D-03:** `OnboardingGuard` runs first in router's `guards` list: `[OnboardingGuard, AuthGuard]`. OnboardingGuard redirects to `OnboardingRoute` if `!hasSeenOnboarding`.
- **D-04:** `AuthGuard` moves from global to per-route. `HomeRoute` is public. Login is opt-in from Home.
- **D-05:** First-launch: Native splash -> Onboarding -> Home. Subsequent: Native splash -> Home.
- **D-06:** After onboarding completes, `hasSeenOnboarding` flips to `true` via `PreferencesService`. Guard re-evaluation via `reevaluateListenable`.
- **D-07:** 3-slide `PageView` with generic placeholder content. Each app replaces copy/images post-bootstrap.
- **D-08:** Static illustrations (placeholder images), NOT RIVE animations in onboarding slides.
- **D-09:** Skip button exits onboarding immediately -- flips flag, navigates to Home.
- **D-10:** Dots indicator + Next/Get Started CTA buttons.
- **D-11:** `hasSeenOnboarding` persisted via `PreferencesService.setBool()`. Key in `core/preferences/` constants.
- **D-12:** `CoachMarkService` wraps `tutorial_coach_mark` with `register()` + `showTour()` API. Handles "target not yet laid out" via `addPostFrameCallback`.
- **D-13:** Counter screen demo fires automatically on first visit only. No replay button.
- **D-14:** Two targets: counter display value + FAB.
- **D-15:** Per-screen tours only. No cross-screen sequencing.
- **D-16:** Two screens: Home page + RIVE Demo page.
- **D-17:** RIVE Demo loads `.riv` via `RiveWidgetBuilder`, exposes state-machine toggle, cleans up in `dispose`.
- **D-18:** Custom `.riv` asset shipped in `assets/rive/`.

### Claude's Discretion
- Exact onboarding placeholder text and image assets
- `CoachMarkService` internal implementation details
- RIVE Demo page layout and state-machine toggle details
- Whether `OnboardingGuard` needs its own `reevaluateListenable` stream
- Navigation pattern from Home to RIVE Demo
- `flutter_native_splash` configuration
- How to handle `AuthGuard` refactor (per-route `guards:` property vs custom approach)

### Deferred Ideas (OUT OF SCOPE)
- Cross-screen tour sequencing
- RIVE animations in onboarding slides
- Help/replay button for coach mark tours
- UX-07 (RIVE-based animated splash) -- explicitly dropped
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UX-01 | Onboarding feature at `lib/features/onboarding/` -- 3-slide PageView with dots, skip, next/get-started | auto_route per-route pattern, PageView + PageController pattern, Clean Architecture layering |
| UX-02 | `hasSeenOnboarding` persisted via SharedPreferencesAsync through `core/preferences/` service | Existing `PreferencesService` (verified in codebase) with `getBool`/`setBool` |
| UX-03 | auto_route guard redirects first-run users to onboarding; subsequent launches go to HomeRoute | auto_route `AutoRouteGuard` pattern with `resolver.redirectUntil`, `reevaluateListenable` |
| UX-04 | `CoachMarkService` wrapper over `tutorial_coach_mark` | `TutorialCoachMark` API with `TargetFocus`, `show(context:)`, overlay configuration |
| UX-05 | Counter screen demo -- first visit highlights FAB with coach mark tour | `addPostFrameCallback` for target layout, `PreferencesService` for tour flag |
| UX-06 | RIVE 0.14 initialized with `await RiveNative.init()` in startup service | Verified `RiveNative.init()` API from rive-docs migration guide |
| UX-07 | ~~RIVE-based animated splash~~ | **DROPPED per D-01.** No implementation needed. |
| UX-08 | Demo screen loads `.riv` asset with `RiveWidgetBuilder`, state-machine toggle, controller disposal | `RiveWidgetBuilder` + `FileLoader.fromAsset` + `BooleanInput` pattern from Context7 |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Onboarding flow | Presentation | Data (preferences) | PageView + Cubit owns UI state; thin data layer reads/writes `hasSeenOnboarding` flag |
| Onboarding guard | Frontend (Router) | -- | `auto_route` guard runs at navigation layer before any widget builds |
| AuthGuard refactor | Frontend (Router) | -- | Moving from global `guards` override to per-route `guards:` property |
| Coach mark service | Domain (core service) | Presentation | Service wraps `tutorial_coach_mark`; presentation layer calls `showTour` |
| Coach mark demo | Presentation | Data (preferences) | Counter page triggers tour; flag persisted per tourId |
| RIVE initialization | Startup (bootstrap) | -- | `RiveNative.init()` in `StartUpService` before `runApp` |
| RIVE demo page | Presentation | -- | Standalone page with `RiveWidgetBuilder`, no data/domain layer needed |
| Preference flags | Data (core service) | -- | `PreferencesService` already exists, shared across onboarding + coach marks |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `rive` | `^0.14.5` | RIVE animation runtime (wraps `rive_native` C++ core) | Official RIVE Flutter SDK; 0.14.x is the native C++ rewrite [VERIFIED: pub.dev] |
| `tutorial_coach_mark` | `^1.3.3` | Coach mark / feature tour overlays | Most popular Flutter coach mark package, active maintenance [VERIFIED: pub.dev] |
| `auto_route` | `^11.1.0` | Already in pubspec -- guards, routing | Already established in skeleton [VERIFIED: codebase pubspec.yaml] |
| `shared_preferences` | `^2.5.5` | Already in pubspec -- `PreferencesService` backing | Already established in skeleton [VERIFIED: codebase] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter_native_splash` | `^2.3.9` | Already in pubspec -- native splash config | Already present; no changes needed for this phase [VERIFIED: codebase] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `tutorial_coach_mark` | `showcaseview` | `showcaseview` has more GitHub stars but `tutorial_coach_mark` has a cleaner imperative API matching D-12's `register/showTour` pattern |
| Manual `PageView` onboarding | `introduction_screen`, `onboarding` packages | Custom PageView is simpler, no extra dependency, matches skeleton philosophy of minimal deps |

**Installation:**
```bash
flutter pub add rive tutorial_coach_mark
```

**Version verification:**
- `rive`: 0.14.5 published 2026-04-03 [VERIFIED: pub.dev/packages/rive/versions]
- `tutorial_coach_mark`: 1.3.3 published ~2025-10 [VERIFIED: pub.dev/packages/tutorial_coach_mark/versions]
- `auto_route`: 11.1.0 already in pubspec [VERIFIED: codebase]
- `shared_preferences`: 2.5.5 already in pubspec [VERIFIED: codebase]

## Architecture Patterns

### System Architecture Diagram

```
[App Launch]
    |
    v
[main.dart] -- WidgetsFlutterBinding.ensureInitialized()
    |
    v
[StartUpService.initServices()]
    |-- await RiveNative.init()     <-- NEW (UX-06)
    |-- await Firebase.initializeApp()
    |-- configureDependenciesApp()
    |
    v
[AppRouter] with guards: [OnboardingGuard, AuthGuard*]
    |                                        * AuthGuard now per-route only
    |
    |-- reevaluateListenable: ReevaluateListenable.stream(
    |       authService.authStateChanges,   <-- existing
    |   )
    |
    |-- (first launch) OnboardingGuard redirects to:
    |       [OnboardingRoute] -- 3-slide PageView
    |           |-- "Get Started" / "Skip"
    |           |-- PreferencesService.setBool('hasSeenOnboarding', true)
    |           |-- Navigate to HomeRoute
    |
    |-- (subsequent launch) Guard passes through to:
    |       [HomeRoute] -- existing counter page
    |           |-- (first visit) CoachMarkService.showTour('home')
    |           |       |-- Target 1: counter display
    |           |       |-- Target 2: FAB
    |           |       |-- PreferencesService.setBool('tour_home_seen', true)
    |           |
    |           |-- "RIVE Demo" button --> [RiveDemoRoute]
    |                   |-- RiveWidgetBuilder loads assets/rive/demo.riv
    |                   |-- Switch toggles BooleanInput on state machine
    |                   |-- Back navigation disposes controller
    |
    |-- [LoginRoute] -- per-route guarded (AuthGuard), opt-in from Home
```

### Recommended Project Structure
```
lib/
├── core/
│   ├── preferences/
│   │   ├── preferences_service.dart          # existing
│   │   ├── preferences_service_impl.dart     # existing
│   │   └── preferences_keys.dart             # NEW: string constants
│   ├── coach_mark/
│   │   └── coach_mark_service.dart           # NEW: CoachMarkService
│   └── router/
│       ├── router.dart                       # MODIFIED: add routes + OnboardingGuard
│       ├── router.gr.dart                    # regenerated
│       └── guards/
│           ├── auth_guard.dart               # existing (unchanged)
│           └── onboarding_guard.dart         # NEW
├── features/
│   ├── onboarding/
│   │   ├── presentation/
│   │   │   ├── onboarding_page.dart          # NEW: @RoutePage PageView
│   │   │   ├── widgets/
│   │   │   │   ├── onboarding_slide.dart     # NEW: single slide widget
│   │   │   │   └── dot_indicator.dart        # NEW: animated dots
│   │   │   └── cubit/
│   │   │       ├── onboarding_cubit.dart     # NEW: slide state + flag
│   │   │       └── onboarding_state.dart     # NEW
│   │   └── domain/                           # (thin: just uses PreferencesService)
│   ├── home_page/
│   │   └── presentation/
│   │       └── home_page.dart                # MODIFIED: add GlobalKeys, coach mark trigger, RIVE Demo button
│   └── rive_demo/
│       └── presentation/
│           ├── rive_demo_page.dart            # NEW: @RoutePage
│           └── cubit/
│               ├── rive_demo_cubit.dart       # NEW (optional -- could be StatefulWidget)
│               └── rive_demo_state.dart       # NEW
├── startup_service.dart                       # MODIFIED: add RiveNative.init()
└── app.dart                                   # MODIFIED: reevaluateListenable may need onboarding stream
assets/
├── images/
│   └── onboarding/
│       ├── slide_1.webp                       # NEW: placeholder
│       ├── slide_2.webp                       # NEW: placeholder
│       └── slide_3.webp                       # NEW: placeholder
└── rive/
    └── demo.riv                               # NEW: minimal animation
```

### Pattern 1: OnboardingGuard with auto_route
**What:** An `AutoRouteGuard` that checks `hasSeenOnboarding` from `PreferencesService` and redirects first-run users to `OnboardingRoute`.
**When to use:** Before any content route on the first launch.
**Example:**
```dart
// Source: auto_route docs (Context7 /milad-akarie/auto_route_library)
// + codebase AuthGuard pattern
class OnboardingGuard extends AutoRouteGuard {
  OnboardingGuard(this._preferencesService);

  final PreferencesService _preferencesService;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    final seen = await _preferencesService.getBool('hasSeenOnboarding');
    if (seen == true) {
      resolver.next();
    } else {
      resolver.redirectUntil(const OnboardingRoute());
    }
  }
}
```

### Pattern 2: Per-Route AuthGuard
**What:** Move `AuthGuard` from the global `guards` list to individual route `guards:` properties.
**When to use:** When only specific routes need authentication.
**Example:**
```dart
// Source: Context7 /milad-akarie/auto_route_library -- per-route guards
@override
List<AutoRoute> get routes => [
  AutoRoute(page: MyHomeRoute.page, path: '/'),         // public
  AutoRoute(page: OnboardingRoute.page, path: '/onboarding'),  // public
  AutoRoute(page: RiveDemoRoute.page, path: '/rive-demo'),     // public
  AutoRoute(
    page: LoginRoute.page,
    path: '/login',
    guards: [AuthGuard(_authService)],  // per-route guard
  ),
];
```

### Pattern 3: RIVE 0.14 File Loading with RiveWidgetBuilder
**What:** Declarative pattern to load `.riv` assets with loading/error states.
**When to use:** Any screen displaying a RIVE animation.
**Example:**
```dart
// Source: Context7 /rive-app/rive-flutter -- RiveWidgetBuilder
class _RiveDemoState extends State<RiveDemoPage> {
  late final FileLoader fileLoader = FileLoader.fromAsset(
    'assets/rive/demo.riv',
    riveFactory: Factory.rive,
  );

  @override
  void dispose() {
    fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RiveWidgetBuilder(
      fileLoader: fileLoader,
      stateMachineSelector: const StateMachineDefault(),
      builder: (context, state) => switch (state) {
        RiveLoading() => const Center(child: CircularProgressIndicator()),
        RiveFailed() => Center(child: Text('Failed: ${state.error}')),
        RiveLoaded() => RiveWidget(
          controller: state.controller,
          fit: Fit.contain,
        ),
      },
    );
  }
}
```

### Pattern 4: CoachMarkService Wrapper
**What:** A service that abstracts `tutorial_coach_mark` behind a `register/showTour` API.
**When to use:** Any screen that needs first-visit feature highlighting.
**Example:**
```dart
// Source: Context7 /rafaelbarbosatec/tutorial_coach_mark + D-12 spec
class CoachMarkService {
  CoachMarkService(this._preferencesService);

  final PreferencesService _preferencesService;
  final Map<String, List<_CoachTarget>> _tours = {};

  void register(
    String tourId,
    GlobalKey key,
    String description, {
    String? title,
  }) {
    _tours.putIfAbsent(tourId, () => []);
    _tours[tourId]!.add(_CoachTarget(key: key, title: title, description: description));
  }

  Future<void> showTour(String tourId, BuildContext context) async {
    final seen = await _preferencesService.getBool('tour_${tourId}_seen');
    if (seen == true) return;

    final targets = _tours[tourId];
    if (targets == null || targets.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      TutorialCoachMark(
        targets: targets.map((t) => TargetFocus(
          keyTarget: t.key,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (t.title != null) Text(t.title!, style: ...),
                  Text(t.description, style: ...),
                ],
              ),
            ),
          ],
        )).toList(),
        colorShadow: Colors.black,
        opacityShadow: 0.7,
        onFinish: () => _preferencesService.setBool(
          'tour_${tourId}_seen',
          value: true,
        ),
      ).show(context: context);
    });
  }
}
```

### Pattern 5: Onboarding Guard with reevaluateListenable
**What:** The guard must re-evaluate when `hasSeenOnboarding` flips to `true` so the user is navigated away from OnboardingRoute without a manual push.
**When to use:** Whenever a guard's decision depends on async state that changes during the session.
**Recommendation:** Use a `ValueNotifier<bool>` exposed by a thin wrapper (or extend `PreferencesService` to expose a `ChangeNotifier`). Combine with `authService.authStateChanges` in `reevaluateListenable` using `Listenable.merge()`.
```dart
// In app.dart
routerConfig: appRouter.config(
  reevaluateListenable: Listenable.merge([
    ReevaluateListenable.stream(authService.authStateChanges),
    onboardingNotifier,  // ValueNotifier<bool> flipped by OnboardingCubit
  ]),
  navigatorObservers: () => [AppRouterObserver()],
),
```
[ASSUMED] -- `Listenable.merge` with `ReevaluateListenable` may need testing; the alternative is a custom `ChangeNotifier` that aggregates both signals.

### Anti-Patterns to Avoid
- **Guard with async I/O on every navigation:** `OnboardingGuard` reads `SharedPreferences` (async). Cache the value after first read so subsequent navigations are synchronous. The guard's `onNavigation` is called on every route change.
- **Disposing RIVE resources in cubit instead of widget:** RIVE controllers are tied to the render tree. Always dispose `FileLoader`, `RiveWidgetController`, and inputs in `State.dispose()`, not in a BLoC/Cubit.
- **Coach marks before layout:** Never call `TutorialCoachMark.show()` during `build()`. Always use `addPostFrameCallback` to ensure targets have been laid out.
- **Hardcoded preference keys scattered across files:** Centralize all keys in `core/preferences/preferences_keys.dart` as `static const String` values.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Coach mark overlays | Custom overlay + spotlight cutout | `tutorial_coach_mark` | Spotlight geometry, animation timing, multi-target sequencing, tap handling -- hundreds of edge cases |
| RIVE animation rendering | Custom Skia/Impeller integration | `rive` package (C++ runtime) | Native renderer handles state machines, blending, mesh deformation |
| Dot page indicator | Custom painter from scratch | `AnimatedContainer` Row | Simple enough to build inline; no package needed for 3 dots |
| Onboarding persistence | Direct `SharedPreferences` calls | `PreferencesService.setBool` | Abstraction already exists; keeps testability |
| Route guards | Manual `Navigator.push` checks | `auto_route` `AutoRouteGuard` | Framework handles redirect stacking, resolution, and re-evaluation |

**Key insight:** The complexity in this phase is in wiring -- connecting three features through the routing layer and shared preferences. The individual features themselves are standard Flutter patterns. Don't over-engineer the features; invest in clean integration.

## Common Pitfalls

### Pitfall 1: OnboardingGuard Async Race
**What goes wrong:** `OnboardingGuard.onNavigation` calls `await _preferencesService.getBool(...)` which is async, but `onNavigation` is synchronous in auto_route. The resolver waits, but if the preference read is slow, there's a visible blank frame.
**Why it happens:** `SharedPreferencesAsync` reads from disk on first access.
**How to avoid:** Pre-read the `hasSeenOnboarding` flag during `StartUpService.initServices()` and inject the cached value into the guard. The guard reads from memory, not disk.
**Warning signs:** Brief white flash between native splash and first screen.

### Pitfall 2: RIVE LateInitializationError
**What goes wrong:** `LateInitializationError: Field 'makeFlutterFactory' has not been initialized` crashes the app.
**Why it happens:** RIVE widgets are built before `RiveNative.init()` completes.
**How to avoid:** Call `await RiveNative.init()` in `StartUpService` before `runApp`. Never load `.riv` files before init. [VERIFIED: rive-docs FAQ]
**Warning signs:** Crash on first RIVE widget render.

### Pitfall 3: Coach Mark Targets Not Laid Out
**What goes wrong:** `TutorialCoachMark.show()` called during or immediately after `build()` -- targets have zero size, spotlight appears in wrong position or crashes.
**Why it happens:** `GlobalKey.currentContext` is null or has zero `RenderBox` size during the build phase.
**How to avoid:** Always wrap `showTour` in `WidgetsBinding.instance.addPostFrameCallback((_) { ... })`. D-12 mandates this. [VERIFIED: tutorial_coach_mark README]
**Warning signs:** Spotlight appears at (0,0) or overlay renders without a visible cutout.

### Pitfall 4: Guard Re-evaluation Not Triggering
**What goes wrong:** User completes onboarding but stays on `OnboardingRoute` -- the router doesn't re-evaluate and navigate to Home.
**Why it happens:** `reevaluateListenable` only listens to `authService.authStateChanges`. The onboarding flag change doesn't trigger re-evaluation.
**How to avoid:** Either (a) add a `ValueNotifier` to `reevaluateListenable` that fires when onboarding completes, or (b) explicitly call `router.replaceAll([const MyHomeRoute()])` after setting the flag.
**Warning signs:** User taps "Get Started" but nothing happens, or they see the onboarding again on back-press.

### Pitfall 5: RIVE Resource Leaks
**What goes wrong:** Memory grows unbounded when navigating to/from RIVE demo page.
**Why it happens:** `FileLoader`, `RiveWidgetController`, and input handles are not disposed.
**How to avoid:** Dispose in exact reverse order of creation in `State.dispose()`: inputs first, then controller, then fileLoader/file. [VERIFIED: Context7 rive-flutter examples]
**Warning signs:** Growing memory in DevTools when repeatedly visiting RIVE demo.

### Pitfall 6: AuthGuard Still Global After Refactor
**What goes wrong:** After moving AuthGuard to per-route, it still runs for every navigation because it's left in the global `guards` list.
**Why it happens:** Incomplete refactor -- forgot to remove from `AppRouter.guards`.
**How to avoid:** Remove `AuthGuard` from the `guards` override entirely. Only keep `OnboardingGuard` global. Add `AuthGuard` to specific routes via the `guards:` parameter.
**Warning signs:** Unauthenticated users redirected to login when visiting Home (which should be public per D-04).

## Code Examples

### RiveNative Initialization in StartUpService
```dart
// Source: Context7 /rive-app/rive-docs -- flutter.mdx
// Integration point: lib/startup_service.dart
import 'package:rive/rive.dart';

static Future<void> initServices() async {
  var environment = 'dev';

  // UX-06: Initialize RIVE native runtime before any RIVE widget loads.
  await RiveNative.init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // ... existing Firebase setup
  } on Object catch (e) {
    // ... existing fallback
  }

  await configureDependenciesApp(environment: environment);
}
```

### RIVE State Machine Boolean Toggle
```dart
// Source: Context7 /rive-app/rive-flutter -- InputsExample
// For RIVE demo page: access a BooleanInput and toggle it
_riveFile = await File.asset('assets/rive/demo.riv', riveFactory: Factory.rive);
_controller = RiveWidgetController(_riveFile!);
_toggleInput = _controller?.stateMachine.boolean('Toggle');

// Toggle:
_toggleInput?.value = !(_toggleInput?.value ?? false);

// Cleanup in dispose():
_toggleInput?.dispose();
_controller?.dispose();
_riveFile?.dispose();
```

### tutorial_coach_mark TargetFocus Construction
```dart
// Source: Context7 /rafaelbarbosatec/tutorial_coach_mark -- README
TargetFocus(
  identify: 'counter_display',
  keyTarget: counterKey,  // GlobalKey attached to counter Text widget
  shape: ShapeLightFocus.RRect,
  radius: AppDimensions.radiusMedium,
  paddingFocus: AppDimensions.radiusMedium,
  contents: [
    TargetContent(
      align: ContentAlign.bottom,
      builder: (context, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('This is your counter', style: context.theme.textTheme.titleMedium),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text('Tap the button below to increment it.',
            style: context.theme.textTheme.bodyMedium),
        ],
      ),
    ),
  ],
)
```

### OnboardingRoute with auto_route Guard
```dart
// Source: Context7 /milad-akarie/auto_route_library
// router.dart modification
@override
late final List<AutoRouteGuard> guards = [
  OnboardingGuard(getIt<PreferencesService>()),
  // AuthGuard removed from global -- now per-route only
];

@override
List<AutoRoute> get routes => [
  AutoRoute(page: MyHomeRoute.page, path: '/'),
  AutoRoute(page: OnboardingRoute.page, path: '/onboarding'),
  AutoRoute(page: RiveDemoRoute.page, path: '/rive-demo'),
  AutoRoute(
    page: LoginRoute.page,
    path: '/login',
    guards: [AuthGuard(_authService)],  // per-route
  ),
];
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `rive` < 0.14 (Dart runtime) | `rive` 0.14+ (C++ native runtime via `rive_native`) | Dec 2025 | Breaking API: `File.asset` with `riveFactory`, `RiveWidgetBuilder`, `RiveWidgetController` replace `RiveAnimation.asset` |
| `SimpleAnimation` / `OneShotAnimation` | `StateMachineSelector` / `RiveWidgetController.stateMachine` | 0.14.0 | State machine inputs accessed via controller, not separate `StateMachineController` |
| `RiveAnimation.asset('file.riv')` | `FileLoader.fromAsset('file.riv', riveFactory: Factory.rive)` | 0.14.0 | Explicit factory parameter required |
| Global `AuthGuard` via interface implementation | Global `guards` list on `RootStackRouter` | auto_route 9.0 | Per-route `guards:` property on `AutoRoute` entries |

**Deprecated/outdated:**
- `RiveAnimation` widget -- replaced by `RiveWidget` + `RiveWidgetBuilder` in 0.14 [VERIFIED: Context7]
- `StateMachineController` -- replaced by `RiveWidgetController.stateMachine` in 0.14 [VERIFIED: Context7]
- `SmaInput`, `SMIBool`, `SMINumber` -- replaced by `BooleanInput`, `NumberInput`, `TriggerInput` in 0.14 [VERIFIED: Context7]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Listenable.merge` works with `ReevaluateListenable.stream` for combining auth + onboarding signals | Architecture Patterns, Pattern 5 | Guard re-evaluation won't trigger on onboarding completion; fallback is explicit `router.replaceAll` navigation |
| A2 | `tutorial_coach_mark` 1.3.3 is compatible with Flutter 3.41.5 / Dart 3.9 | Standard Stack | Build failure; would need to find alternative or fork |
| A3 | RIVE 0.14.5 `File.asset` API with `riveFactory: Factory.rive` is the correct loading pattern for bundled assets | Code Examples | Demo page won't load the animation; Context7 examples all show this pattern |

## Open Questions

1. **reevaluateListenable composition**
   - What we know: `ReevaluateListenable.stream(authService.authStateChanges)` already works for auth. Onboarding needs a similar trigger.
   - What's unclear: Whether `Listenable.merge` correctly composes a `ReevaluateListenable` with a `ValueNotifier`. The alternative is explicit navigation after flag flip.
   - Recommendation: Implement the `Listenable.merge` approach first. If it doesn't work, fall back to explicit `router.replaceAll([const MyHomeRoute()])` in the onboarding cubit after setting the flag. Both achieve the same UX.

2. **Creating the `.riv` asset**
   - What we know: A custom `.riv` file with a boolean state-machine input is needed at `assets/rive/demo.riv`.
   - What's unclear: Whether to create this in the RIVE editor (requires manual design work) or use a publicly available sample `.riv`.
   - Recommendation: Use one of RIVE's open-source sample files (e.g., from their GitHub examples repo) that has a boolean toggle. If none fits, create a minimal one in the RIVE editor -- a simple shape with a color toggle is sufficient.

3. **Onboarding cubit necessity**
   - What we know: D-07 describes a simple 3-slide PageView with next/skip/get-started.
   - What's unclear: Whether this needs a full Cubit or if a StatefulWidget with PageController suffices.
   - Recommendation: Use a Cubit to stay consistent with the skeleton's patterns. The cubit manages `currentPage` index and `hasCompleted` state. It's lightweight but demonstrates the pattern for downstream apps.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test 10.0.0` + `very_good_analysis 10.2.0` |
| Config file | None -- `flutter test` uses defaults |
| Quick run command | `flutter test --no-pub test/features/onboarding/` |
| Full suite command | `flutter test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UX-01 | Onboarding cubit manages 3 slides, emits correct state on next/skip | unit | `flutter test test/features/onboarding/presentation/cubit/onboarding_cubit_test.dart -x` | Wave 0 |
| UX-02 | `hasSeenOnboarding` read/write via PreferencesService | unit | `flutter test test/core/preferences/preferences_keys_test.dart -x` | Wave 0 |
| UX-03 | OnboardingGuard redirects when flag is false, passes when true | unit | `flutter test test/core/router/guards/onboarding_guard_test.dart -x` | Wave 0 |
| UX-04 | CoachMarkService registers targets and resolves to TargetFocus list | unit | `flutter test test/core/coach_mark/coach_mark_service_test.dart -x` | Wave 0 |
| UX-05 | Coach mark tour flag persisted after completion | unit | `flutter test test/core/coach_mark/coach_mark_service_test.dart -x` | Wave 0 |
| UX-06 | `RiveNative.init()` called in startup | manual-only | Cannot unit test native FFI init in test runner | -- |
| UX-07 | DROPPED | -- | -- | -- |
| UX-08 | RIVE demo page builds without error, disposes resources | widget | `flutter test test/features/rive_demo/presentation/rive_demo_page_test.dart -x` | Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test --no-pub`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/features/onboarding/presentation/cubit/onboarding_cubit_test.dart` -- covers UX-01
- [ ] `test/core/router/guards/onboarding_guard_test.dart` -- covers UX-03
- [ ] `test/core/coach_mark/coach_mark_service_test.dart` -- covers UX-04, UX-05
- [ ] `test/features/rive_demo/presentation/rive_demo_page_test.dart` -- covers UX-08
- [ ] Mocking setup: `PreferencesService` mock via manual fake or `mocktail` (not yet in dev_dependencies -- may need `mocktail` addition)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Indirectly (AuthGuard refactor) | `auto_route` guard + `AuthService` contract (unchanged) |
| V3 Session Management | No | -- |
| V4 Access Control | Yes (guard ordering) | OnboardingGuard + per-route AuthGuard ensure correct access flow |
| V5 Input Validation | No | No user input in onboarding/coach marks/RIVE demo |
| V6 Cryptography | No | -- |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Bypassing onboarding guard via deep link | Elevation of Privilege | Guard runs on ALL navigations including deep links (auto_route default behavior) |
| Preference tampering (clearing `hasSeenOnboarding`) | Tampering | Low risk -- worst case is user sees onboarding again. Not a security boundary. |

## Sources

### Primary (HIGH confidence)
- Context7 `/rive-app/rive-flutter` -- `RiveWidgetBuilder`, `RiveWidgetController`, state machine inputs, dispose patterns
- Context7 `/rive-app/rive-docs` -- `RiveNative.init()` initialization, migration guide, FAQ
- Context7 `/rafaelbarbosatec/tutorial_coach_mark` -- `TargetFocus`, `TutorialCoachMark` API, overlay configuration
- Context7 `/milad-akarie/auto_route_library` -- guards (global + per-route), `reevaluateListenable`, `AutoRouteGuard` pattern

### Secondary (MEDIUM confidence)
- pub.dev/packages/rive/versions -- version 0.14.5 verified as latest stable
- pub.dev/packages/tutorial_coach_mark/versions -- version 1.3.3 verified as latest
- Codebase inspection -- `PreferencesService`, `AuthGuard`, `AppRouter`, `StartUpService`, `injection.config.dart` all verified

### Tertiary (LOW confidence)
- `Listenable.merge` composition with `ReevaluateListenable` -- no official docs found confirming this pattern (A1)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all packages verified on pub.dev and Context7
- Architecture: HIGH -- patterns derived from verified library APIs + existing codebase conventions
- Pitfalls: HIGH -- each pitfall sourced from official docs or known Flutter patterns
- Guard re-evaluation: MEDIUM -- `Listenable.merge` approach is sound but untested with `ReevaluateListenable`

**Research date:** 2026-04-17
**Valid until:** 2026-05-17 (stable libraries, 30-day window)
