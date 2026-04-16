# Skeleton — Flutter Mobile App Starter (2026 Refresh)

## What This Is

A reusable Flutter skeleton the author uses to bootstrap new mobile apps. This milestone refreshes the skeleton against 2026 Flutter tooling: native Android/iOS scaffolding is rebased on a fresh `flutter create`, key packages are replaced or upgraded (Drift over ObjectBox, Dart 3 sealed classes over `dartz`, `flutter_bloc` 9, `auto_route` 10), Firebase is wired end-to-end (not stubbed), and starter patterns for onboarding, in-app tutorials, and RIVE animations are added. The outcome is a template whose `git clone → bootstrap → flutter run` loop lands a production-ready, Firebase-connected iOS + Android app in minutes.

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

### Active

<!-- In-scope for this milestone. Hypotheses until shipped. -->

- [ ] Rebase Android/iOS native scaffolding on the latest stable Flutter's `flutter create` output (AGP, Kotlin, Gradle, Podfile, deployment targets) while preserving `lib/`
- [ ] Replace ObjectBox with Drift; port the counter example to Drift with reactive queries and the same repo/service/cubit flow
- [ ] Add `shared_preferences` for user preferences and `flutter_secure_storage` for tokens
- [ ] Replace `dartz` `Either<Failure, T>` with Dart 3 sealed classes + pattern matching (keep the `Failure` type hierarchy concept)
- [ ] Upgrade `flutter_bloc` 8 → 9
- [ ] Upgrade `auto_route` 9 → 10
- [ ] Full Firebase wiring (no stubs): Core, Auth, Firestore, Crashlytics (+ global error handler via `PlatformDispatcher.instance.onError`), Analytics, Performance, App Check
- [ ] Firebase Auth providers configured natively (no UI screen): Email + Password, Google Sign-In, Apple Sign-In — including SHA keys, URL schemes, Info.plist entries
- [ ] Onboarding feature: 3-slide `PageView` with dots indicator + skip/next buttons, `hasSeenOnboarding` flag in `shared_preferences`, `auto_route` guard redirecting first-run users to onboarding
- [ ] `tutorial_coach_mark` integration with a `CoachMarkService` wrapper (`register(key, description)` + `showTour()`) and a live demo highlighting the counter screen's FAB
- [ ] RIVE integration: animated RIVE splash (post-native splash) + example widget demonstrating `.riv` loading and state-machine interaction
- [ ] Flavors: `dev` and `prod` with per-flavor bundle id, app name, launcher icon, and Firebase configuration files
- [ ] Bootstrap script: `dart run tool/bootstrap.dart --name <AppName> --bundle <com.foo.app>` that renames Dart package, iOS bundle id, Android namespace + applicationId, Info.plist display names, and launcher icon per flavor
- [ ] Remove unused declared dependencies: `http`, `uuid`, `collection`
- [ ] Switch from `flutter_lints` to `very_good_analysis`, configure analyzer with errors-not-warnings
- [ ] Add an example test covering the counter feature (cubit + repository) so every future feature has a pattern to copy
- [ ] Trim platforms to iOS + Android only (remove `web/`, `macos/`, `linux/`, `windows/` directories and plugin declarations)
- [ ] Update README with the new bootstrap flow, per-flavor FlutterFire wiring, architecture conventions, and upgrade playbook for the next Flutter major

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
- Replacing `auto_route` with `go_router` — `auto_route` stays, bumped to 10

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

## Constraints

- **Tech stack**: Flutter stable channel, Dart 3.x, iOS 15+, Android as per latest `flutter create` defaults — Firebase 11 already pushes iOS floor to 14/15
- **Platforms**: iOS + Android only — other platforms explicitly descoped
- **Languages**: code and documentation in English; user-facing UI localized PL + EN
- **Performance**: skeleton must not regress cold-start relative to the current baseline once Firebase + RIVE + Drift are initialized
- **DX**: `git clone → bootstrap → flutter run` under 30 minutes on a clean machine is the skeleton's reason to exist
- **Compatibility**: the rebase process itself must be repeatable — design bootstrap + rebase so the next Flutter major can replay them without a rewrite

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Rebase on fresh `flutter create` instead of surgical bump or clean-slate rewrite | Native scaffolding has drifted far enough (AGP, Kotlin, Gradle, iOS target) that patching in place is fragile, but `lib/` is still valuable and worth preserving verbatim | — Pending |
| Drift over ObjectBox (and over Hive-descendants) | ObjectBox is niche and unfamiliar to the author; Hive is unmaintained; Drift has strong typing, reactive queries, and active maintenance in 2026 | — Pending |
| Dart 3 sealed classes over `dartz` Either | `dartz` is effectively unmaintained; sealed classes + pattern matching give the same `Failure`/`Success` ergonomics natively, with better IDE and analyzer support | — Pending |
| Keep Cubit + `get_it` + `injectable` | Proven in the existing skeleton, author is fluent in them, no compelling 2026 reason to switch to Riverpod; the bloc 9 bump captures the upgrade path | — Pending |
| Firebase wired end-to-end rather than stubbed | Every target app uses Firebase Auth + cloud; stubbing forces the same wiring per app | — Pending |
| Auth providers wired natively, no login UI | Login UX varies per app; native setup (Info.plist URL schemes, SHA keys, build.gradle entries) is the painful repeatable part worth pre-solving | — Pending |
| `very_good_analysis` over `flutter_lints` | Stricter lints catch more real defects; skeleton sets the quality bar that every downstream app inherits | — Pending |
| iOS + Android only | Author builds mobile apps — other platforms add maintenance surface without actual use | — Pending |
| Dart bootstrap script for renaming | Manual renames across Android, iOS, and Dart are error-prone; a tested script replays deterministically per project | — Pending |
| Onboarding without a package | `PageView` + dots indicator is ~100 lines; a package adds maintenance risk for no real gain | — Pending |
| `tutorial_coach_mark` with a thin wrapper | Author has used this package successfully; a small `CoachMarkService` keeps feature code declarative and the API consistent across apps | — Pending |
| No CI / pre-commit hooks in the skeleton | Each project has different CI needs; skeleton stays minimal and downstream adds what it needs | — Pending |
| Two flavors (`dev`, `prod`) — no `staging` | Current apps only need two environments; adding `staging` is cheap later, carrying it now is dead weight | — Pending |

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
*Last updated: 2026-04-16 after initialization*
