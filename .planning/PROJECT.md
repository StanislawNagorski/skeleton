# Skeleton — Flutter Mobile App Starter (2026 Refresh)

## What This Is

A reusable Flutter skeleton the author uses to bootstrap new mobile apps. This milestone refreshes the skeleton against 2026 Flutter tooling: native Android/iOS scaffolding is rebased on Flutter 3.41.5's `flutter create`, key packages are replaced or upgraded (Drift over ObjectBox, Dart 3 sealed classes over `dartz`, `flutter_bloc` 9, `auto_route` 11, RIVE 0.14), Firebase is wired end-to-end on the FlutterFire BoM 4.12.0 matrix (Firebase config files gitignored, configured per-app via FlutterFire CLI after bootstrap), and starter patterns for onboarding, in-app tutorials, and RIVE splash + animations are added. The outcome is a template whose `git clone → bootstrap → flutterfire configure → flutter run` loop lands a production-ready, Firebase-connected iOS + Android app in under 30 minutes.

## Core Value

Going from `git clone` to a working, Firebase-connected Flutter app on iOS and Android should take minutes, not hours — with a production-grade Clean Architecture already in place. Every decision in this refresh serves that one thing.

## Requirements

### Validated

<!-- Carried over from the existing skeleton; architectural patterns preserved through the rebase. -->

- ✓ Clean Architecture per feature (data / domain / presentation) — existing skeleton
- ✓ Cubit (BLoC) state management with `part`-linked immutable state — existing skeleton
- ✓ Dependency injection via `get_it` + `injectable`, abstract-class-first registration — existing skeleton
- ✓ Declarative routing via `auto_route` with `@RoutePage` annotations — existing skeleton
- ✓ Design token system (`app_colors`, `app_themes`, `app_dimensions`, `app_fonts`, `app_styles`) — existing skeleton
- ✓ ARB-based internationalization with PL + EN locales — existing skeleton
- ✓ Reactive local data pattern: data-source streams → repository → cubit → UI — existing skeleton
- ✓ Native rebase on Flutter 3.41.5 (AGP 8.11.1, Kotlin 2.2.20, Gradle 8.14, Java 17, iOS floor 15) — v1.0 Phase 1
- ✓ Platforms trimmed to iOS + Android only — v1.0 Phase 1
- ✓ Drift 2.32.1 replaces ObjectBox with reactive queries — v1.0 Phase 2
- ✓ Sealed `Result<T>` + `AppFailure` replaces dartz Either — v1.0 Phase 2
- ✓ `SharedPreferencesAsync` + `flutter_secure_storage` integrated — v1.0 Phase 2
- ✓ `very_good_analysis` lints with errors-not-warnings — v1.0 Phase 2
- ✓ `flutter_bloc` 9 + `auto_route` 11.1.0 upgraded — v1.0 Phase 3
- ✓ Abstract `AuthService` contract with sealed `AuthResult` — v1.0 Phase 3
- ✓ FlutterFire BoM 4.12.0 end-to-end (Core, Auth, Firestore, Crashlytics, Analytics, Performance, App Check) — v1.0 Phase 4
- ✓ Firebase Auth providers (Email, Google, Apple) wired natively — v1.0 Phase 4
- ✓ App Check release-only (`kReleaseMode` gate) — v1.0 Phase 4
- ✓ 3-slide onboarding with `OnboardingGuard` + `hasSeenOnboarding` persistence — v1.0 Phase 5
- ✓ `CoachMarkService` wrapper with FAB demo tour — v1.0 Phase 5
- ✓ RIVE 0.14 with `RiveNative.init()` + `RiveWidgetBuilder` demo page — v1.0 Phase 5
- ✓ `tool/bootstrap.dart` one-pass rename script — v1.0 Phase 6
- ✓ EN ARB template switch with `untranslated-messages-file` — v1.0 Phase 6
- ✓ Counter cubit + repository reference tests (bloc_test + mocktail + Drift in-memory) — v1.0 Phase 6
- ✓ README rewrite, rebase runbook, upgrade playbook — v1.0 Phase 7

### Active

(None — all v1.0 requirements shipped or descoped)

### Out of Scope

- Login UI screen — Firebase Auth providers are wired natively; each target app builds its own login UX
- CI/CD workflows (GitHub Actions, fastlane) — per-project concern; skeleton stays lean
- Pre-commit hooks (lefthook, husky) — developer-preference, added per-project
- Web / macOS / Linux / Windows scaffolding — mobile-first, re-add per-project if ever needed
- Anonymous auth — not required for the target app profile
- Staging flavor (third environment) — `dev` + `prod` cover current needs; adding staging is per-project
- Analytics event taxonomy / screen-tracking conventions — too app-specific for a skeleton
- In-app purchases / subscriptions scaffolding — added per-app when required
- Deep linking configuration (dynamic/universal links, Android intent filters) — per-app; skeleton exposes `auto_route` hooks only
- Push notification UI and routing logic — per-app; skeleton only initializes Firebase Messaging if needed later
- Full state-management migration to Riverpod — `flutter_bloc` stays, no need to swap
- Replacing `get_it` + `injectable` with another DI — proven, staying
- Replacing `auto_route` with `go_router` — `auto_route` stays, bumped to 11
- Shared demo Firebase project committed to the skeleton — skeleton stays Firebase-sterile; every new app creates its own `<name>-dev` and `<name>-prod` projects and runs `flutterfire configure` post-bootstrap
- `flutter_flavorizr` or other flavor generators — flavors are hand-rolled so every file is explicit, auditable in `git diff`, and independent of generator upgrades
- Firebase App Check in development builds — App Check only activates in release mode to avoid debug-token distribution overhead; dev builds call unprotected Firebase endpoints

## Context

- Skeleton lives at `/Users/stanislawnagorski/Developer/WeCodeMobile/skeleton/skeleton` on branch `2026-update`
- Current version `1.0.1+2`, Flutter `3.29.0` via FVM (`.fvmrc`), pubspec name `skeleton`, package id `com.example.skeleton`
- Authoritative snapshot of the current state lives in `.planning/codebase/` (STACK, ARCHITECTURE, STRUCTURE, CONVENTIONS, INTEGRATIONS, TESTING, CONCERNS)
- Author is a Flutter-first mobile dev at WeCodeMobile; this skeleton seeds apps that typically use Firebase Auth + Firestore + Crashlytics and ship RIVE animations
- Author writes his notes in Polish (`x_notes.txt`); codebase, docs, and README stay in English; only user-facing localization ships PL + EN
- Target apps landing on this skeleton after the refresh will reuse the same auth + cloud + RIVE pattern, so every pre-solved piece of native setup multiplies in value
- Native drift already observable: `.flutter-plugins-dependencies` was generated against Flutter `3.27.1` while `.fvmrc` pins `3.29.0`; AGP `8.1.0` and Kotlin `1.8.22` lag the current Flutter template defaults
- Known native debt documented in `.planning/codebase/CONCERNS.md`: release builds reuse the debug keystore (TODO in `android/app/build.gradle`), `com.example.skeleton` placeholder must be renamed per app, iOS deployment target sits at 13.0, and `test/` is empty
- Previous personal experience: author used Hive in earlier projects but it is effectively unmaintained now; has not used ObjectBox in practice — this motivated the Drift switch
- Research findings are captured in `.planning/research/` (STACK, FEATURES, ARCHITECTURE, PITFALLS, SUMMARY). Stack version pins come from STACK.md; architecture decisions (two-entrypoint flavor design, `AuthService` contract, sealed `Result<T>` + sealed `Failure`, init sequence) come from ARCHITECTURE.md; PITFALLS.md lists the known gotchas the roadmap must route around

## Constraints

- **Tech stack**: Flutter 3.41.5 stable / Dart 3.9, AGP 8.11.1 / Kotlin 2.2.20 / Gradle 8.14 / Java 17 on Android, iOS Podfile floor 15 (Firebase iOS SDK 12.x requires 15)
- **Platforms**: iOS + Android only — other platforms explicitly descoped
- **Languages**: code and documentation in English; user-facing UI localized PL + EN
- **Performance**: skeleton must not regress cold-start relative to the current baseline once Firebase + RIVE + Drift are initialized
- **DX**: `git clone → bootstrap → flutter run` under 30 minutes on a clean machine is the skeleton's reason to exist
- **Compatibility**: the rebase process itself must be repeatable — design bootstrap + rebase so the next Flutter major can replay them without a rewrite

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Rebase on fresh `flutter create` instead of surgical bump or clean-slate rewrite | Native scaffolding has drifted far enough (AGP, Kotlin, Gradle, iOS target) that patching in place is fragile, but `lib/` is still valuable and worth preserving verbatim | Validated — Phase 1 |
| Drift over ObjectBox (and over Hive-descendants) | ObjectBox is niche and unfamiliar to the author; Hive is unmaintained; Drift has strong typing, reactive queries, and active maintenance in 2026 | ✓ Good — v1.0 |
| Dart 3 sealed classes over `dartz` Either | `dartz` is effectively unmaintained; sealed classes + pattern matching give the same `Failure`/`Success` ergonomics natively, with better IDE and analyzer support | ✓ Good — v1.0 |
| Keep Cubit + `get_it` + `injectable` | Proven in the existing skeleton, author is fluent in them, no compelling 2026 reason to switch to Riverpod; the bloc 9 bump captures the upgrade path | Validated — Phase 3 |
| Firebase wired end-to-end rather than stubbed | Every target app uses Firebase Auth + cloud; stubbing forces the same wiring per app | Validated — Phase 4 |
| Auth providers wired natively, no login UI | Login UX varies per app; native setup (Info.plist URL schemes, SHA keys, build.gradle entries) is the painful repeatable part worth pre-solving | Validated — Phase 4 |
| `very_good_analysis` over `flutter_lints` | Stricter lints catch more real defects; skeleton sets the quality bar that every downstream app inherits | ✓ Good — v1.0 |
| iOS + Android only | Author builds mobile apps — other platforms add maintenance surface without actual use | Validated — Phase 1 |
| Dart bootstrap script for renaming | Manual renames across Android, iOS, and Dart are error-prone; a tested script replays deterministically per project | ✓ Good — v1.0 |
| Onboarding without a package | `PageView` + dots indicator is ~100 lines; a package adds maintenance risk for no real gain | ✓ Good — v1.0 |
| `tutorial_coach_mark` with a thin wrapper | Author has used this package successfully; a small `CoachMarkService` keeps feature code declarative and the API consistent across apps | ✓ Good — v1.0 |
| No CI / pre-commit hooks in the skeleton | Each project has different CI needs; skeleton stays minimal and downstream adds what it needs | ✓ Good — v1.0 |
| Two flavors (`dev`, `prod`) — no `staging` | Current apps only need two environments; adding `staging` is cheap later, carrying it now is dead weight | — Descoped from v1.0 (no flavors in skeleton) |
| Hand-rolled flavors (not `flutter_flavorizr`) | Every flavor file is explicit and visible in `git diff`; no dependency on an external generator | — Descoped from v1.0 (no flavors in skeleton) |
| Firebase config gitignored in skeleton — per-app projects, not shared demo | A shared demo Firebase would not be used; each new app creates its own projects and runs `flutterfire configure` after bootstrap | ✓ Good — v1.0 |
| Dev + prod = two separate Firebase projects (not one project with two apps) | Separate projects give separate Firestore, Auth user pool, Analytics, Crashlytics, and security rules per environment | ✓ Good — v1.0 |
| App Check only in release mode (`kReleaseMode`) | Debug tokens need per-developer registration in Firebase Console and the iOS console-print path is currently broken in flutterfire; gating on `kReleaseMode` removes the friction while still protecting prod | Validated — Phase 4 |
| ARB template switched PL → EN | PL-as-template is non-standard — tooling assumes EN; existing skeleton already shows PL/EN drift because of it; EN template + `untranslated-messages-file` CI check makes drift visible | ✓ Good — v1.0 |
| `auto_route` bumped 9 → 11.1.0 (skipping 10) | v10 was a transitional major whose guard API changed again in v11 — active development lives on v11 | ✓ Good — v1.0 |
| RIVE 0.14 (new `RiveNative.init()` / `RiveWidget` API) | 0.14 is a runtime rewrite built on `rive_native`; adopting it now avoids a second migration when the old `Rive` widget deprecates | ✓ Good — v1.0 |
| Central `AuthService` abstract class as the auth boundary | One contract (`Stream<AuthUser?>` + sealed `AuthResult`) feeds `auto_route` guards and every downstream feature; freezing it early prevents cascading churn in onboarding, coach marks, and apps built on top | Validated — Phase 3 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-18 after v1.0 milestone completion (2026 Refresh)*
