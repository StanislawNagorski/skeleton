# External Integrations

**Analysis Date:** 2026-04-16

## APIs & External Services

**Firebase Platform (Google):**
- All Firebase plugins are declared in `pubspec.yaml` and have native pods locked in `ios/Podfile.lock` (Firebase iOS SDK `11.6.0`)
- Initialization is currently STUBBED OUT in `lib/startup_service.dart` — `_configureFirebase()` body is commented behind `TODO` markers; `Firebase.initializeApp(...)` is never invoked in the running app
- Firebase configuration files are NOT shipped in this skeleton:
  - `lib/firebase_options.dart` — missing
  - `ios/Runner/GoogleService-Info.plist` — missing
  - `android/app/google-services.json` — missing
  - `README.md` instructs each consuming project to wire Firebase via the FlutterFire CLI

**Firebase services declared:**
- `firebase_core` `^3.10.0` - Base initialization (`lib/startup_service.dart`)
- `firebase_crashlytics` `^4.3.0` - Crash & error reporting; helper `_configureCrashlytics()` in `lib/startup_service.dart` registers `FlutterError.onError` and `PlatformDispatcher.instance.onError` (currently unreachable; commented out)
- `firebase_analytics` `^11.4.0` - Event analytics; declared but no analytics calls present in `lib/`
- `firebase_performance` `^0.10.1` - Performance monitoring; declared but no traces present in `lib/`
- `firebase_app_check` `^0.3.2` - App attestation; helper `_configureAppCheck()` in `lib/startup_service.dart` activates Play Integrity (`AndroidProvider.playIntegrity`/`debug`) and DeviceCheck (`AppleProvider.deviceCheck`/`debug`); currently commented out

**Generic HTTP:**
- `http` `^1.2.2` declared in `pubspec.yaml` for arbitrary REST calls; no `http.Client`, `get(`, or `post(` usages found in `lib/`

## Data Storage

**Databases:**

- **ObjectBox** (local NoSQL) - `objectbox` `^4.0.3` + `objectbox_flutter_libs` `any` + `objectbox_generator` `any`
  - Bootstrap: `lib/core/local_database/object_box.dart` (`ObjectBox.initObjectBox()` opens the store using `path_provider.getApplicationDocumentsDirectory()`)
  - Generated bindings: `lib/core/local_database/objectbox.g.dart`
  - Schema metadata (commit to VCS): `lib/core/local_database/objectbox-model.json` — currently contains one entity `CounterModel`
  - Output dir override in `pubspec.yaml`: `objectbox: output_dir: core/local_database`
  - Entity definition: `lib/features/home_page/data/model/counter_model.dart` (annotated with `@Entity()` / `@Id()`)
  - Reactive queries used via `query().watch(triggerImmediately: true)` in `lib/features/home_page/data/local_database/counter_local_database.dart`
  - Native libs declared for iOS, Android, macOS, Linux, Windows in `.flutter-plugins-dependencies`
  - Initialized in `StartUpService._configureDatabases()` → `ObjectBox.initObjectBox()` (`lib/startup_service.dart:18`)

- **Cloud Firestore** (remote NoSQL) - `cloud_firestore` `^5.6.1`
  - Declared in `pubspec.yaml`; pod locked at `FirebaseFirestore 11.6.0` (`ios/Podfile.lock`)
  - NOT yet imported anywhere under `lib/` (no `cloud_firestore.dart` import found)
  - Web platform support included via `cloud_firestore_web` `4.4.1`
  - Effectively dormant until Firebase initialization is enabled

**File Storage:**
- Local filesystem only via `path_provider` `^2.1.5`; consumed by `lib/core/local_database/object_box.dart` to locate the application documents directory for the ObjectBox store

**Caching:**
- None. No `shared_preferences`, `hive`, `flutter_secure_storage`, or in-memory cache packages declared.

## Authentication & Identity

**Auth Provider:**
- None. No `firebase_auth`, OAuth, or custom auth client is declared in `pubspec.yaml`
- `firebase_app_check` provides app attestation (proving the request comes from a genuine app instance) but is NOT user authentication
- No login screens, sessions, or token storage implementations present

## Monitoring & Observability

**Error Tracking:**
- `firebase_crashlytics` `^4.3.0` declared; wiring stubbed in `lib/startup_service.dart` `_configureCrashlytics()` (commented out). Once enabled, it routes `FlutterError.onError` → `recordFlutterFatalError` and `PlatformDispatcher.instance.onError` → `recordError(..., fatal: true)`
- No Sentry, Bugsnag, or alternate crash reporter

**Logs:**
- `logger` `^2.5.0` is the in-app logging library
- Pretty-printed instances configured per call site:
  - `lib/core/router/router.dart` — `Logger(printer: PrettyPrinter(methodCount: 0, noBoxingByDefault: true))` traces every navigation event via `AppRouterObserver`
  - `lib/features/home_page/data/repository/counter_repository.dart` — `Logger()` writes `e('Local data source exception: $e')` for failed reads/writes
- No remote log shipping (`firebase_analytics`/`crashlytics` not currently wired)

**Performance:**
- `firebase_performance` `^0.10.1` declared but no traces or HTTP metrics implemented in `lib/`

## CI/CD & Deployment

**Hosting:**
- Mobile app — distributed through App Store / Google Play (no in-repo deployment configuration)
- No web hosting, container, or backend deployment artifacts present

**CI Pipeline:**
- None detected. No `.github/workflows/`, `bitrise.yml`, `codemagic.yaml`, `fastlane/`, `.circleci/`, or `.gitlab-ci.yml`.

**Code Signing:**
- iOS: signing handled in Xcode project (no Fastlane match config)
- Android: `android/app/build.gradle` uses debug signing for release builds (TODO comment present at `buildTypes.release`)

## Environment Configuration

**Required env vars:**
- None. No `.env`, `String.fromEnvironment`, or `--dart-define` consumers found in `lib/`

**Secrets location:**
- No secrets stored in repo (no `.env*`, no key files, no `google-services.json`, no `GoogleService-Info.plist`)
- `.gitignore` does not list `.env` patterns; consuming projects should add them when introducing secrets
- `.fvm/` is ignored to keep the cached Flutter SDK out of version control
- Build artifacts under `/build/`, `.dart_tool/`, `.flutter-plugins`, `.flutter-plugins-dependencies` are git-ignored

## Webhooks & Callbacks

**Incoming:**
- None. No deep links, universal links, or push handlers configured. `ios/Runner/Info.plist` declares no `CFBundleURLTypes`; `android/app/src/main/AndroidManifest.xml` declares only the launcher `MAIN`/`LAUNCHER` intent.

**Outgoing:**
- None. No background workers, schedulers, or outbound webhook clients.

## Native Plugins (Resolved Across Platforms)

Source: `.flutter-plugins-dependencies`

| Plugin | iOS | Android | macOS | Linux | Windows | Web |
|--------|-----|---------|-------|-------|---------|-----|
| `cloud_firestore` `5.6.1` | yes | yes | yes | — | yes | yes (`cloud_firestore_web` `4.4.1`) |
| `firebase_analytics` `11.4.0` | yes | yes | yes | — | — | yes (`firebase_analytics_web` `0.5.10+6`) |
| `firebase_app_check` `0.3.2` | yes | yes | yes | — | — | yes (`firebase_app_check_web` `0.2.0+4`) |
| `firebase_core` `3.10.0` | yes | yes | yes | — | yes | yes (`firebase_core_web` `2.19.0`) |
| `firebase_crashlytics` `4.3.0` | yes | yes | yes | — | — | — |
| `firebase_performance` `0.10.1` | yes | yes | — | — | — | yes (`firebase_performance_web` `0.1.7+6`) |
| `flutter_native_splash` `2.4.4` | yes | yes | — | — | — | yes |
| `objectbox_flutter_libs` `4.0.3` | yes | yes | yes | yes | yes | — |
| `path_provider` `2.1.5` | yes (`path_provider_foundation` `2.4.1`) | yes (`path_provider_android` `2.2.15`) | yes | yes (`path_provider_linux` `2.2.1`) | yes (`path_provider_windows` `2.3.0`) | — |

## Third-Party SDKs (iOS native, via CocoaPods)

Pinned in `ios/Podfile.lock`:
- Firebase iOS SDK `11.6.0` umbrella — `Firebase/Analytics`, `Firebase/Crashlytics`, `Firebase/Firestore`, `Firebase/Performance`, `FirebaseAppCheck`, `FirebaseCore`, `FirebaseInstallations`, `FirebaseRemoteConfig`, `FirebaseSessions`
- `AppCheckCore` `11.2.0` — App Check primitives
- `GoogleAppMeasurement` `11.6.0` — Analytics SDK transitive
- `GoogleDataTransport` `10.1.0` — Telemetry transport
- `GoogleUtilities` `8.0.2` — Shared Google utilities
- `BoringSSL-GRPC` `0.0.36`, `abseil` `1.20240116.2` — gRPC/Firestore transitive
- `flat_buffers` `23.5.26` (transitive Dart package) — used by ObjectBox bindings

## RIVE Animations

- Not present. No `rive` package declared in `pubspec.yaml` and no `.riv` assets referenced. Asset folder `assets/images/`, `assets/sounds/`, `assets/images/webp/` are declared in `pubspec.yaml` but the `assets/` directory does not yet exist on disk.

---

*Integration audit: 2026-04-16*
