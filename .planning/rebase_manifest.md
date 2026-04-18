# Rebase Manifest: Phase 1 -- Native Rebase

**Date:** 2026-04-16
**Flutter SDK:** 3.41.5 (via FVM)
**Branch:** 2026-update

## Actions Taken

### FVM + SDK
- [x] `.fvmrc` bumped from `3.29.0` to `3.41.5` (D-05)
- [x] `fvm install 3.41.5 && fvm use 3.41.5` run before scaffold generation (D-05)

### Native Directory Swap
- [x] `android/` replaced with fresh `flutter create --platforms=android,ios` output (D-02)
- [x] `ios/` replaced with fresh `flutter create --platforms=android,ios` output (D-03)
- [x] Stale Kotlin folder under `android/app/src/main/kotlin/` verified -- only one `MainActivity.kt` exists (D-02)
- [x] `ios/Pods/` and `ios/Podfile.lock` deleted before swap, regenerated via `pod install` (D-03)

### Platform Trimming
- [x] `web/`, `macos/`, `linux/`, `windows/` directories deleted (INFRA-02)
- [x] `flutter clean` run after deletion to clear cached references

### Pubspec Environment
- [x] `environment: sdk:` updated from `^3.6.0` to `^3.9.0` (D-04)
- [x] `intl` constraint bumped from `^0.19.0` to `^0.20.2` (required by SDK-pinned flutter_localizations)
- [x] All other dependencies, dev_dependencies, flutter block, objectbox block left untouched (D-04)
- [x] Asset directory declarations left untouched -- out of scope for Phase 1 (D-06)

### iOS Podfile
- [x] `platform :ios` floor set to `'15.0'` (PROJECT.md constraint -- Firebase iOS SDK 12.x requires 15)
- [x] iOS deployment target set to `15.0` in `project.pbxproj` via `IPHONEOS_DEPLOYMENT_TARGET` (no MinimumOSVersion in AppFrameworkInfo.plist in 3.41.5)

### L10n Import Migration
- [x] Flutter 3.41.5 generates l10n files in-place (`lib/core/localization/`) instead of `flutter_gen/gen_l10n/` synthetic package
- [x] Imports updated in `lib/app.dart` and `lib/core/extensions/context_extension.dart`
- [x] `l10n.yaml` updated with `synthetic-package: false` for in-place generation

### Release Signing
- [x] `android/app/build.gradle.kts` signing reads `key.properties` first, falls back to env vars (D-07)
- [x] When neither source present: no `signingConfigs.release` defined, Gradle warning logged, release build fails (D-08)
- [x] `android/key.properties.template` shipped with placeholder fields and keytool one-liner (D-09)
- [x] `.gitignore` excludes `android/key.properties` and `android/app/*.jks` (D-09)
- [x] README `Release Signing` section added with keytool + template + CI env var docs (D-09)

### Pre-Rebase Safety
- [x] Pre-rebase state committed on `2026-update` branch -- recovery via `git reset` (D-01)

## Explicit Non-Edits (Fresh Template Accepted)

- [x] `android/gradle.properties` -- accepted fresh `flutter create` defaults; did NOT re-apply `org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G` (D-10)
- [x] `ios/Runner/Info.plist` -- did NOT re-apply `CADisableMinimumFrameDurationOnPhone = true` / 120Hz unlock (D-11). Note: fresh 3.41.5 template includes this key by default.
- [x] `ios/Runner/Info.plist` -- did NOT preserve `CFBundleDisplayName = "Skeleton"` literal; accepted flutter create default (D-12)
- [x] This manifest itself is the Phase 1 deliverable documenting all decisions (D-13)

## Deferred Items

- Asset directory `.gitkeep` placeholders -> Phase 4 or Phase 6
- Re-adding JVM args -> only if Phase 5/6 hits build-memory pressure
- Re-adding 120Hz unlock -> Phase 6 if RIVE animations stutter
- Per-flavor signing configs -> Phase 4

## Version Matrix (Actual)

| Component | Old Version | New Version (from flutter create 3.41.5) |
|-----------|-------------|-------------------------------------------|
| Flutter SDK | 3.29.0 | 3.41.5 |
| Dart SDK constraint | ^3.6.0 | ^3.9.0 (actual SDK: 3.11.3) |
| AGP | 8.1.0 | 8.11.1 |
| Kotlin | 1.8.22 | 2.2.20 |
| Gradle | 8.1.0 | 8.14 |
| Gradle build scripts | Groovy (.gradle) | Kotlin DSL (.gradle.kts) |
| Java target | 1.8 | 17 |
| iOS Podfile floor | 13.0 | 15.0 |
| iOS deployment target | 12.0 / 13.0 | 15.0 |
