---
phase: 01-native-rebase
reviewed: 2026-04-16T12:00:00Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - android/app/build.gradle.kts
  - android/build.gradle.kts
  - android/settings.gradle.kts
  - android/gradle.properties
  - android/key.properties.template
  - android/gradle/wrapper/gradle-wrapper.properties
  - android/app/src/main/kotlin/com/example/skeleton/MainActivity.kt
  - ios/Podfile
  - ios/Runner/AppDelegate.swift
  - ios/Runner/SceneDelegate.swift
  - ios/Runner/Info.plist
  - ios/Flutter/AppFrameworkInfo.plist
  - .fvmrc
  - .gitignore
  - README.md
  - pubspec.yaml
  - lib/app.dart
  - lib/core/extensions/context_extension.dart
findings:
  critical: 1
  warning: 5
  info: 3
  total: 9
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-04-16T12:00:00Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

Phase 01 rebased native Android/iOS scaffolding onto Flutter 3.41.5 with Kotlin DSL Gradle files, bumped the iOS deployment target to 15.0, added release signing scaffolding, and updated SDK constraints. The native scaffolding is well-structured and follows Flutter 3.41.5 conventions (scene delegate pattern on iOS, Kotlin DSL on Android). One critical issue exists in the signing config (null pointer on missing property), along with several warnings around stale README instructions and a potential runtime crash in `context_extension.dart`.

## Critical Issues

### CR-01: Null pointer when `storeFile` key is missing from key.properties

**File:** `android/app/build.gradle.kts:50`
**Issue:** When `hasKeystoreFile` is true, `keystoreProperties["storeFile"]` returns `Any?`. The `file()` call on line 50 will throw `IllegalArgumentException` if the key is missing or empty in `key.properties`. The other three properties are safely cast with `as String?`, but `storeFile` is passed directly to `file()` which does not accept null. A user who copies the template and fills in only passwords (leaving `storeFile` as the default `keystore.jks` which may not exist) gets an opaque Gradle crash rather than a helpful error.
**Fix:**
```kotlin
if (hasKeystoreFile) {
    val storeFilePath = keystoreProperties["storeFile"] as String?
    require(!storeFilePath.isNullOrBlank()) {
        "storeFile must be set in key.properties. See key.properties.template."
    }
    storeFile = file(storeFilePath)
    storePassword = keystoreProperties["storePassword"] as String?
    keyAlias = keystoreProperties["keyAlias"] as String?
    keyPassword = keystoreProperties["keyPassword"] as String?
}
```

## Warnings

### WR-01: README references `android/app/build.gradle` -- file is now `.kts`

**File:** `README.md:9`
**Issue:** Line 9 says "Open the file `android/app/build.gradle`" but the file has been migrated to `android/app/build.gradle.kts` in this phase. Users following the README will not find the file. Line 16 also references `android/app/src/main/java/com/example/skeleton` but the actual path is `android/app/src/main/kotlin/com/example/skeleton`.
**Fix:** Update line 9 to reference `android/app/build.gradle.kts` and line 16 to reference `android/app/src/main/kotlin/com/example/skeleton`.

### WR-02: README references `AndroidManifest.xml` package attribute -- removed in AGP 8+

**File:** `README.md:20-26`
**Issue:** Lines 20-26 instruct the user to update the `package` attribute in `AndroidManifest.xml`. Since AGP 7.0+ the `package` attribute is deprecated and since AGP 8.0 it should be removed from the manifest entirely -- the namespace is now declared only in `build.gradle.kts` (which this phase already does correctly on line 22). Following these stale instructions would confuse users or cause build warnings.
**Fix:** Remove the `AndroidManifest.xml` package attribute section from the README. Instead, instruct users to update only `namespace` and `applicationId` in `android/app/build.gradle.kts`.

### WR-03: Force-unwrap on `AppLocalizations.of(this)` may crash at runtime

**File:** `lib/core/extensions/context_extension.dart:5`
**Issue:** `AppLocalizations.of(this)!` will throw a null assertion error if the widget is accessed before localization delegates are initialized (e.g., in a context above `MaterialApp.router`). While this is a common Flutter pattern, in a skeleton template that others will clone, it is a frequent source of confusing crashes for new developers.
**Fix:** Add a descriptive assertion message:
```dart
AppLocalizations get localizations {
  final l10n = AppLocalizations.of(this);
  assert(l10n != null, 'No AppLocalizations found. Ensure this context is below MaterialApp.router.');
  return l10n!;
}
```

### WR-04: `use_modular_headers!` removed from Podfile without replacement

**File:** `ios/Podfile:30`
**Issue:** The previous Podfile (per CLAUDE.md conventions) had both `use_frameworks!` and `use_modular_headers!`. The new Podfile only has `use_frameworks!`. While Flutter 3.41.5's template does not include `use_modular_headers!`, some Firebase iOS SDK pods (especially older transitive deps) may fail to build without it. This is not a guaranteed failure, but it is a known compatibility edge case with Firebase iOS SDK 12.x.
**Fix:** If Firebase pod builds fail with header-not-found errors, add `use_modular_headers!` back inside the `target 'Runner'` block. Consider adding a comment noting this for future reference.

### WR-05: `intl` version bumped to `^0.20.2` but may conflict with `flutter_localizations`

**File:** `pubspec.yaml:29`
**Issue:** The `intl` package version was bumped from `^0.19.0` to `^0.20.2`. The `flutter_localizations` SDK package pins its own `intl` version transitively. If the Flutter SDK's bundled `intl` is older than 0.20.2, `pub get` will fail with a version conflict. This depends on the exact Flutter 3.41.5 SDK resolution, but since the SDK constraint is `^3.9.0`, earlier Flutter versions in that range may ship an incompatible `intl`.
**Fix:** Verify that `flutter pub get` resolves cleanly with Flutter 3.41.5. If it does, this is fine. If not, relax the constraint to `intl: any` (letting the SDK drive the version) or pin it to match the SDK's bundled version.

## Info

### IN-01: Hardcoded app title in `lib/app.dart`

**File:** `lib/app.dart:15`
**Issue:** `title: 'Skeleton APP'` is hardcoded rather than using a localized string. This is an internal-only string (used in Android's recent apps switcher) so it is low severity, but it should be updated per-project during bootstrap.
**Fix:** Consider using a localized string or adding a comment reminding the bootstrapper to rename it.

### IN-02: `key.properties.template` has `storeFile=keystore.jks` as default value

**File:** `android/key.properties.template:8`
**Issue:** The template pre-fills `storeFile=keystore.jks` which is a relative path. If the user runs `keytool` from a different directory, the path will be wrong. The other fields are correctly left empty, but `storeFile` having a default value might mislead users into thinking they do not need to update it.
**Fix:** Either leave `storeFile=` empty like the other fields, or add a comment clarifying the path is relative to `android/` directory.

### IN-03: `Jetifier` property removed from `gradle.properties`

**File:** `android/gradle.properties:2`
**Issue:** The previous `gradle.properties` had `android.enableJetifier=true`. The new version correctly removes it (Jetifier is no longer needed with AGP 8+). This is a positive change and noted here for traceability only.
**Fix:** No action required.

---

_Reviewed: 2026-04-16T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
