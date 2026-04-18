# Phase 5: UX Patterns (Onboarding + RIVE Splash + Coach Marks) - Pattern Map

**Mapped:** 2026-04-17
**Files analyzed:** 16 new/modified files
**Analogs found:** 14 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/core/router/guards/onboarding_guard.dart` | middleware | request-response | `lib/core/router/guards/auth_guard.dart` | exact |
| `lib/core/router/router.dart` | route | request-response | (self -- modify in place) | exact |
| `lib/core/preferences/preferences_keys.dart` | config | -- | `lib/core/presentation/app_dimensions.dart` | role-match |
| `lib/core/coach_mark/coach_mark_service.dart` | service | event-driven | `lib/core/preferences/preferences_service.dart` + `preferences_service_impl.dart` | role-match |
| `lib/features/onboarding/presentation/onboarding_page.dart` | component | request-response | `lib/features/home_page/presentation/home_page.dart` | exact |
| `lib/features/onboarding/presentation/widgets/onboarding_slide.dart` | component | request-response | `lib/features/home_page/presentation/home_page.dart` (_Page) | role-match |
| `lib/features/onboarding/presentation/widgets/dot_indicator.dart` | component | request-response | (no analog -- simple custom widget) | none |
| `lib/features/onboarding/presentation/cubit/onboarding_cubit.dart` | controller | request-response | `lib/features/home_page/presentation/cubit/home_cubit.dart` | exact |
| `lib/features/onboarding/presentation/cubit/onboarding_state.dart` | model | -- | `lib/features/home_page/presentation/cubit/home_state.dart` | exact |
| `lib/features/rive_demo/presentation/rive_demo_page.dart` | component | request-response | `lib/features/home_page/presentation/home_page.dart` | role-match |
| `lib/features/rive_demo/presentation/cubit/rive_demo_cubit.dart` | controller | request-response | `lib/features/home_page/presentation/cubit/home_cubit.dart` | role-match |
| `lib/features/rive_demo/presentation/cubit/rive_demo_state.dart` | model | -- | `lib/features/home_page/presentation/cubit/home_state.dart` | exact |
| `lib/features/home_page/presentation/home_page.dart` | component | request-response | (self -- modify in place) | exact |
| `lib/startup_service.dart` | service | request-response | (self -- modify in place) | exact |
| `lib/app.dart` | config | request-response | (self -- modify in place) | exact |
| `lib/main.dart` | config | request-response | (self -- modify in place) | exact |

## Pattern Assignments

### `lib/core/router/guards/onboarding_guard.dart` (middleware, request-response)

**Analog:** `lib/core/router/guards/auth_guard.dart`

**Imports pattern** (lines 1-4):
```dart
import 'package:auto_route/auto_route.dart';

import 'package:skeleton/core/auth/auth_service.dart';
import 'package:skeleton/core/router/router.dart';
```
New file replaces `auth_service.dart` import with `preferences_service.dart`, keeps `router.dart` for route references.

**Core guard pattern** (lines 11-24):
```dart
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
```
New `OnboardingGuard` replaces `_authService.currentUser != null` with a cached `hasSeenOnboarding` boolean check. Uses `resolver.redirectUntil(const OnboardingRoute())` on failure. Per Pitfall 1 in RESEARCH.md, the flag must be pre-read and cached -- do NOT call `await _preferencesService.getBool(...)` inside `onNavigation`.

**Doc comment pattern** (lines 6-10):
```dart
/// Redirects unauthenticated users to [LoginRoute].
///
/// Wired as a router-level guard via the `guards` override on [AppRouter].
/// Re-evaluated automatically via `reevaluateListenable` on every
/// [AuthService.authStateChanges] emission.
```

---

### `lib/core/router/router.dart` (route, MODIFIED)

**Analog:** self -- current file at `lib/core/router/router.dart`

**Guards list pattern** (lines 18-21):
```dart
  @override
  late final List<AutoRouteGuard> guards = [
    AuthGuard(_authService),
  ];
```
Modify to: `[OnboardingGuard(cachedFlag), ]` -- remove `AuthGuard` from global. Per D-04, `AuthGuard` moves to per-route `guards:` property.

**Routes list pattern** (lines 23-27):
```dart
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: MyHomeRoute.page, path: '/'),
        AutoRoute(page: LoginRoute.page, path: '/login'),
      ];
```
Extend with: `AutoRoute(page: OnboardingRoute.page, path: '/onboarding')`, `AutoRoute(page: RiveDemoRoute.page, path: '/rive-demo')`. Add `guards: [AuthGuard(_authService)]` to `LoginRoute` only.

**Constructor pattern** (lines 13-16):
```dart
class AppRouter extends RootStackRouter {
  AppRouter(this._authService);

  final AuthService _authService;
```
Constructor must also accept `PreferencesService` (or the cached onboarding flag) for `OnboardingGuard`.

---

### `lib/core/preferences/preferences_keys.dart` (config)

**Analog:** `lib/core/presentation/app_dimensions.dart`

**Constants-class pattern** (lines 1-11):
```dart
abstract class AppDimensions {
  static const double radiusSmall = 6;
  static const double radiusMedium = 12;

  static const double spacingSmall = 4;
  static const double spacingBase = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 24;
  static const double spacingExtraLarge = 32;
  static const double snackBarHeight = 58;
}
```
New file uses same `abstract class` + `static const String` pattern for preference keys: `hasSeenOnboarding`, `tourHomeCompleted`, etc.

---

### `lib/core/coach_mark/coach_mark_service.dart` (service, event-driven)

**Analog:** `lib/core/preferences/preferences_service.dart` (abstract interface pattern) + `lib/core/preferences/preferences_service_impl.dart` (injectable singleton pattern)

**Abstract service pattern** (`preferences_service.dart` lines 1-26):
```dart
/// Abstract preferences service for key-value persistence.
///
/// Features define their own key constants -- this service provides
/// the typed get/set plumbing.
abstract class PreferencesService {
  /// Reads a boolean value for [key], or `null` if not set.
  Future<bool?> getBool(String key);
  // ...
}
```

**Injectable singleton pattern** (`preferences_service_impl.dart` lines 1-8):
```dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skeleton/core/preferences/preferences_service.dart';

@LazySingleton(as: PreferencesService)
class PreferencesServiceImpl implements PreferencesService {
```

CoachMarkService can be a concrete `@lazySingleton` class (no abstract interface needed since there is only one implementation). Depends on `PreferencesService` via constructor injection. API: `register()`, `showTour()`. See RESEARCH.md Pattern 4 for full implementation pattern.

---

### `lib/features/onboarding/presentation/onboarding_page.dart` (component, request-response)

**Analog:** `lib/features/home_page/presentation/home_page.dart`

**@RoutePage + BlocProvider pattern** (lines 1-16):
```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeleton/core/extensions/context_extension.dart';
import 'package:skeleton/core/injectable/injection.dart';
import 'package:skeleton/core/presentation/app_dimensions.dart';
import 'package:skeleton/features/home_page/presentation/cubit/home_cubit.dart';

@RoutePage()
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        // ignore: discarded_futures -- init is fire-and-forget by design
        create: (context) => getIt<HomeCubit>()..init(),
        child: Builder(
```
New file follows identical structure: `@RoutePage()`, `StatelessWidget`, `BlocProvider(create: (_) => getIt<OnboardingCubit>()..init())`, delegates to private `_Page` widget.

**Private page widget pattern** (lines 58-109):
```dart
class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor:
              context.theme.colorScheme.inversePrimary,
          title: Text(context.localizations.homePage_title),
        ),
        body: Center(
```
New `_Page` builds `Scaffold` with `PageView` + `BlocBuilder<OnboardingCubit, OnboardingState>`.

---

### `lib/features/onboarding/presentation/cubit/onboarding_cubit.dart` (controller, request-response)

**Analog:** `lib/features/home_page/presentation/cubit/home_cubit.dart`

**Cubit class structure** (lines 1-15):
```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:skeleton/core/errors/result.dart';
import 'package:skeleton/features/home_page/data/model/counter_model.dart';
import 'package:skeleton/features/home_page/domain/counter_service.dart';

part 'home_state.dart';

/// Manages counter page state.
@injectable
class HomeCubit extends Cubit<HomeState> {
  /// Creates a [HomeCubit] backed by the given [CounterService].
  HomeCubit(this._counterService) : super(HomeState.initial());
```
New cubit: `@injectable`, `part 'onboarding_state.dart'`, constructor takes `PreferencesService`, `super(OnboardingState.initial())`. Exposes `init()`, `nextSlide()`, `skipOnboarding()`, `completeOnboarding()`.

**Init + close pattern** (lines 22-45, 73-77):
```dart
  Future<void> init() async {
    final counter = await _getCounter();
    // ...
  }

  @override
  Future<void> close() async {
    await _counterStream?.cancel();
    return super.close();
  }
```

---

### `lib/features/onboarding/presentation/cubit/onboarding_state.dart` (model)

**Analog:** `lib/features/home_page/presentation/cubit/home_state.dart`

**State class pattern** (full file, lines 1-42):
```dart
part of 'home_cubit.dart';

class HomeState {
  const HomeState({
    required this.navigation,
    required this.status,
    required this.counter,
  });

  factory HomeState.initial() => const HomeState(
        status: HomePageStatus.empty,
        navigation: HomePageNavigation.empty,
        counter: CounterModel(value: 0),
      );

  final CounterModel counter;
  final HomePageStatus status;
  final HomePageNavigation navigation;

  HomeState copyWith({
    HomePageStatus? status,
    HomePageNavigation? navigation,
    CounterModel? counter,
  }) {
    return HomeState(
      status: status ?? this.status,
      navigation: navigation ?? this.navigation,
      counter: counter ?? this.counter,
    );
  }
}

enum HomePageStatus {
  loading,
  success,
  error,
  empty,
}

enum HomePageNavigation {
  empty,
}
```
New state: `part of 'onboarding_cubit.dart'`, fields: `currentPage` (int), `status` (enum with `initial`, `inProgress`, `completed`). `factory OnboardingState.initial()`, `copyWith`. Status enum: `OnboardingPageStatus`.

---

### `lib/features/rive_demo/presentation/rive_demo_page.dart` (component, request-response)

**Analog:** `lib/features/home_page/presentation/home_page.dart` (page structure) + RESEARCH.md Pattern 3 (RIVE-specific code)

**Page structure** -- same `@RoutePage()` + `BlocProvider` + `_Page` pattern as onboarding_page above.

**RIVE-specific note:** The `_Page` widget must be `StatefulWidget` (not `StatelessWidget`) because RIVE's `FileLoader` and controller require `dispose()` in `State.dispose()`. This is the one place where the skeleton departs from the `StatelessWidget` pattern used in `home_page.dart`. See RESEARCH.md Pattern 3 and Anti-Pattern note about disposing in widget state, not cubit.

---

### `lib/features/rive_demo/presentation/cubit/rive_demo_cubit.dart` (controller)

**Analog:** `lib/features/home_page/presentation/cubit/home_cubit.dart`

Same `@injectable` cubit structure. Manages toggle state for the RIVE state-machine boolean input. Simpler than `HomeCubit` -- no stream subscription, just `toggleAnimation()` method that emits updated state.

---

### `lib/features/rive_demo/presentation/cubit/rive_demo_state.dart` (model)

**Analog:** `lib/features/home_page/presentation/cubit/home_state.dart`

Same pattern: `part of`, const constructor, `factory .initial()`, `copyWith`, status enum. Fields: `isToggled` (bool), `status` (enum: `loading`, `loaded`, `error`).

---

### `lib/features/home_page/presentation/home_page.dart` (component, MODIFIED)

**Analog:** self -- current file

**Modifications needed:**
1. Add `GlobalKey` fields for coach mark targets (counter text, FAB)
2. Add coach mark trigger in `BlocListener` or after first build via `addPostFrameCallback`
3. Add navigation button to RIVE Demo page

**Key attachment pattern** -- wrap existing widgets with keys:
```dart
// Current (line 79-83):
builder: (context, state) => Text(
  '${state.counter.value}',
  style: context.theme.textTheme.headlineMedium,
),
```
Add `key: counterKey` to the `Text` widget. Similarly for FAB at line 91.

**Navigation pattern** from LoginPage analog (`lib/features/login/presentation/login_page.dart`) -- simple, but for RIVE Demo use `context.router.push(const RiveDemoRoute())`.

---

### `lib/startup_service.dart` (service, MODIFIED)

**Analog:** self -- current file

**Insertion point** (lines 26-29):
```dart
  static Future<void> initServices() async {
    var environment = 'dev';

    try {
      await Firebase.initializeApp(
```
Add `await RiveNative.init();` BEFORE the Firebase try-block (per D-02 and Pitfall 2). Import `package:rive/rive.dart`.

---

### `lib/app.dart` (config, MODIFIED)

**Analog:** self -- current file

**reevaluateListenable pattern** (lines 23-26):
```dart
        routerConfig: appRouter.config(
          reevaluateListenable: ReevaluateListenable.stream(
            authService.authStateChanges,
          ),
```
Extend to compose onboarding notifier via `Listenable.merge()` per RESEARCH.md Pattern 5. Fallback: explicit `router.replaceAll` if merge approach fails.

---

### `lib/main.dart` (config, MODIFIED)

**Analog:** self -- current file

**DI resolution pattern** (lines 12-18):
```dart
  final authService = getIt<AuthService>();
  final appRouter = AppRouter(authService);

  runApp(MyApp(
    appRouter: appRouter,
    authService: authService,
  ));
```
Add `final preferencesService = getIt<PreferencesService>();` and pass to `AppRouter` constructor. Pre-read `hasSeenOnboarding` flag here for guard caching (per Pitfall 1).

---

## Shared Patterns

### BlocProvider Page Wiring
**Source:** `lib/features/home_page/presentation/home_page.dart` lines 9-33
**Apply to:** `onboarding_page.dart`, `rive_demo_page.dart`
```dart
@RoutePage()
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        // ignore: discarded_futures -- init is fire-and-forget by design
        create: (context) => getIt<HomeCubit>()..init(),
        child: Builder(
          builder: (context) => BlocListener<HomeCubit, HomeState>(
            listener: (context, state) {
              // status-based side effects
            },
            child: const _Page(),
          ),
        ),
      );
}
```

### State Class Structure
**Source:** `lib/features/home_page/presentation/cubit/home_state.dart` lines 1-42
**Apply to:** `onboarding_state.dart`, `rive_demo_state.dart`
```dart
part of 'home_cubit.dart';

class HomeState {
  const HomeState({
    required this.navigation,
    required this.status,
    required this.counter,
  });

  factory HomeState.initial() => const HomeState(
        status: HomePageStatus.empty,
        navigation: HomePageNavigation.empty,
        counter: CounterModel(value: 0),
      );

  // ... fields, copyWith, enums
}
```

### Injectable Cubit Registration
**Source:** `lib/features/home_page/presentation/cubit/home_cubit.dart` lines 12-15
**Apply to:** `onboarding_cubit.dart`, `rive_demo_cubit.dart`
```dart
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._counterService) : super(HomeState.initial());
```

### AutoRouteGuard Pattern
**Source:** `lib/core/router/guards/auth_guard.dart` lines 11-24
**Apply to:** `onboarding_guard.dart`
```dart
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
```

### Abstract Constants Class
**Source:** `lib/core/presentation/app_dimensions.dart` lines 1-11
**Apply to:** `preferences_keys.dart`
```dart
abstract class AppDimensions {
  static const double radiusSmall = 6;
  // ...
}
```

### Context Extension Access
**Source:** `lib/core/extensions/context_extension.dart` lines 1-7
**Apply to:** All new page/widget files
```dart
import 'package:skeleton/core/extensions/context_extension.dart';
// Use: context.localizations.<key>, context.theme
```

### Localization Key Naming
**Source:** `lib/core/localization/app_pl.arb` (documented convention)
**Apply to:** New ARB entries for onboarding and RIVE demo
```
onboarding_title, onboarding_subtitle1, onboarding_skip, onboarding_next, onboarding_getStarted
riveDemo_title, riveDemo_toggleLabel
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/features/onboarding/presentation/widgets/dot_indicator.dart` | component | request-response | No custom indicator widget exists in the codebase. Simple `Row` of `AnimatedContainer` -- build from scratch per RESEARCH.md "Don't Hand-Roll" table (no package needed for 3 dots). |
| `assets/rive/demo.riv` | asset | -- | Binary RIVE animation file. Must be created in RIVE editor or sourced from RIVE open-source examples. No analog in codebase. |
| `assets/images/onboarding/slide_1.webp` (+ slide_2, slide_3) | asset | -- | Placeholder images. No onboarding images exist yet. Create minimal placeholders. |

## Metadata

**Analog search scope:** `lib/core/`, `lib/features/`, `lib/`
**Files scanned:** 25+ Dart files across core and features directories
**Pattern extraction date:** 2026-04-17
