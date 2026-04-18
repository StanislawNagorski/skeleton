# Skeleton - Flutter App Template

A reusable Flutter starter for iOS + Android with Clean Architecture, sealed `Result<T>` error handling, Drift local database, Firebase Auth (Email / Google / Apple), RIVE animations, onboarding flow, and coach marks. Core value: `git clone -> bootstrap -> flutter run` in under 30 minutes, with a production-grade architecture already in place.

## Quickstart

### Prerequisites

- Flutter 3.41.5 via [FVM](https://fvm.app/) (pinned in `.fvmrc`)
- Dart SDK ^3.9.0
- Xcode (for iOS) / Android Studio (for Android)
- CocoaPods (for iOS)

### 1. Clone & Bootstrap

```bash
git clone <repo-url> my_app
cd my_app
dart run tool/bootstrap.dart --name MyApp --bundle com.example.myapp
```

The bootstrap script performs a single-pass rename across the entire project:

| Step | What it does |
|------|-------------|
| 1/9 | Renames all `package:skeleton/` imports in `lib/` to your Dart package name |
| 2/9 | Updates Android `build.gradle.kts` namespace + applicationId |
| 3/9 | Updates Android `AndroidManifest.xml` label |
| 4/9 | Moves the Android Kotlin directory to match new bundle ID |
| 5/9 | Updates iOS `project.pbxproj` bundle identifier |
| 6/9 | Updates iOS `Info.plist` display name + bundle name |
| 7/9 | Updates `pubspec.yaml` name + description |
| 8/9 | Updates README.md title |
| 9/9 | Updates Drift database file name |

### 2. Post-Bootstrap Steps

After bootstrap completes, follow the printed checklist:

1. `fvm flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. Create a Firebase project at https://console.firebase.google.com
4. Register Android app with package name: `com.example.myapp`
5. Register iOS app with bundle ID: `com.example.myapp`
6. Download `google-services.json` -> `android/app/`
7. Download `GoogleService-Info.plist` -> `ios/Runner/`
8. `flutterfire configure --project=<your-firebase-project-id>`
9. Register SHA-1 fingerprints:
   - Debug: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`
   - Release: `keytool -list -v -keystore <your-release-keystore> -alias <your-alias>`
10. Enable "Sign in with Apple" capability in Xcode
11. Configure Apple Services ID at https://developer.apple.com
12. `fvm flutter run`

### 3. Run Without Firebase

Firebase is optional. The skeleton works immediately after bootstrap with `FakeAuthService` in dev mode -- no Firebase project required. Just run:

```bash
fvm flutter pub get
fvm flutter run
```

When `firebase_options.dart` is the stub (no `flutterfire configure` has been run), the app automatically falls back to the `'dev'` DI environment:

- Registers `FakeAuthService` (in-memory, any email/password works)
- Does not register Firebase Analytics, Performance, or Firestore
- Does not activate Crashlytics or App Check

This preserves the `clone -> bootstrap -> flutter run` DX promise.

## Architecture

### Clean Architecture Layers

Each feature lives under `lib/features/<feature>/` with three subdirectories. Shared infrastructure lives under `lib/core/`.

```
lib/
  core/              # Shared infrastructure (auth, database, DI, errors, router, ...)
  features/
    home_page/
      data/           # Data sources, models, repositories
      domain/         # Services, entities
      presentation/   # Pages, cubits, widgets
    onboarding/
    login/
    rive_demo/
```

- **Data** -- owns all data acquisition: local DB queries, remote API calls, translating raw exceptions into typed `AppFailure` values. Repositories return `Result<T>`.
- **Domain** -- business logic independent of UI. Orchestrates repositories, applies rules, composes data.
- **Presentation** -- renders UI, handles user input, manages page-scoped state via Cubits.

Each layer defines an `abstract class` interface; concrete implementations are registered with `@Injectable(as: AbstractType)`. Dependencies point inward only.

### State Management

`flutter_bloc` 9 with `Cubit<State>`. State is an immutable class with a `factory .initial()` constructor and a `copyWith` method. Status surfaces via a `<Feature>PageStatus` enum (`loading`, `success`, `error`, `empty`).

```dart
// Cubit consumes Result<T> via exhaustive switch:
switch (result) {
  case Success(:final value):
    emit(state.copyWith(status: PageStatus.success, data: value));
  case Failure(:final failure):
    emit(state.copyWith(status: PageStatus.error, message: failure.message));
}
```

### Error Handling (sealed Result<T> / AppFailure)

Dart 3 sealed `Result<T>` provides type-safe error handling with exhaustive pattern matching:

```dart
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure);
  final AppFailure failure;
}
```

`AppFailure` is a sealed hierarchy with typed variants:

```dart
sealed class AppFailure {
  const AppFailure(this.message);
  final String message;
}

final class LocalDataNotFound extends AppFailure { ... }
final class LocalDataSource extends AppFailure { ... }
final class AuthError extends AppFailure { ... }
```

Repositories catch exceptions and return `Result<T>`. Cubits consume via exhaustive `switch` -- no `fold()`, pattern matching only.

### Routing (auto_route 11)

`RootStackRouter` with the `guards` property on the router class:

- **OnboardingGuard** -- global (runs on every route), redirects first-launch users to `/onboarding`
- **AuthGuard** -- per-route on `LoginRoute` only, redirects unauthenticated users

Guard re-evaluation is reactive via `reevaluateListenable`:

```dart
routerConfig: appRouter.config(
  reevaluateListenable: Listenable.merge([
    ReevaluateListenable.stream(authService.authStateChanges),
    MyApp.onboardingNotifier,
  ]),
),
```

### Dependency Injection (get_it + injectable)

`@Injectable(as: AbstractType)` pattern with DI environment switching:

- `'prod'` environment: registers `FirebaseAuthService` (real Firebase Auth)
- `'dev'` environment: registers `FakeAuthService` (in-memory, no Firebase needed)

```dart
// Called during startup after Firebase availability is determined:
await configureDependenciesApp(environment: environment);
```

After adding new `@Injectable` classes, regenerate DI config:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### AuthService Contract

The central authentication boundary. Implementations:
- `FakeAuthService` -- in-memory, ships with the skeleton (dev mode)
- `FirebaseAuthService` -- real Firebase Auth (prod mode)

```dart
abstract class AuthService {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;

  Future<AuthResult> signInWithEmail({required String email, required String password});
  Future<AuthResult> signUpWithEmail({required String email, required String password});
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> signInWithApple();
  Future<void> signOut();
  Future<AuthResult> sendPasswordReset({required String email});
}
```

Returns sealed `AuthResult` with three states:

```dart
sealed class AuthResult {}
final class AuthSuccess extends AuthResult { final AuthUser user; }
final class AuthFailure extends AuthResult { final AppFailure failure; }
final class AuthCancelled extends AuthResult {}
```

> **Note:** `AuthUser` is a pure Dart entity with zero Firebase imports. Downstream apps implementing custom backends create their own `AuthService` implementation.

## Firebase Integration

### Firebase-Sterile Stance

The skeleton ships without Firebase config files. No `google-services.json`, no `GoogleService-Info.plist`, no real `firebase_options.dart`. A stub `firebase_options.dart` throws `UnsupportedError` at runtime, triggering the dev-mode fallback automatically.

Each app configures its own Firebase project post-bootstrap via `flutterfire configure`.

### FlutterFire Setup

#### Prerequisites

- A Firebase project created in [Firebase Console](https://console.firebase.google.com/)
- FlutterFire CLI installed:
  ```bash
  dart pub global activate flutterfire_cli
  ```

#### 1. Generate Firebase Options

```bash
flutterfire configure --project=YOUR_PROJECT_ID
```

This replaces the stub `lib/firebase_options.dart` with real configuration.
After this step, `flutter run` initializes Firebase and registers
`FirebaseAuthService` instead of `FakeAuthService`.

#### 2. Google Sign-In Setup

**Android**

1. Register SHA-1 fingerprints in **Firebase Console > Project Settings > Your Apps > Android app > Add Fingerprint**.
2. Get your debug SHA-1:
   ```bash
   ./gradlew signingReport
   ```
   Look for the `SHA1` line under the `debugAndroidTest` variant.
3. Get your release SHA-1:
   ```bash
   keytool -list -v -keystore <your-release-keystore> -alias <alias>
   ```
4. The `serverClientId` (Web OAuth client ID) is auto-detected from `google-services.json` at runtime -- no manual configuration needed after `flutterfire configure`.
   If you need to find it manually: **Google Cloud Console > APIs & Services > Credentials > Web client (auto created by Firebase)**.

**iOS**

Add the reversed client ID URL scheme to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

Find the `REVERSED_CLIENT_ID` value in the generated `ios/Runner/GoogleService-Info.plist`.

#### 3. Apple Sign-In Setup

Apple Sign-In is iOS only. The Xcode entitlement is not pre-enabled --
you must add it after renaming the bundle ID.

1. Open the project in Xcode.
2. Select **Runner** target > **Signing & Capabilities**.
3. Click **+ Capability** > **Sign in with Apple**.
4. In **Apple Developer Portal > Certificates, Identifiers & Profiles > Identifiers**:
   - Select your App ID and enable **Sign in with Apple**.
   - If you need web or Android redirect flow: create a **Services ID**, configure
     domains and return URLs.

> **Note:** Apple returns the user's email and name only on the first sign-in.
> Store them on your backend immediately -- subsequent sign-ins omit this data.

#### 4. App Check (Release Builds Only)

App Check is activated automatically in release builds (`kReleaseMode`):

| Platform | Provider |
|----------|----------|
| Android  | Play Integrity (requires Play Console enrollment) |
| iOS      | App Attest (requires iOS 14+; skeleton floor is iOS 15) |

No debug-token configuration needed -- dev builds skip App Check entirely.

#### 5. Crashlytics

Crashlytics is wired automatically when Firebase is initialized:

- `FlutterError.onError` catches Flutter framework errors
- `PlatformDispatcher.instance.onError` catches async Dart errors
- `Isolate.current.addErrorListener` catches spawned isolate errors

Collection is disabled in debug builds -- only release crashes are reported.

#### Dev Mode (No Firebase)

If `firebase_options.dart` is the stub (no `flutterfire configure` run), the app:

- Falls back to the `'dev'` DI environment
- Registers `FakeAuthService` (in-memory, any email/password works)
- Does not register Firebase Analytics, Performance, or Firestore
- Does not activate Crashlytics or App Check

This preserves the `clone -> flutter run` DX promise.

## UX Patterns

### Onboarding

3-slide `PageView` with dots indicator + skip/next buttons. Gated by `OnboardingGuard` -- first launch shows onboarding, subsequent launches skip. The `hasSeenOnboarding` flag is persisted via `PreferencesService` and pre-read at startup to avoid async I/O in the guard (prevents white flash on cold start).

Placeholder content -- replace slides per-app.

### RIVE Animations

RIVE 0.14 initialized via `RiveNative.init()` in `StartUpService` before any widget loads. A dedicated demo page at `/rive-demo` shows `RiveWidgetBuilder` with state-machine interaction.

Ship your own `.riv` assets in `assets/rive/`.

### Coach Marks

`CoachMarkService` wraps `tutorial_coach_mark`. API:

- `register(GlobalKey, description)` -- register a target
- `showTour(tourId)` -- auto-triggers once per `tourId` (persisted via `PreferencesService`)

The counter page has a two-target demo tour. Replace targets per-app.

## Release Signing

The skeleton uses a `key.properties` file for local release signing and environment variables for CI.

### Local Setup

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore android/app/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Copy the template and fill in your values:
   ```bash
   cp android/key.properties.template android/key.properties
   ```

3. Edit `android/key.properties` with your keystore path, passwords, and alias.

4. Build a release APK:
   ```bash
   fvm flutter build apk --release
   ```

### CI Setup

Set these environment variables instead of using `key.properties`:

| Variable | Description |
|----------|-------------|
| `ANDROID_KEYSTORE_PATH` | Path to the `.jks` keystore file |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias (e.g., `upload`) |
| `ANDROID_KEY_PASSWORD` | Key password |

> **Note:** `key.properties` and `*.jks` files are gitignored. Never commit signing secrets.

## Code Generation

Run after adding new annotated classes, routes, or database tables:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This regenerates:

| File | Generator |
|------|-----------|
| `lib/core/router/router.gr.dart` | auto_route |
| `lib/core/injectable/injection.config.dart` | injectable |
| `lib/core/database/app_database.g.dart` | drift |

## Localization

EN is the template language (`l10n.yaml` sets `template-arb-file: app_en.arb`). PL translations are included.

- Key naming: `feature_element` (e.g., `homePage_title`, `homePage_incrementButton`)
- Add new keys to `app_en.arb` first, then translate in `app_pl.arb`
- `untranslated_messages.txt` tracks missing translations (gitignored)
- Access in widgets via `context.localizations.<key>` (from `context_extension.dart`)

ARB files live in `lib/core/localization/`.

## Testing

Reference tests at `test/features/home_page/`:

- `home_cubit_test.dart` -- `bloc_test` + `mocktail` pattern for cubit testing
- `counter_repository_test.dart` -- Drift `NativeDatabase.memory()` pattern for in-memory repository tests

Bootstrap E2E test at `test/tool/bootstrap_test.dart` -- verifies the rename script works end-to-end.

Run all tests:

```bash
fvm flutter test
```

## Version Matrix

| Component | Version |
|-----------|---------|
| Flutter SDK | 3.41.5 (pinned in `.fvmrc`) |
| Dart SDK | ^3.9.0 (pinned in `pubspec.yaml`) |
| AGP | 8.11.1 |
| Kotlin | 2.2.20 |
| Gradle | 8.14 |
| Java | 17 |
| iOS Podfile floor | 15.0 |
| flutter_bloc | ^9.1.1 |
| auto_route | ^11.1.0 |
| drift | ^2.32.1 |
| firebase_core | ^4.7.0 |
| firebase_auth | ^6.4.0 |
| rive | ^0.14.5 |

> Pinned in `.fvmrc` / `pubspec.yaml`. See [Rebase Runbook](docs/rebase-runbook.md) for the upgrade procedure.

## Upgrading

See [Upgrade Playbook](docs/upgrade-playbook.md) for FlutterFire BoM bumps, App Check verification, auto_route migration, and Drift schema migration.

## Rebasing on a New Flutter Version

See [Rebase Runbook](docs/rebase-runbook.md) for the full native rebase procedure.
