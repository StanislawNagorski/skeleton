# Native Rebase Runbook

When to use: Rebasing the skeleton onto a new Flutter major release (e.g., 3.41.5 -> next).

Last performed: 2026-04-16 (Flutter 3.41.5)

## Prerequisites

- FVM installed (`dart pub global activate fvm`)
- Xcode + CocoaPods (`sudo gem install cocoapods` or via Homebrew)
- Android Studio + Android SDK (with command-line tools)
- Clean working tree (commit or stash all changes)

## Pre-Rebase Safety

Step 0: Commit current state on a named branch as a recovery point.

```bash
git checkout -b rebase-flutter-X.Y.Z
git add -A && git commit -m "pre-rebase snapshot"
```

This branch is your rollback target if anything goes wrong during the rebase.

## Procedure

### Step 1: Bump FVM Pin

Update `.fvmrc` to the new Flutter version:

```json
{
  "flutter": "X.Y.Z"
}
```

Install and activate:

```bash
fvm install X.Y.Z && fvm use X.Y.Z
```

- **Verify:** `fvm flutter --version` reports the new version
- **What can go wrong:** FVM itself may need updating first. Run `dart pub global activate fvm` to get the latest version before installing a new Flutter SDK.

### Step 2: Generate Fresh Scaffold

Create a temp directory and generate fresh Flutter scaffolding using the pinned SDK:

```bash
mkdir /tmp/flutter-rebase-scaffold
cd /tmp/flutter-rebase-scaffold
fvm flutter create --platforms=android,ios --org=com.example --project-name=skeleton skeleton_temp
```

The `--platforms=android,ios` flag ensures no `web/`, `macos/`, `linux/`, or `windows/` directories are generated.

- **Verify:** The temp directory contains `android/` and `ios/` with the new SDK's defaults. Confirm no non-mobile platform directories exist: `ls -d skeleton_temp/web skeleton_temp/macos 2>/dev/null` should produce no output.
- **What can go wrong:** `flutter create` flags may change between majors -- check `fvm flutter create --help` for the current syntax. The `--org` and `--project-name` flags must match the skeleton's existing values.

### Step 3: Delete Old Native Directories

From the skeleton project root:

```bash
rm -rf android/ ios/
```

Also delete non-mobile platforms if they were re-created in a previous step:

```bash
rm -rf web/ macos/ linux/ windows/
```

Run `flutter clean` to clear cached references to deleted directories:

```bash
fvm flutter clean
```

- **Verify:** `ls -d android ios web macos linux windows 2>/dev/null` produces no output
- **What can go wrong:** If `flutter clean` is skipped, cached plugin registrations may reference deleted platform directories and cause confusing errors in later steps.

### Step 4: Copy Fresh Scaffold

```bash
cp -R /tmp/flutter-rebase-scaffold/skeleton_temp/android ./android
cp -R /tmp/flutter-rebase-scaffold/skeleton_temp/ios ./ios
```

- **Verify:** `ls android/app/build.gradle.kts` (or `build.gradle` depending on the SDK version) exists. The file extension tells you whether the SDK switched build script DSLs.
- **What can go wrong:** Flutter may switch between Groovy (`.gradle`) and Kotlin DSL (`.gradle.kts`) between major versions. The 3.41.5 rebase moved to Kotlin DSL. If the DSL changes, the release signing scaffolding (Step 9) must be rewritten in the new DSL.

### Step 5: Update iOS Podfile Floor

Open `ios/Podfile` and set the platform floor to match Firebase iOS SDK requirements:

```ruby
platform :ios, '15.0'
```

Update `IPHONEOS_DEPLOYMENT_TARGET` in `ios/Runner.xcodeproj/project.pbxproj` to match. Search and replace all occurrences:

```bash
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*/IPHONEOS_DEPLOYMENT_TARGET = 15.0/g' ios/Runner.xcodeproj/project.pbxproj
```

- **Verify:** `grep "platform :ios" ios/Podfile` shows `15.0`. Run `grep -c "IPHONEOS_DEPLOYMENT_TARGET = 15.0" ios/Runner.xcodeproj/project.pbxproj` to confirm all occurrences updated.
- **What can go wrong:** Firebase iOS SDK version may require a higher floor -- check the Firebase iOS SDK release notes for minimum deployment target. As of 2026, Firebase iOS SDK 12.x requires iOS 15.

### Step 6: Update pubspec.yaml SDK Constraint

Update the `environment.sdk` constraint to match the new Dart SDK:

```yaml
environment:
  sdk: ^X.Y.Z
```

Bump any dependencies whose constraints conflict with the new SDK. For example, `intl` was bumped from `^0.19.0` to `^0.20.2` in the 3.41.5 rebase because `flutter_localizations` pinned a newer version.

- **Verify:** `fvm flutter pub get` exits 0 with no dependency conflicts
- **What can go wrong:** Dependency version conflicts are the most common issue. Check pub.dev for compatible versions. Run `fvm flutter pub get` and read the error output carefully -- it usually tells you exactly which constraint is blocking.

### Step 7: Check L10n Generation Path

Flutter may change where l10n files are generated between major versions.

In 3.41.5, generation moved from `flutter_gen/gen_l10n/` (synthetic package) to in-place under the arb-dir. This required:

1. Adding `synthetic-package: false` to `l10n.yaml`
2. Updating imports in `lib/app.dart` from `package:flutter_gen/gen_l10n/app_localizations.dart` to `package:skeleton/core/localization/app_localizations.dart`
3. Updating the same import in `lib/core/extensions/context_extension.dart`

To check if this changed in your target version:

```bash
fvm flutter pub get
# Look for generated files:
find lib/core/localization -name "app_localizations*.dart" 2>/dev/null
find .dart_tool -path "*/flutter_gen/gen_l10n/*" 2>/dev/null
```

If generation moved, update `l10n.yaml` accordingly and fix all import paths.

- **Verify:** `fvm flutter pub get` generates localization files and all imports resolve. `fvm flutter analyze` shows no "Target of URI doesn't exist" errors related to localization.
- **What can go wrong:** Missing the import update causes analyzer errors that look unrelated to l10n. Always search for the old import path across the entire `lib/` tree: `grep -r "flutter_gen/gen_l10n" lib/`.

### Step 8: Regenerate Lockfiles and Generated Code

```bash
fvm flutter pub get
dart run build_runner build --delete-conflicting-outputs
cd ios && pod install && cd ..
```

- **Verify:** All three commands exit 0. Check that these generated files exist and have fresh timestamps:
  - `pubspec.lock`
  - `lib/core/injectable/injection.config.dart`
  - `lib/core/router/router.gr.dart`
  - `lib/core/database/app_database.g.dart`
- **What can go wrong:** `pod install` may fail on a stale CocoaPods repo cache. Run `pod repo update` first, then retry. If `build_runner` fails, check for breaking API changes in `auto_route_generator`, `injectable_generator`, or `drift_dev` -- you may need to bump their versions.

### Step 9: Apply Release Signing Scaffold

Check if the fresh `build.gradle.kts` (or `build.gradle`) still has the release signing block that reads from `key.properties` / env vars.

If lost in the rebase (it will be, since `flutter create` generates a clean build file), re-apply the signing config. The current skeleton's signing scaffold lives in `android/app/build.gradle.kts` and does:

1. Reads `key.properties` file (local dev path)
2. Falls back to environment variables (CI path)
3. If neither is present: logs a warning, sets `signingConfig = null` so release builds fail explicitly

Reference: `android/key.properties.template` contains the expected field format.

- **Verify:** `grep "key.properties" android/app/build.gradle.kts` finds the signing config. `grep "ANDROID_KEYSTORE_PATH" android/app/build.gradle.kts` finds the env var fallback.
- **What can go wrong:** If the build script DSL changed (Groovy to Kotlin or vice versa), the signing scaffold must be translated to the new DSL. The logic is identical -- only the syntax differs. See the existing `android/app/build.gradle.kts` for the Kotlin DSL version.

### Step 10: Run Full Verification

```bash
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug
fvm flutter build ios --debug --no-codesign
```

All four commands must exit 0.

- **Verify:** Each command completes without errors. Warnings are acceptable at this stage -- they will be addressed by lint upgrades in subsequent phases.
- **What can go wrong:** Deprecated APIs in the new SDK may cause analyzer errors (not just warnings). Fix these before proceeding. Common issues: renamed enum values, removed deprecated methods, changed constructor signatures in Flutter framework classes.

### Step 11: Review the Delta

```bash
git diff --stat
git diff
```

Walk through every changed file. Key things to check:

- Android AGP / Kotlin / Gradle versions match the new SDK's defaults
- iOS deployment target is correct (Podfile, project.pbxproj)
- No skeleton-specific customizations were lost (release signing, Podfile floor)
- `pubspec.lock` dependency versions are reasonable (no unexpected downgrades)
- Generated code compiles cleanly
- `.gitignore` still excludes `key.properties` and `*.jks`

Commit when satisfied:

```bash
git add -A && git commit -m "chore: rebase native scaffolding on Flutter X.Y.Z"
```

### Step 12: Update Documentation

1. Update the Version Matrix in README.md with the new component versions
2. Update this runbook's "Last performed" date and Flutter version at the top
3. Update `.planning/rebase_manifest.md` if the project uses GSD planning
4. Update the upgrade playbook (`docs/upgrade-playbook.md`) if any dependency upgrade procedures changed

## Version Matrix (3.41.5 Rebase)

Reference of what the 3.41.5 rebase produced:

| Component | Old | New |
|-----------|-----|-----|
| Flutter SDK | 3.29.0 | 3.41.5 |
| Dart SDK | ^3.6.0 | ^3.9.0 |
| AGP | 8.1.0 | 8.11.1 |
| Kotlin | 1.8.22 | 2.2.20 |
| Gradle | 8.1.0 | 8.14 |
| Build scripts | Groovy (.gradle) | Kotlin DSL (.gradle.kts) |
| Java target | 1.8 | 17 |
| iOS Podfile floor | 13.0 | 15.0 |

## Lessons Learned (3.41.5)

- **Groovy to Kotlin DSL:** Flutter 3.41.5 switched Android build scripts from Groovy (`.gradle`) to Kotlin DSL (`.gradle.kts`). All `build.gradle` files became `build.gradle.kts`. The release signing scaffold had to be rewritten in Kotlin syntax (`val`, `Properties()`, `signingConfigs { create("release") { ... } }`).

- **L10n generation path change:** L10n generation moved from the synthetic package (`flutter_gen/gen_l10n/`) to in-place generation under the arb-dir. This required adding `synthetic-package: false` to `l10n.yaml` and updating all import paths from `package:flutter_gen/gen_l10n/app_localizations.dart` to `package:skeleton/core/localization/app_localizations.dart`.

- **AppFrameworkInfo.plist change:** `AppFrameworkInfo.plist` no longer contains `MinimumOSVersion` in 3.41.5. The deployment target is set only via `IPHONEOS_DEPLOYMENT_TARGET` in `project.pbxproj`. Do not waste time looking for it in the plist.

- **Gradle properties defaults:** Fresh `gradle.properties` defaults from `flutter create` are fine for normal builds. Custom JVM args (`-Xmx4G -XX:MaxMetaspaceSize=2G`) are only needed if build-memory pressure occurs with large dependency trees.

- **intl dependency conflict:** The new Dart SDK pins a newer `flutter_localizations` which requires `intl ^0.20.2`. If your `pubspec.yaml` still declares `intl: ^0.19.0`, `flutter pub get` will fail with a version conflict. Bump `intl` first.

- **Pod install after directory swap:** Always delete `ios/Pods/` and `ios/Podfile.lock` before the swap, then regenerate via `pod install` after. Stale pod artifacts from the old SDK version cause cryptic build failures.

## Checklist (Quick Reference)

For quick reference during execution, here is the condensed checklist:

- [ ] Commit pre-rebase snapshot on a named branch
- [ ] Update `.fvmrc` to new Flutter version
- [ ] `fvm install X.Y.Z && fvm use X.Y.Z`
- [ ] Generate fresh scaffold: `fvm flutter create --platforms=android,ios ...`
- [ ] Delete old `android/`, `ios/`, and non-mobile platform directories
- [ ] `fvm flutter clean`
- [ ] Copy fresh `android/` and `ios/` from temp scaffold
- [ ] Set iOS Podfile floor to `15.0` (or whatever Firebase requires)
- [ ] Set `IPHONEOS_DEPLOYMENT_TARGET` to match in `project.pbxproj`
- [ ] Update `pubspec.yaml` SDK constraint
- [ ] Bump conflicting dependencies (check `intl`)
- [ ] Check l10n generation path and update imports if changed
- [ ] `fvm flutter pub get`
- [ ] `dart run build_runner build --delete-conflicting-outputs`
- [ ] `cd ios && pod install && cd ..`
- [ ] Re-apply release signing scaffold if lost
- [ ] `fvm flutter analyze` (must pass)
- [ ] `fvm flutter test` (must pass)
- [ ] `fvm flutter build apk --debug` (must pass)
- [ ] `fvm flutter build ios --debug --no-codesign` (must pass)
- [ ] Review `git diff`, commit
- [ ] Update README version matrix, this runbook, and rebase manifest
