# Phase 5: UX Patterns (Onboarding + RIVE Splash + Coach Marks) - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

RIVE 0.14 initialized in the startup service, a 3-slide onboarding feature gated by an `OnboardingGuard`, a `CoachMarkService` wrapper over `tutorial_coach_mark` with a live two-target demo on the counter page, and a dedicated RIVE demo page showcasing `.riv` loading + state-machine interaction. This phase also refactors `AuthGuard` from global to per-route — home becomes public, login becomes opt-in. The RIVE animated splash screen originally scoped in requirements is **dropped** (user decision: animated splash is an anti-pattern; native splash only). This phase does **not** touch the bootstrap script, i18n cleanup, tests, or documentation — those are owned by Phases 6-7.

</domain>

<decisions>
## Implementation Decisions

### Splash strategy (revised from requirements)
- **D-01:** No RIVE animated splash screen. No `SplashRoute`. The native splash (Flutter default) is the only splash. User lands directly on `OnboardingRoute` (first run) or `HomeRoute` (subsequent runs). Animated splashes are considered an anti-pattern — they add friction without value.
- **D-02:** `RiveNative.init()` is still called in `StartUpService` before `runApp` (required for RIVE runtime), but it does NOT drive a splash. It simply initializes the RIVE engine for use by the demo page and any downstream features.

### Guard ordering & routing flow
- **D-03:** `OnboardingGuard` runs first in the router's `guards` list: `[OnboardingGuard, AuthGuard]`. OnboardingGuard redirects to `OnboardingRoute` if `!hasSeenOnboarding`. AuthGuard evaluates only after onboarding is complete.
- **D-04:** `AuthGuard` moves from **global** (Phase 3 decision D-09) to **per-route**. `HomeRoute` is public — no authentication required. Login is an opt-in screen accessible from Home, not a forced gate. Only routes that explicitly need auth protection get `AuthGuard` applied.
- **D-05:** First-launch flow: Native splash → Onboarding (3 slides) → Home. Subsequent launches: Native splash → Home. Login is always a separate opt-in action from Home.
- **D-06:** After onboarding completes (user taps "Get Started" or "Skip"), `hasSeenOnboarding` flips to `true` via `PreferencesService`, and the user navigates to `HomeRoute`. Guard re-evaluation via `reevaluateListenable` handles the transition.

### Onboarding feature
- **D-07:** 3-slide `PageView` with generic placeholder content — title + subtitle + placeholder image per slide (e.g. "Welcome", "Discover Features", "Get Started"). Each app replaces the copy and images post-bootstrap.
- **D-08:** Static illustrations (placeholder images from `assets/images/`), NOT RIVE animations in onboarding slides. Keeps onboarding simple and replaceable.
- **D-09:** Skip button exits onboarding immediately — flips `hasSeenOnboarding=true` and navigates straight to Home. No "skip to last slide" intermediary.
- **D-10:** Dots indicator shows current position. "Next" button advances slides. Last slide shows "Get Started" CTA instead of "Next".
- **D-11:** `hasSeenOnboarding` persisted via `PreferencesService.setBool()` (the `SharedPreferencesAsync`-backed service from Phase 2). Key defined in a `core/preferences/` constants file.

### Coach marks
- **D-12:** `CoachMarkService` wraps `tutorial_coach_mark` with API: `register(GlobalKey key, String description, {String? title})` + `showTour(String tourId)`. Internally resolves registered keys to `TargetFocus` and handles "target not yet laid out" via `addPostFrameCallback`.
- **D-13:** Counter screen demo tour fires automatically on first visit only. Tour flag persisted per `tourId` in `SharedPreferences` via `PreferencesService`. No replay button — auto-trigger once, then never again.
- **D-14:** Two targets in the demo tour: (1) counter display value, (2) FAB. Shows how multi-step tours work as a reference pattern for downstream apps.
- **D-15:** Per-screen tours only. No cross-screen tour sequencing. Each `tourId` is scoped to one screen. Simpler API, downstream apps build chaining if needed.

### RIVE demo
- **D-16:** Two screens in the skeleton: Home page (counter + navigation button to RIVE demo) and a dedicated RIVE Demo page.
- **D-17:** RIVE Demo page loads a custom `.riv` asset via `RiveWidgetBuilder`, exposes a state-machine input toggle, and demonstrates the cleanup pattern (`dispose` of the controller). This is the primary showcase for how to use RIVE 0.14 in a feature.
- **D-18:** A simple custom `.riv` asset is created for the skeleton (e.g. a minimal shape animation) — shipped in `assets/rive/`. Each app replaces with their own `.riv` files.

### Claude's Discretion
- Exact onboarding placeholder text and image assets
- `CoachMarkService` internal implementation details (target resolution, animation config, overlay styling)
- RIVE Demo page layout and state-machine toggle implementation details
- Whether `OnboardingGuard` needs its own `reevaluateListenable` stream or piggybacks on the existing `PreferencesService`
- Navigation pattern from Home to RIVE Demo (button style, placement)
- `flutter_native_splash` configuration if any customization is needed for the minimal native splash
- How to handle `AuthGuard` refactor from global to per-route: whether via `guards` property on individual `AutoRoute` entries or a custom route-metadata approach

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### RIVE 0.14
- `.planning/research/STACK.md` — RIVE 0.14 version pin, `RiveNative.init()` API, `RiveWidget` / `RiveWidgetBuilder` usage
- `.planning/research/PITFALLS.md` — RIVE/native-splash handoff timing (flagged HIGH-risk; now mitigated by dropping RIVE splash)

### Routing & guards
- `lib/core/router/router.dart` — Current `AppRouter` with global `[AuthGuard]` in `guards` override (to be refactored to per-route)
- `lib/core/router/guards/auth_guard.dart` — Current `AuthGuard` implementation
- `lib/app.dart` — `reevaluateListenable` wiring
- `.planning/research/ARCHITECTURE.md` §Routing & Navigation — guard patterns, `reevaluateListenable`

### Preferences & persistence
- `lib/core/preferences/preferences_service.dart` — Abstract `PreferencesService` with `getBool`/`setBool` (Phase 2)
- `lib/core/preferences/preferences_service_impl.dart` — `SharedPreferencesAsync`-backed implementation

### Prior phase contracts
- `.planning/phases/03-package-upgrades-auth-contract/03-CONTEXT.md` — Phase 3 decisions D-08 through D-11 (guard wiring, LoginRoute placeholder, reevaluateListenable)
- `.planning/phases/04-firebase-wiring-auth-providers/04-CONTEXT.md` — Phase 4 decisions D-01 through D-03 (startup sequence, DI switching)
- `lib/core/auth/auth_service.dart` — AuthService contract (unchanged by this phase)
- `lib/main.dart` — Current entrypoint and startup sequence

### Phase requirements
- `.planning/REQUIREMENTS.md` §UX Patterns (UX-01 through UX-08)
- `.planning/ROADMAP.md` §Phase 5 Success Criteria 1-5

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`PreferencesService`** (Phase 2): Already provides `getBool`/`setBool` for `hasSeenOnboarding` and coach mark tour flags. No new persistence layer needed.
- **`AuthGuard`** (Phase 3): Existing implementation to be refactored from global to per-route.
- **`LoginRoute` placeholder** (Phase 3): Already exists as a minimal placeholder page. Stays as-is, now accessible as opt-in from Home.
- **`AppRouterObserver`** (existing): Logs route changes — will automatically log onboarding and RIVE demo navigation.
- **Design tokens** (`app_colors`, `app_themes`, `app_dimensions`): Available for onboarding slide styling.

### Established Patterns
- **Clean Architecture per feature**: Onboarding and RIVE demo follow `data/domain/presentation` layering. Onboarding needs a thin data layer (preferences flag) + presentation. RIVE demo is presentation-only.
- **`@RoutePage()` + `auto_route`**: Both new pages annotated and added to `AppRouter.routes`.
- **`@injectable` cubits**: Onboarding cubit manages slide state + `hasSeenOnboarding` flag. RIVE demo cubit manages state-machine interaction.
- **`BlocProvider(create: (_) => getIt<Cubit>()..init())`**: Established page-level cubit wiring pattern.

### Integration Points
- **`AppRouter.guards`**: Add `OnboardingGuard` before `AuthGuard`. Refactor `AuthGuard` to per-route.
- **`AppRouter.routes`**: Add `OnboardingRoute`, `RiveDemoRoute`.
- **`StartUpService.initServices()`**: Add `await RiveNative.init()` before Firebase init.
- **`pubspec.yaml`**: Add `rive: ^0.14.x`, `tutorial_coach_mark: ^x.x.x`, `flutter_native_splash` (if not already present).
- **`assets/`**: Add `assets/rive/` directory for `.riv` files, `assets/images/onboarding/` for placeholder illustrations.

</code_context>

<specifics>
## Specific Ideas

- **RIVE splash is an anti-pattern** — The user explicitly decided against an animated splash screen. The skeleton should demonstrate RIVE in a feature context (demo page), not a loading screen. This aligns with modern mobile UX: get users to content as fast as possible.
- **Home is public, login is opt-in** — This is a deliberate departure from Phase 3's global `AuthGuard`. The skeleton's stance is: most screens are public by default, auth only gates specific protected features. Downstream apps can tighten this by making `AuthGuard` global again if their app requires it.
- **Coach marks as a pattern, not a feature** — The two-target demo (counter display + FAB) exists to show downstream devs how to wire `CoachMarkService` for their own features. Per-screen scoping keeps the API simple.

</specifics>

<deferred>
## Deferred Ideas

- Cross-screen tour sequencing in CoachMarkService — downstream apps build chaining if needed
- RIVE animations in onboarding slides — decided against for simplicity, but could be added per-app
- Help/replay button for coach mark tours — decided against for skeleton, per-app addition
- UX-07 (RIVE-based animated splash with handoff) — explicitly dropped; success criteria 2 needs revision to match new approach

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-ux-patterns-onboarding-rive-splash-coach-marks*
*Context gathered: 2026-04-17*
