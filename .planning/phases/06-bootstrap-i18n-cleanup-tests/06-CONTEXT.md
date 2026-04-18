# Phase 6: Bootstrap + i18n Cleanup + Tests - Context

**Gathered:** 2026-04-18
**Status:** Ready for planning

<domain>
## Phase Boundary

One-pass bootstrap rename script (`tool/bootstrap.dart`), PL→EN ARB template switch with key reconciliation, and reference tests for the counter feature (cubit + repository) that establish the copy-paste pattern for downstream features.

</domain>

<decisions>
## Implementation Decisions

### Bootstrap Script
- **D-01:** Script lives at `tool/bootstrap.dart` and is invoked via `dart run tool/bootstrap.dart --name <AppName> --bundle <com.foo.app>` — pure Dart, no shell dependencies
- **D-02:** Full rename pass covers: Dart package name (`skeleton` → new), iOS bundle identifier, Android namespace + applicationId, `Info.plist` `CFBundleDisplayName`, `pubspec.yaml` name + description, `README.md` title
- **D-03:** Script uses `dart:io` `File`/`Directory` for file system operations — no external packages needed
- **D-04:** Script validates inputs (non-empty name, valid reverse-domain bundle ID format) before starting rename
- **D-05:** Post-run checklist printed to stdout after successful rename — covers Firebase project creation, `flutterfire configure` invocation, SHA-1 registration, Apple capability steps

### ARB Template Switch
- **D-06:** `l10n.yaml` `template-arb-file` changes from `app_pl.arb` to `app_en.arb` — EN becomes the source of truth
- **D-07:** Both ARB files reconciled so no keys are missing in either — `untranslated-messages-file: untranslated_messages.txt` added to `l10n.yaml` and the output file gitignored
- **D-08:** Existing key order preserved; no key renames needed (keys are already `feature_element` format)

### Test Patterns
- **D-09:** Test framework: `bloc_test` for cubit tests, `mocktail` for fakes, Drift `NativeDatabase.memory()` for repository tests — matches project stack
- **D-10:** Test location: `test/features/home_page/` with `home_cubit_test.dart` and `counter_repository_test.dart` — mirrors `lib/features/` structure
- **D-11:** Tests serve as copy-paste templates — clear setup/teardown, named groups, comments explaining the pattern for new features
- **D-12:** Bootstrap script itself tested in `test/tool/bootstrap_test.dart` — runs rename on a fixture copy, asserts `flutter analyze` passes on the renamed output

### Claude's Discretion
- Bootstrap script internal structure (function decomposition, error handling approach)
- Test assertion granularity and naming conventions
- Whether to add a `--dry-run` flag to bootstrap (nice-to-have, not required)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project
- `.planning/PROJECT.md` — Core value, requirements, constraints
- `.planning/REQUIREMENTS.md` — TOOL-01 through TOOL-07 acceptance criteria
- `.planning/ROADMAP.md` — Phase 6 success criteria (5 checkpoints)

### Existing Code
- `pubspec.yaml` — Current package name, dependencies
- `l10n.yaml` — Current ARB config (template: app_pl.arb)
- `lib/core/localization/app_en.arb` — EN translations (source after switch)
- `lib/core/localization/app_pl.arb` — PL translations (current template)
- `android/app/build.gradle.kts` — namespace + applicationId locations
- `ios/Runner/Info.plist` — CFBundleDisplayName location

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- ARB files already in sync (23 keys each) — reconciliation is straightforward
- `pubspec.yaml` already uses `generate: true` for l10n

### Established Patterns
- Clean Architecture layering: `data/` → `domain/` → `presentation/` per feature
- DI via `get_it` + `injectable` — cubits registered as factories
- Sealed `Result<T>` pattern for error handling (Phase 2)
- `PreferencesService` abstraction for SharedPreferences access

### Integration Points
- `tool/bootstrap.dart` is standalone — no integration with existing lib/ code
- Tests need `bloc_test`, `mocktail` added to dev_dependencies
- `drift` test utilities (NativeDatabase.memory) need `sqlite3` dev dependency

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-bootstrap-i18n-cleanup-tests*
*Context gathered: 2026-04-18*
