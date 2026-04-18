---
phase: 05-ux-patterns-onboarding-rive-splash-coach-marks
verified: 2026-04-18T01:04:31Z
status: human_needed
score: 5/5
overrides_applied: 2
overrides:
  - must_have: "On first launch, the user sees a native splash -> RIVE animated splash -> 3-slide PageView onboarding with dots + skip/next buttons, then lands on the home screen; subsequent launches skip onboarding and go straight home"
    reason: "RIVE animated splash explicitly dropped per user decision D-01 (05-CONTEXT.md). Flow is native splash -> onboarding -> home (first run) or native splash -> home (subsequent). The onboarding + skip logic is fully implemented. ROADMAP SC not updated to reflect descope."
    accepted_by: "user (D-01 in 05-CONTEXT.md)"
    accepted_at: "2026-04-17T00:00:00Z"
  - must_have: "await RiveNative.init() is called in each main_*.dart before runApp, and the splash-to-home handoff happens via addPostFrameCallback + FlutterNativeSplash.remove() with no visible flicker"
    reason: "RiveNative.init() IS called before runApp in StartUpService. FlutterNativeSplash.remove() not needed because RIVE animated splash was dropped per D-01. Native splash uses Flutter's default mechanism. The RiveNative.init() portion of this SC is verified."
    accepted_by: "user (D-01 in 05-CONTEXT.md)"
    accepted_at: "2026-04-17T00:00:00Z"
human_verification:
  - test: "First launch onboarding flow"
    expected: "App opens to 3-slide onboarding with dot indicator, skip/next/get-started buttons. Completing or skipping routes to Home."
    why_human: "Requires running app on simulator to verify visual flow, animations, and guard behavior"
  - test: "Subsequent launch skips onboarding"
    expected: "Kill and relaunch app -- goes straight to Home (no onboarding)"
    why_human: "Requires SharedPreferences persistence across app restarts"
  - test: "Coach mark tour on first Home visit"
    expected: "Two-target overlay highlights counter display then FAB with tooltips. Does not re-show on subsequent visits."
    why_human: "Coach mark overlay rendering and TutorialCoachMark behavior must be verified visually"
  - test: "RIVE demo page"
    expected: "Navigating from Home to RIVE Demo page shows animation canvas (or error if placeholder .riv). Switch toggle is present."
    why_human: "RIVE widget rendering and state-machine interaction require visual confirmation"
  - test: "Auth guard is per-route only"
    expected: "Home is public (no auth redirect). Login route still functions."
    why_human: "Guard evaluation order requires runtime verification"
---

# Phase 5: UX Patterns (Onboarding + RIVE Splash + Coach Marks) Verification Report

**Phase Goal:** RIVE 0.14 initialized and driving an animated splash that hands off to the app, a 3-slide onboarding feature gated by an `auto_route` guard, and a `CoachMarkService` wrapper with a live FAB demo on the counter page
**Verified:** 2026-04-18T01:04:31Z
**Status:** human_needed
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | On first launch, user sees native splash -> RIVE animated splash -> onboarding -> home; subsequent launches skip onboarding | PASSED (override) | Override: RIVE animated splash dropped per D-01. Onboarding flow implemented: 3-slide PageView with dots, skip/next/get-started. OnboardingGuard redirects first-run users. hasSeenOnboarding flag persists via PreferencesService. |
| 2 | RiveNative.init() called before runApp, splash-to-home handoff via addPostFrameCallback + FlutterNativeSplash.remove() | PASSED (override) | Override: FlutterNativeSplash.remove() not needed (D-01). RiveNative.init() IS called in StartUpService.initServices() at line 31, BEFORE Firebase try-block. Verified in startup_service.dart. |
| 3 | hasSeenOnboarding persisted via SharedPreferencesAsync through core/preferences service; OnboardingGuard redirects first-run users | VERIFIED | PreferencesKeys.hasSeenOnboarding = 'hasSeenOnboarding' in preferences_keys.dart. main.dart pre-reads flag at line 21-24. OnboardingGuard checks cached bool in onNavigation (line 27). OnboardingCubit.completeOnboarding() persists flag + calls markOnboardingSeen() + toggles MyApp.onboardingNotifier. |
| 4 | On first visit to counter page, FAB highlighted by CoachMarkService.showTour('home'); subsequent visits no re-show | VERIFIED | CoachMarkService.showTour() checks 'tour_home_seen' pref (line 49-51). Home page registers 2 targets (_counterKey, _fabKey) in initState (lines 80-94). showTour called via addPostFrameCallback (lines 97-101). onFinish persists flag (line 123). unregister in dispose (line 107). |
| 5 | Dedicated demo screen loads .riv asset with RiveWidgetBuilder, exposes state-machine input toggle, cleans up controller in dispose | VERIFIED | rive_demo_page.dart: FileLoader.fromAsset('assets/rive/demo.riv') at line 38-41. RiveWidgetBuilder at line 75 with RiveLoading/RiveFailed/RiveLoaded handling. SwitchListTile toggle at line 100-110. BooleanInput disposed at line 49, FileLoader disposed at line 50. |

**Score:** 5/5 truths verified (2 via override)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/core/router/guards/onboarding_guard.dart` | OnboardingGuard with cached boolean | VERIFIED | 33 lines, extends AutoRouteGuard, pre-cached _hasSeenOnboarding, markOnboardingSeen(), no async in onNavigation |
| `lib/core/preferences/preferences_keys.dart` | Centralized preference key constants | VERIFIED | 8 lines, hasSeenOnboarding + tourHomeCompleted constants |
| `assets/rive/demo.riv` | Minimal RIVE animation | VERIFIED (placeholder) | File exists but is empty placeholder -- RiveWidgetBuilder will show RiveFailed state. Intentional per skeleton design (replaced per-app). |
| `lib/features/onboarding/presentation/onboarding_page.dart` | Onboarding with PageView | VERIFIED | 163 lines, @RoutePage, BlocProvider, 3 OnboardingSlide children, DotIndicator, FilledButton, TextButton skip, PopScope |
| `lib/features/onboarding/presentation/cubit/onboarding_cubit.dart` | Slide state + persistence | VERIFIED | 50 lines, @injectable, nextPage/onPageChanged/completeOnboarding/skipOnboarding, persists flag, fires notifier |
| `lib/features/onboarding/presentation/cubit/onboarding_state.dart` | Immutable state | VERIFIED | 38 lines, currentPage/totalPages/status, isLastPage getter, copyWith, OnboardingPageStatus enum |
| `lib/features/onboarding/presentation/widgets/onboarding_slide.dart` | Single slide widget | VERIFIED | Renders Image.asset + title + subtitle with theme styling |
| `lib/features/onboarding/presentation/widgets/dot_indicator.dart` | Animated dot indicator | VERIFIED | Row of AnimatedContainer circles, 8px, 300ms, primary/surfaceContainerHighest |
| `lib/features/rive_demo/presentation/rive_demo_page.dart` | RIVE demo with RiveWidgetBuilder | VERIFIED | 142 lines, @RoutePage, FileLoader.fromAsset, RiveWidgetBuilder, SwitchListTile, dispose cleanup |
| `lib/features/rive_demo/presentation/cubit/rive_demo_cubit.dart` | Toggle state management | VERIFIED | 30 lines, @injectable, toggleAnimation/onLoaded/onLoadFailed |
| `lib/features/rive_demo/presentation/cubit/rive_demo_state.dart` | Immutable RIVE demo state | VERIFIED | 32 lines, isToggled/status, copyWith, RiveDemoPageStatus enum |
| `lib/core/coach_mark/coach_mark_service.dart` | CoachMarkService wrapper | VERIFIED | 140 lines, @lazySingleton, register/unregister/showTour, addPostFrameCallback, TutorialCoachMark, preference persistence |
| `lib/features/home_page/presentation/home_page.dart` | Counter page with coach marks + RIVE nav | VERIFIED | 166 lines, GlobalKey _counterKey/_fabKey, CoachMarkService integration, OutlinedButton to RiveDemoRoute |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| startup_service.dart | rive | RiveNative.init() | WIRED | Line 31: `await RiveNative.init();` before Firebase try-block |
| router.dart | onboarding_guard.dart | global guards list | WIRED | Line 23-25: `guards = [onboardingGuard]` |
| main.dart | router.dart | AppRouter with PreferencesService | WIRED | Lines 26-33: Pre-reads flag, creates OnboardingGuard, passes to AppRouter |
| onboarding_cubit.dart | PreferencesService | setBool(PreferencesKeys.hasSeenOnboarding) | WIRED | Line 37-39: persists flag in completeOnboarding() |
| onboarding_cubit.dart | app.dart | MyApp.onboardingNotifier | WIRED | Line 44: toggles notifier for guard re-evaluation |
| rive_demo_page.dart | assets/rive/demo.riv | FileLoader.fromAsset | WIRED | Lines 38-41: loads from bundled assets |
| rive_demo_page.dart | rive | RiveWidgetBuilder | WIRED | Line 75: declarative loading with builder |
| coach_mark_service.dart | tutorial_coach_mark | TutorialCoachMark | WIRED | Line 59: constructs TutorialCoachMark with targets |
| coach_mark_service.dart | PreferencesService | setBool for tour flag | WIRED | Line 123: persists tour_${tourId}_seen |
| home_page.dart | coach_mark_service.dart | showTour('home') | WIRED | Line 100: calls showTour in addPostFrameCallback |
| home_page.dart | router.dart | RiveDemoRoute push | WIRED | Line 137: context.router.push(const RiveDemoRoute()) |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| onboarding_page.dart | OnboardingState (currentPage, isLastPage) | OnboardingCubit emit() | Yes -- cubit manages page index | FLOWING |
| rive_demo_page.dart | RiveDemoState (isToggled) | RiveDemoCubit.toggleAnimation() | Yes -- toggle state managed by cubit | FLOWING |
| home_page.dart | coach mark targets | CoachMarkService._tours | Yes -- register() populates in initState | FLOWING |
| onboarding_cubit.dart | hasSeenOnboarding | PreferencesService.setBool | Yes -- real persistence call | FLOWING |

### Behavioral Spot-Checks

Step 7b: SKIPPED (no runnable entry points -- Flutter app requires simulator/device)

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| UX-01 | 05-02 | 3-slide PageView onboarding | SATISFIED | onboarding_page.dart with 3 OnboardingSlide children, dots, skip/next/get-started |
| UX-02 | 05-01, 05-02 | hasSeenOnboarding via SharedPreferencesAsync | SATISFIED | PreferencesKeys.hasSeenOnboarding, OnboardingCubit.completeOnboarding persists via PreferencesService |
| UX-03 | 05-01, 05-02 | auto_route guard redirects first-run users | SATISFIED | OnboardingGuard in global guards, redirects to OnboardingRoute when flag is false |
| UX-04 | 05-04 | CoachMarkService wrapper API | SATISFIED | coach_mark_service.dart with register/showTour/unregister, addPostFrameCallback safety |
| UX-05 | 05-04 | Counter screen FAB coach mark demo | SATISFIED | home_page.dart registers 2 targets, auto-fires tour on first visit, persists completion |
| UX-06 | 05-01 | RiveNative.init() in startup service | SATISFIED | startup_service.dart line 31: await RiveNative.init() before Firebase |
| UX-07 | 05-01 | RIVE animated splash with handoff | SATISFIED (descoped) | Explicitly dropped per D-01 (animated splashes are anti-pattern). RiveNative.init() still runs for RIVE runtime. REQUIREMENTS.md marked complete. |
| UX-08 | 05-03 | RIVE demo screen with RiveWidgetBuilder | SATISFIED | rive_demo_page.dart with FileLoader, RiveWidgetBuilder, SwitchListTile toggle, proper disposal |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| assets/rive/demo.riv | - | Empty placeholder file (not valid .riv binary) | INFO | RiveWidgetBuilder will show RiveFailed state. Intentional -- each downstream app provides their own .riv. |

### Human Verification Required

### 1. First Launch Onboarding Flow

**Test:** Run `fvm flutter run` on a simulator with cleared app data. Verify onboarding appears with 3 slides, dot indicator, skip/next/get-started buttons.
**Expected:** Slides render with placeholder images + localized text. Skip or Get Started routes to Home.
**Why human:** Visual layout, animation timing, and guard redirect behavior require runtime observation.

### 2. Subsequent Launch Skip

**Test:** Kill and relaunch the app after completing onboarding.
**Expected:** App goes straight to Home (no onboarding).
**Why human:** SharedPreferences persistence across cold restarts cannot be verified statically.

### 3. Coach Mark Tour

**Test:** On first visit to Home after onboarding, observe coach mark overlay.
**Expected:** Two-target tour (counter display, then FAB) with tooltip text. Does not re-show on second visit.
**Why human:** TutorialCoachMark overlay rendering and addPostFrameCallback timing require visual confirmation.

### 4. RIVE Demo Page

**Test:** Tap "RIVE Demo" button on Home page.
**Expected:** RIVE demo page opens. Animation canvas shows loading/error (placeholder .riv). Switch toggle is present and functional (when real .riv provided).
**Why human:** RIVE widget rendering and navigation behavior require runtime testing.

### 5. Auth Guard Per-Route

**Test:** Verify Home is accessible without authentication. Login route still functions.
**Expected:** Home is public. AuthGuard only on /login route.
**Why human:** Guard evaluation order requires runtime verification with actual navigation.

### Gaps Summary

No code-level gaps found. All artifacts exist, are substantive, and are properly wired. All 8 UX requirements are accounted for (UX-07 explicitly descoped per user decision D-01, documented in 05-CONTEXT.md and 05-RESEARCH.md).

The two ROADMAP success criteria referencing the RIVE animated splash (SC1: "native splash -> RIVE animated splash" and SC2: "FlutterNativeSplash.remove()") do not match the implementation because the splash was intentionally dropped during the discussion phase. These are handled via overrides documented above. The ROADMAP.md success criteria should be updated to reflect the descope decision.

Five human verification items remain -- all require running the app on a simulator/device to confirm visual behavior, guard redirects, and persistence across restarts.

---

_Verified: 2026-04-18T01:04:31Z_
_Verifier: Claude (gsd-verifier)_
