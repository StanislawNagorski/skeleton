# Phase 1: Native Rebase - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Regenerate `android/` and `ios/` from a fresh `flutter create` against Flutter 3.41.5, trim platforms to mobile-only (delete `web/`, `macos/`, `linux/`, `windows/`), preserve `lib/` verbatim, scaffold release signing, and unblock every downstream phase. This phase deliberately does **not** touch dependency versions, Firebase wiring, flavors, sealed-class refactors, or `lib/` migrations — those are owned by Phases 2–7.

</domain>

<decisions>
## Implementation Decisions

### Rebase safety & rollback
- **D-01:** Mark the pre-rebase state with a plain commit on the current `2026-update` branch — no extra tag, no feature branch. Recovery via `git reset` against the labeled commit hash.
- **D-02:** Explicitly `rm -rf` the stale `android/app/src/main/kotlin/com/example/skeleton/` folder as part of the rebase steps (`flutter create` doesn't reliably clean it; PITFALLS.md flags this). Verify only one `MainActivity.kt` exists post-rebase.
- **D-03:** Auto-delete `ios/Pods/` and `ios/Podfile.lock` as part of the rebase script (not as a manual README step), then run `pod install` fresh. Prevents the lock-vs-Podfile-floor-15 cascade documented in PITFALLS.md > FlutterFire Version Drift.

### Pubspec merge scope
- **D-04:** Touch only the `environment:` block (Dart `^3.9.0` and Flutter SDK floor) from the fresh template. Leave all `dependencies:`, `dev_dependencies:`, `flutter_lints`, `objectbox:` block, asset declarations, and package pins untouched. Phase 2 owns dep bumps + `very_good_analysis` swap + ObjectBox removal.
- **D-05:** Bump `.fvmrc` from `3.29.0` → `3.41.5` and run `fvm install 3.41.5 && fvm use 3.41.5` **before** the temp-dir `flutter create`. Guarantees the temp scaffold is generated against the target SDK, not whatever the host had.
- **D-06:** Asset directory declarations (`assets/images/`, `assets/sounds/`, `assets/images/webp/`) and the missing-directory pub-get warnings are **out of scope for Phase 1** — deferred to whichever phase actually adds an asset (Phase 4 launcher icons or Phase 6 RIVE assets).

### Release signing scaffolding (INFRA-04)
- **D-07:** `android/app/build.gradle` reads `android/key.properties` first; if absent, falls back to env vars (`ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`). Both paths populate the same `signingConfigs.release` block. Local devs use `key.properties`; CI uses env vars.
- **D-08:** When neither `key.properties` nor the env vars are present: define **no** `signingConfigs.release`, leave `buildTypes.release.signingConfig` unset, log a clear gradle-config-time warning. `flutter build apk --debug` continues to work; `flutter build apk --release` fails with a readable Gradle error pointing to the README. **No accidental debug-signed releases** — this is the explicit fix for the current `// TODO` in `android/app/build.gradle:33-39`.
- **D-09:** Ship `android/key.properties.template` (committed) with placeholder fields (`storeFile=keystore.jks`, `storePassword=`, `keyAlias=`, `keyPassword=`) and a comment block explaining the `keytool` generation one-liner. `.gitignore` excludes `android/key.properties` and `android/app/*.jks`. README gets a `Release signing` subsection: keytool command → copy template → fill values → `flutter build apk --release`.

### Native customizations to preserve
- **D-10:** **Do not** re-apply the `org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G` tweak from the current `android/gradle.properties`. Accept whatever fresh `flutter create` 3.41.5 emits as the baseline. Pure-rebase posture: customizations re-earn their place per project, not by inertia.
- **D-11:** **Do not** re-apply the `CADisableMinimumFrameDurationOnPhone = true` (120Hz unlock) entry in `ios/Runner/Info.plist`. Accept fresh template default. Re-add per-app if 120Hz becomes a requirement (Phase 6 RIVE work will revisit if needed).
- **D-12:** **Do not** preserve the iOS `CFBundleDisplayName = "Skeleton"` literal. Use `flutter create`'s default (driven by `--project-name=skeleton`). Phase 7 bootstrap script handles per-app display names.
- **D-13:** Write `.planning/rebase_manifest.md` as a Phase 1 deliverable. Lists every native edit (or explicit non-edit) the rebase made: deleted platforms, deleted Kotlin source folder, Podfile floor 15 alignment, signing config scaffolding, accepted-fresh-defaults list (JVM args, 120Hz, display name). Phase 8's full rebase runbook extends this — Phase 1 captures the running list while it's fresh.

### Claude's Discretion
- Exact wording of the gradle-config-time warning when `key.properties` and env vars are both missing
- Comment style and content of `android/key.properties.template`
- Section ordering and depth of `.planning/rebase_manifest.md` (must list every decision above; format is up to the planner)
- Exact `flutter create` invocation flags beyond `--platforms=android,ios --org=com.example --project-name=skeleton --ios-language=swift --android-language=kotlin` (per ARCHITECTURE.md Step 2)
- Whether to align `ios/Flutter/AppFrameworkInfo.plist` `MinimumOSVersion` to 15.0 alongside the Podfile bump (currently 12.0; CONCERNS.md flags the mismatch — recommended to align, but not blocking)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Rebase mechanics (the procedure to follow)
- `.planning/research/ARCHITECTURE.md` §Rebase Mechanics (repeatable process), Steps 0–6 — the full temp-dir + filesystem swap procedure, the pubspec merge approach, the post-rebase regeneration commands
- `.planning/research/PITFALLS.md` §Native Rebase Gotchas — the warning signs, prevention checklist (1–6), and the explicit recommendation to delete `Podfile.lock` + `Pods/` and the stale Kotlin folder
- `.planning/research/PITFALLS.md` §Removed platforms leftover refs — `flutter clean` requirement after deleting `web/macos/linux/windows/`

### Release signing
- `.planning/research/PITFALLS.md` §Release Keystore — `key.properties.template` pattern, `.gitignore` requirements, "do not ship a real keystore" rule
- `.planning/codebase/CONCERNS.md` §"Release build uses debug signing" — the current `// TODO: Add your own signing config` in `android/app/build.gradle:33-39` that this phase removes

### Constraints to honor
- `.planning/PROJECT.md` §Constraints — Flutter 3.41.5, AGP 8.11.1, Kotlin 2.2.20, Gradle 8.14, Java 17, iOS Podfile floor 15
- `.planning/REQUIREMENTS.md` §Infrastructure (INFRA-01 through INFRA-04) — the four exact requirement statements this phase satisfies
- `.planning/ROADMAP.md` §Phase 1 Success Criteria 1–5 — the five TRUE-statements that must hold before Phase 1 ships

### Existing native state to be replaced
- `.planning/codebase/STRUCTURE.md` §Directory Layout — the current `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/` shape
- `.planning/codebase/CONCERNS.md` §"Default `com.example.skeleton` package identifier still in place" — package id stays as placeholder (Phase 7 bootstrap renames)
- `.planning/codebase/CONCERNS.md` §"Android Kotlin plugin pinned to 1.8.22" + "iOS minimum deployment target is 13.0 / 12.0" — both are corrected by this phase

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`lib/` tree** (entire): preserved verbatim across the rebase. The native swap touches zero Dart source files.
- **`pubspec.yaml`**: dependency block preserved verbatim (Phase 2 owns the bumps). Only `environment:` block updated.
- **`l10n.yaml`, `analysis_options.yaml`, `.metadata`, `.planning/`, README, `.gitignore`**: all preserved verbatim.

### Established Patterns
- **FVM-pinned Flutter version** (`.fvmrc`): the rebase uses FVM throughout (`fvm install`, `fvm use`, `fvm flutter create`, `fvm flutter pub get`).
- **Generated files committed to repo**: post-rebase regeneration includes `dart run build_runner build --delete-conflicting-outputs` and `flutter gen-l10n` (the `flutter:generate: true` block in pubspec drives this on `pub get`).
- **Single-namespace Android project**: `com.example.skeleton` placeholder remains until Phase 7 bootstrap script.

### Integration Points
- **Phase 2 inherits**: a fresh `android/` + `ios/` with stock dependency block — no flavor wiring, no Firebase plugins applied yet. Phase 2 (`lints + sealed Result + Drift`) operates on `lib/` only and on `pubspec.yaml` deps.
- **Phase 4 inherits**: a stock `android/app/build.gradle` ready to receive `flavorDimensions` + `productFlavors` blocks and per-flavor `applicationIdSuffix`. A stock `ios/Runner.xcodeproj` ready to be duplicated into `dev`/`prod` schemes.
- **Phase 5 inherits**: a Podfile floored at 15 (so Firebase iOS SDK 12.x installs cleanly) and the FlutterFire CLI's expected directory layout for `--android-out` / `--ios-out` per flavor.
- **`.planning/rebase_manifest.md`** (new artifact from this phase) becomes the seed input for Phase 8's rebase runbook.

### What Goes Away
- `web/`, `macos/`, `linux/`, `windows/` directories deleted entirely.
- `ios/Podfile.lock`, `ios/Pods/` deleted (regenerated by `pod install`).
- Stale `android/app/src/main/kotlin/com/example/skeleton/` folder contents (the Kotlin tree under the renamed-by-flutter-create path).
- Existing `android/gradle.properties` JVM tweak, iOS `CADisableMinimumFrameDurationOnPhone`, iOS `CFBundleDisplayName = "Skeleton"` — none re-applied (D-10/D-11/D-12).
- The current `// TODO: Add your own signing config for the release build` (debug signing reused for release) in `android/app/build.gradle:33-39` (replaced by D-07/D-08/D-09).
- `.flutter-plugins-dependencies` and `pubspec.lock` regenerated against 3.41.5.

</code_context>

<specifics>
## Specific Ideas

- **Pure-rebase posture as guiding principle**: customizations from the old skeleton must re-earn their place rather than survive by inertia. JVM args, 120Hz unlock, display name overrides — all dropped. If they matter for downstream apps, they get re-added in the phase that surfaces the need (Phase 6 RIVE for 120Hz, Phase 4 flavors for app-name resValue, etc.).
- **Rebase manifest is a deliverable, not a side artifact**: future Flutter major rebases re-read it. Treat it like a runbook entry — same care as committed code.
- **Signing scaffolding's defining property: no silent debug-signed releases**. The whole point of INFRA-04. The skeleton must be louder than the original `// TODO` comment was.
- **Mobile-only is non-negotiable**: `flutter create --platforms=android,ios` (positional flag, not post-hoc deletion). Never let `web/`/`macos/`/`linux/`/`windows/` regenerate by accident.

</specifics>

<deferred>
## Deferred Ideas

- Asset directory `.gitkeep` placeholders / declaration cleanup → Phase 4 (launcher icons) or Phase 6 (RIVE assets) — whichever lands first
- Re-adding `org.gradle.jvmargs=-Xmx4G` to `android/gradle.properties` → consider only if Phase 5 (Firebase) or Phase 6 (RIVE) runs into build-memory pressure on the rebased tree
- Re-adding `CADisableMinimumFrameDurationOnPhone = true` → revisit in Phase 6 if RIVE animations stutter on ProMotion devices
- Aligning `ios/Flutter/AppFrameworkInfo.plist` `MinimumOSVersion` 12.0 → 15.0 (CONCERNS.md flagged mismatch) — Claude's discretion within Phase 1 if it surfaces during rebase, otherwise Phase 5 (Firebase wiring) will force it
- Per-flavor signing configs (`signingConfigs.releaseDev` vs `signingConfigs.releaseProd`) → Phase 4 (Flavors) — Phase 1 only scaffolds the single `signingConfigs.release` block

</deferred>

---

*Phase: 01-native-rebase*
*Context gathered: 2026-04-16*
