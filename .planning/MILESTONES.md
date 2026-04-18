# Milestones

## v1.0 — 2026 Refresh

**Shipped:** 2026-04-18
**Phases:** 7 | **Plans:** 19 | **Commits:** 141
**Files:** 276 changed | **LOC:** 3,553 Dart
**Timeline:** 2026-04-16 → 2026-04-18 (3 days)

### Key Accomplishments

1. Native rebase onto Flutter 3.41.5 (AGP 8.11.1, Kotlin 2.2.20, Gradle 8.14, Java 17, iOS floor 15)
2. Sealed `Result<T>` + `AppFailure` replacing dartz, ObjectBox → Drift migration, `very_good_analysis` lints
3. `flutter_bloc` 9 + `auto_route` 11 + abstract `AuthService` contract with sealed `AuthResult`
4. Full FlutterFire BoM 4.12.0 wiring (Core, Auth, Firestore, Crashlytics, Analytics, Performance, App Check)
5. RIVE 0.14 splash + 3-slide onboarding with guard + CoachMarkService with FAB demo
6. `tool/bootstrap.dart` one-pass rename script + EN template ARB switch + reference tests
7. README rewrite + rebase runbook + upgrade playbook

### Known Deferred Items

8 human-verification items deferred at close (see STATE.md Deferred Items):
- 4 UAT gap sets (Phases 01, 02, 04, 05)
- 4 verification items requiring manual device testing

### Archive

- [v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)
- [v1.0-REQUIREMENTS.md](milestones/v1.0-REQUIREMENTS.md)
