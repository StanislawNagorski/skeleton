# Phase 7: Documentation - Research

**Researched:** 2026-04-18
**Domain:** Technical documentation (README, runbooks, playbooks) for a Flutter project template
**Confidence:** HIGH

## Summary

Phase 7 is a pure documentation phase with no code changes. It produces three deliverables: (1) a fully rewritten README.md that replaces the outdated original with a comprehensive guide covering the bootstrap script, FlutterFire setup, architecture conventions, and the AuthService contract; (2) a rebase runbook capturing the exact procedure used in Phase 1 so the next Flutter major can be replayed without reverse-engineering git history; and (3) an upgrade playbook covering FlutterFire BoM bumps, App Check verification, auto_route guard migration, and Drift schema migration verification.

The existing README is heavily outdated -- it still references ObjectBox, dartz, manual package renaming, and does not document the bootstrap script, sealed Result pattern, RIVE splash, onboarding, coach marks, or the dev/prod Firebase fallback. The Firebase Setup section (added in Phase 4) is the only current content and can be preserved and integrated into the rewrite.

**Primary recommendation:** Structure the README as a sequential flow matching the skeleton's core value proposition (`git clone -> bootstrap -> flutterfire configure -> flutter run`), with architecture and conventions as reference sections below the quickstart. The runbook and playbook belong in `docs/` as standalone markdown files.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-01 | README rewritten to document: bootstrap flow, FlutterFire setup, SHA-1 registration, architecture conventions (Clean Architecture + Cubit + sealed Result), AuthService contract, Firebase-sterile stance | README structure template below; existing Firebase Setup section preservable; architecture conventions derived from CLAUDE.md project scan |
| DOCS-02 | Native rebase procedure documented as repeatable runbook | Phase 1 plans (01-01-PLAN.md, 01-02-PLAN.md) contain the exact steps; distill into a standalone runbook |
| DOCS-03 | Upgrade playbook for FlutterFire BoM bump, App Check validation, auto_route guard migration, Drift schema migration | Each topic maps to a prior phase's research/plan; synthesize into a checklist-style playbook |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| README authoring | Documentation | -- | Pure markdown, no runtime component |
| Rebase runbook | Documentation | Build/CI | Documents build toolchain procedure |
| Upgrade playbook | Documentation | Build/CI | Documents dependency upgrade verification |

## Standard Stack

This phase requires no libraries. It produces markdown files only.

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Markdown | -- | Documentation format | Universal, renders on GitHub, readable raw |

### Supporting

No supporting libraries needed.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Markdown in `docs/` | MkDocs / Docusaurus site | Overkill for a starter template; markdown in-repo is zero-dependency |

## Architecture Patterns

### Documentation Structure

```
README.md                           # Primary entry point -- quickstart + reference
docs/
  rebase-runbook.md                 # DOCS-02: Repeatable native rebase procedure
  upgrade-playbook.md               # DOCS-03: BoM bump + verification checklists
```

### Pattern 1: README as Sequential Flow

**What:** Structure the README to match the user's actual journey: clone, bootstrap, configure Firebase, run. Architecture and conventions follow as reference.

**When to use:** Always for developer-facing starter templates.

**Recommended README sections (in order):**

```markdown
# {AppName} - Flutter App Template

## Quickstart
  ### Prerequisites
  ### 1. Clone & Bootstrap
  ### 2. Firebase Setup (Optional)
  ### 3. Run

## Architecture
  ### Clean Architecture Layers
  ### State Management (Cubit + sealed Result)
  ### Routing (auto_route 11)
  ### Dependency Injection (get_it + injectable)
  ### Error Handling (sealed Result<T> / AppFailure)
  ### AuthService Contract

## Firebase Integration
  ### Firebase-Sterile Stance
  ### FlutterFire Setup Checklist
  ### Google Sign-In Setup (SHA-1 + serverClientId)
  ### Apple Sign-In Setup (Capability + Services ID)
  ### App Check (Release Only)
  ### Crashlytics
  ### Dev Mode (No Firebase)

## UX Patterns
  ### Onboarding
  ### RIVE Splash
  ### Coach Marks

## Release Signing

## Code Generation

## Localization

## Testing

## Upgrading
  (Link to docs/upgrade-playbook.md)

## Rebasing on a New Flutter Version
  (Link to docs/rebase-runbook.md)
```

### Pattern 2: Runbook as Numbered Steps with Verification

**What:** Each step in the rebase runbook includes: (a) the command, (b) what to verify after, (c) what can go wrong. This makes the procedure replayable by someone who did not write it.

**When to use:** Any procedure that will be repeated months/years later.

### Pattern 3: Playbook as Checklist with Verification Commands

**What:** Each upgrade topic (BoM bump, App Check, auto_route, Drift) is a self-contained checklist with `fvm flutter` verification commands inline.

**When to use:** Dependency upgrade procedures where the risk is "it compiles but doesn't work correctly at runtime."

### Anti-Patterns to Avoid

- **Wall-of-text README:** Developers scan, not read. Use headers, numbered steps, and code blocks.
- **Documenting implementation instead of intent:** "Run `dart run tool/bootstrap.dart`" is good; pasting the bootstrap script source is bad.
- **Stale version numbers without context:** Always pair version numbers with "as of {date}" or "pinned in pubspec.yaml" so readers know where the source of truth lives.
- **Duplicating content between README and docs/:** README links to docs/ for deep-dive procedures; does not inline them.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Generating docs site | Custom static site | Raw markdown in repo | Zero maintenance, GitHub renders natively |
| API reference docs | Manual API docs | Code comments + `dart doc` | Stays in sync with code |

## Common Pitfalls

### Pitfall 1: README Diverges from Actual Bootstrap Output

**What goes wrong:** The README documents steps that the bootstrap script has already automated, or misses steps the script does NOT handle (like `flutterfire configure`).
**Why it happens:** README written from memory instead of from the actual `tool/bootstrap.dart` output.
**How to avoid:** Run the bootstrap script, capture its output (including the post-run checklist), and write the README to match exactly.
**Warning signs:** README says "rename X manually" for something bootstrap already handles.

### Pitfall 2: Rebase Runbook Missing Implicit Steps

**What goes wrong:** The runbook says "swap android/ and ios/" but omits that you need to `flutter clean` first, or that `pod install` needs `pod repo update` on a stale machine.
**Why it happens:** The person who did the rebase had a warm cache and didn't hit these issues.
**How to avoid:** Include every `rm`, `clean`, `pod repo update` step from the Phase 1 plans. The plans are the authoritative source -- they were battle-tested.
**Warning signs:** Runbook has fewer than 10 steps (the real procedure has ~15-20).

### Pitfall 3: Upgrade Playbook Assumes Runtime Verification is Optional

**What goes wrong:** Developer bumps BoM versions, `flutter analyze` passes, they ship. But App Check silently stopped activating because the provider class was renamed.
**Why it happens:** Compile-time checks don't catch runtime configuration issues.
**How to avoid:** Playbook must include runtime verification steps: "Build release APK, install on device, check Firebase Console for App Check attestation."
**Warning signs:** Playbook only has `flutter analyze` and `flutter test` as verification.

### Pitfall 4: Old README Content Left Inline

**What goes wrong:** Sections referencing ObjectBox, dartz, `flutter_lints`, or manual package renaming survive the rewrite.
**Why it happens:** Incremental editing instead of full rewrite.
**How to avoid:** Start from a blank file using the recommended structure above. Selectively port only the Firebase Setup section (which was rewritten in Phase 4).
**Warning signs:** Any mention of ObjectBox, dartz, `device_info_plus`, `uuid`, `collection`, or `flutter_lints`.

## Code Examples

No code in this phase. The deliverables are markdown documents.

### Key Content to Reference

The README and docs need to accurately reference these existing artifacts:

**Bootstrap script usage:**
```bash
dart run tool/bootstrap.dart --name MyApp --bundle com.example.myapp
```
[VERIFIED: tool/bootstrap.dart header comment]

**AuthService contract summary (for README):**
```dart
abstract class AuthService {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  Future<AuthResult> signInWithEmail({...});
  Future<AuthResult> signUpWithEmail({...});
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> signInWithApple();
  Future<void> signOut();
  Future<AuthResult> sendPasswordReset({...});
}
```
[VERIFIED: lib/core/auth/auth_service.dart]

**Dev mode fallback (for README):**
- Stub `firebase_options.dart` causes `Firebase.initializeApp` to throw
- StartUpService catches the error, sets environment to `'dev'`
- DI registers `FakeAuthService` instead of `FirebaseAuthService`
[VERIFIED: lib/startup_service.dart lines 33-48]

**Rebase procedure source material:**
- Phase 1 Plan 01: FVM bump, `flutter create --platforms=android,ios`, swap native dirs, delete non-mobile platforms, Podfile floor 15, pubspec env update, regenerate lockfiles
- Phase 1 Plan 02: Release signing scaffolding (`key.properties.template`), rebase manifest
[VERIFIED: .planning/phases/01-native-rebase/01-01-PLAN.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual package renaming (README instructions) | `dart run tool/bootstrap.dart` single-pass | Phase 6 (2026-04-18) | README must document bootstrap, not manual steps |
| ObjectBox + dartz | Drift + sealed Result | Phase 2 | README must not reference ObjectBox or dartz |
| `flutter_lints` | `very_good_analysis` | Phase 2 | README must reference VGA |
| `auto_route` 9 with `$AppRouter` | `auto_route` 11 with `RootStackRouter` + guards property | Phase 3 | README must document new guard pattern |
| Firebase commented out | Firebase with dev/prod fallback | Phase 4 | README must document Firebase-sterile stance + dev mode |
| No onboarding/RIVE/coach marks | Full UX pattern set | Phase 5 | README should mention these features |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `docs/` directory is the right location for runbook + playbook (vs `.planning/`) | Architecture Patterns | Low -- ROADMAP.md says "in `docs/` or `.planning/`"; `docs/` is more conventional for user-facing docs |
| A2 | The bootstrap script's post-run checklist output matches what TOOL-02 specifies | Common Pitfalls | Medium -- if checklist format changed during execution, README might not match |

## Open Questions

1. **Exact bootstrap script post-run output format**
   - What we know: TOOL-02 requires it prints a Firebase setup checklist
   - What's unclear: The exact text format of the printed checklist (need to run the script or read the full source)
   - Recommendation: Read `tool/bootstrap.dart` fully during planning to capture the exact output

2. **Whether README should document onboarding/RIVE/coach marks in detail**
   - What we know: These are UX features added in Phase 5
   - What's unclear: How much detail the README needs vs. letting code speak for itself
   - Recommendation: Brief mention with pointer to the feature directory; the skeleton is a template, not a tutorial

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test` + `mocktail` |
| Config file | pubspec.yaml (dev_dependencies) |
| Quick run command | `fvm flutter test` |
| Full suite command | `fvm flutter test` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCS-01 | README contains required sections | manual-only | Visual inspection | N/A |
| DOCS-02 | Rebase runbook is complete and accurate | manual-only | Visual inspection against Phase 1 plans | N/A |
| DOCS-03 | Upgrade playbook covers all four topics | manual-only | Visual inspection | N/A |

### Sampling Rate

- **Per task commit:** Visual review of markdown structure and content completeness
- **Per wave merge:** Cross-reference against requirements checklist
- **Phase gate:** All three documents exist, all DOCS-0x requirements addressed

### Wave 0 Gaps

None -- documentation phase requires no test infrastructure. Verification is manual review against requirements.

## Security Domain

This phase produces documentation files only. No runtime code, no user input handling, no authentication changes, no cryptographic operations. Security considerations are not applicable.

The README and playbook SHOULD document security-relevant procedures (SHA-1 registration, App Check verification, signing key management) accurately, but these are documentation of existing Phase 1/4 implementations, not new security surface.

## Sources

### Primary (HIGH confidence)
- `tool/bootstrap.dart` -- bootstrap script header and usage [read directly]
- `lib/core/auth/auth_service.dart` -- AuthService contract [read directly]
- `lib/startup_service.dart` -- dev/prod fallback mechanism [read directly]
- `lib/main.dart` -- app entry point with guard setup [read directly]
- `.planning/phases/01-native-rebase/01-01-PLAN.md` -- rebase procedure source [read directly]
- `README.md` -- current README state (outdated, needs full rewrite) [read directly]
- `.planning/REQUIREMENTS.md` -- DOCS-01, DOCS-02, DOCS-03 requirements [read directly]
- `.planning/ROADMAP.md` -- Phase 7 success criteria [read directly]
- `pubspec.yaml` -- current dependency versions [read directly]

### Secondary (MEDIUM confidence)
- None needed -- all sources are first-party project files

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no libraries, pure documentation
- Architecture: HIGH -- document structure is straightforward; source material (prior phase plans) is complete and accessible
- Pitfalls: HIGH -- common documentation anti-patterns are well-understood

**Research date:** 2026-04-18
**Valid until:** 2026-06-18 (60 days -- documentation structure is stable; content references pinned versions)
