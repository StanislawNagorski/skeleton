# Technology Stack

**Analysis Date:** 2026-04-16

## Languages

**Primary:**
- Dart `^3.6.0` - Flutter application code (`lib/`)

**Secondary:**
- Swift - iOS host application (`ios/Runner/AppDelegate.swift`)
- Kotlin `1.8.22` - Android host application (`android/app/src/main/kotlin/`, plugin declared in `android/settings.gradle`)
- Objective-C - Generated Flutter plugin registrant (`ios/Runner/GeneratedPluginRegistrant.m`)
- Ruby - iOS CocoaPods configuration (`ios/Podfile`)
- Groovy - Android Gradle build scripts (`android/build.gradle`, `android/app/build.gradle`)

## Runtime

**Environment:**
- Flutter SDK `3.29.0` (pinned via FVM in `.fvmrc`)
- Dart SDK constraint `^3.6.0` (declared in `pubspec.yaml`)
- Resolved Flutter floor `>=3.24.0` (declared in `pubspec.lock` `sdks` section)
- `.flutter-plugins-dependencies` was generated against Flutter `3.27.1` — there is a drift between `.fvmrc` (3.29.0) and the last `flutter pub get` run

**Package Manager:**
- pub (Dart/Flutter native)
- Lockfile: `pubspec.lock` (present, committed)
- iOS: CocoaPods — `ios/Podfile`, `ios/Podfile.lock` (committed, ~1500 lines, locked to Firebase iOS SDK `11.6.0`)
- Android: Gradle `8.1.0` Android plugin via `dev.flutter.flutter-gradle-plugin` (`android/settings.gradle`)
- Flutter Version Manager (FVM): `.fvmrc` pins `3.29.0`; `.fvm/` directory is git-ignored

## Frameworks

**Core:**
- Flutter `3.29.0` - UI framework, multi-platform (iOS, Android, web, macOS, Linux, Windows enabled)
- `flutter_localizations` (SDK) - Built-in i18n delegates

**Testing:**
- `flutter_test` (SDK) - The only test framework declared (`pubspec.yaml`); no test files exist under `test/`

**Build/Dev:**
- `build_runner` `^2.4.14` - Code generation orchestrator (`pubspec.yaml`)
- `auto_route_generator` `^9.0.0` - Generates router boilerplate (`lib/core/router/router.gr.dart`)
- `injectable_generator` `^2.6.2` - Generates DI registrations (`lib/core/injectable/injection.config.dart`)
- `objectbox_generator` `any` - Generates ObjectBox bindings (`lib/core/local_database/objectbox.g.dart`, `objectbox-model.json`)
- `flutter_lints` `^5.0.0` - Lint rules referenced by `analysis_options.yaml`

## Key Dependencies

**Critical:**
- `flutter_bloc` `^8.1.6` - State management (`bloc` `8.1.4` transitive); used in `lib/features/home_page/presentation/cubit/home_cubit.dart`
- `auto_route` `^9.3.0+1` - Declarative routing wired in `lib/core/router/router.dart`; pages annotated with `@RoutePage()`
- `injectable` `^2.5.0` + `get_it` `8.0.3` - Service locator pattern; configured in `lib/core/injectable/injection.dart`
- `objectbox` `^4.0.3` + `objectbox_flutter_libs` `any` - Local NoSQL persistence; bootstrap in `lib/core/local_database/object_box.dart`, output dir overridden to `core/local_database` in `pubspec.yaml`
- `dartz` `0.10.1` - Functional `Either<Failure, T>` pattern used by repositories and services (`lib/features/home_page/data/repository/counter_repository.dart`)
- `cloud_firestore` `^5.6.1` - Remote NoSQL data store (declared dependency, not yet imported in `lib/`)

**Infrastructure:**
- `firebase_core` `^3.10.0` - Firebase initialization base (resolves to native SDK `11.6.0` on iOS)
- `firebase_crashlytics` `^4.3.0` - Crash reporting (wiring stubbed in `lib/startup_service.dart`)
- `firebase_analytics` `^11.4.0` - Analytics (declared, not yet imported in `lib/`)
- `firebase_performance` `^0.10.1` - Performance traces (declared, not yet imported in `lib/`)
- `firebase_app_check` `^0.3.2` - App attestation; wiring stubbed for Play Integrity (Android) and DeviceCheck (Apple) in `lib/startup_service.dart`
- `logger` `^2.5.0` - Structured logging used in `lib/core/router/router.dart` and repositories
- `path_provider` `^2.1.5` - Filesystem paths for ObjectBox store (`lib/core/local_database/object_box.dart`)
- `http` `^1.2.2` - HTTP client (declared, no usage found in `lib/`)
- `uuid` `^4.5.1` - UUID generation (declared, no usage found in `lib/`)
- `collection` `^1.19.0` - Dart collection helpers (declared, no usage found in `lib/`)
- `intl` `^0.19.0` - Drives ARB-generated localizations
- `cupertino_icons` `^1.0.8` - iOS icon glyphs
- `flutter_native_splash` `^2.3.9` (resolved `2.4.4`) - Native splash screen generator

## Configuration

**Environment:**
- No `.env` file present; no environment-variable-based configuration in `lib/`
- Firebase initialization is stubbed out in `lib/startup_service.dart` (`_configureFirebase` body commented). Native Firebase config files are absent: no `ios/Runner/GoogleService-Info.plist`, no `android/app/google-services.json`, no `lib/firebase_options.dart`. The README instructs the consumer to wire Firebase via FlutterFire CLI.
- Localization sources: `lib/core/localization/app_pl.arb` (template) and `lib/core/localization/app_en.arb`; output declared in `l10n.yaml` to `app_localizations.dart` consumed via `package:flutter_gen/gen_l10n/app_localizations.dart`

**Build:**
- `analysis_options.yaml` - Inherits `package:flutter_lints/flutter.yaml`; no custom rules enabled
- `l10n.yaml` - `arb-dir: lib/core/localization`, `template-arb-file: app_pl.arb`, `output-localization-file: app_localizations.dart`
- `pubspec.yaml` `flutter:` block - `uses-material-design: true`, `generate: true` (l10n), assets `assets/images/`, `assets/sounds/`, `assets/images/webp/` (asset folders are declared but the `assets/` directory does not exist on disk yet)
- `pubspec.yaml` `objectbox:` block - `output_dir: core/local_database`
- `android/gradle.properties` - `org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G`, AndroidX + Jetifier enabled
- `android/app/build.gradle` - `namespace = "com.example.skeleton"`, `applicationId = "com.example.skeleton"`, Java/Kotlin target `1.8`, debug signing reused for release builds (TODO marker in file)
- `ios/Podfile` - `platform :ios, '13.0'`, `use_frameworks!`, `use_modular_headers!`
- `ios/Runner/Info.plist` - `CFBundleDisplayName = Skeleton`, all orientations supported, `CADisableMinimumFrameDurationOnPhone = true`
- `.metadata` - Tracks Flutter project revision `17025dd88227cd9532c33fa78f5250d548d87e9a` on `stable` channel

## Platform Requirements

**Development:**
- Flutter SDK `3.29.0` via FVM (`.fvmrc`)
- Xcode with CocoaPods for iOS builds (Podfile uses `flutter_install_all_ios_pods`)
- Android Studio / Android SDK with Gradle `8.1.0` and Kotlin `1.8.22`
- Run `flutter pub get` then `dart run build_runner build --delete-conflicting-outputs` to regenerate `injection.config.dart`, `router.gr.dart`, and `objectbox.g.dart`

**Production:**
- iOS deployment target: 13.0 (`ios/Podfile`)
- Android: `compileSdk` and `minSdk` inherited from Flutter Gradle plugin defaults; AndroidX/Jetifier enabled
- Multi-platform scaffolding present for `web/`, `macos/`, `linux/`, `windows/` (Flutter create defaults; ObjectBox + Firebase plugins claim native builds across all of them per `.flutter-plugins-dependencies`)
- Bundle/application id placeholder: `com.example.skeleton` (must be replaced per project per README)

---

*Stack analysis: 2026-04-16*
