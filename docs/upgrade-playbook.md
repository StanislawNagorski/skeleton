# Upgrade Playbook

Checklists for common dependency upgrades. Each section is self-contained -- jump to the one you need.

Last updated: 2026-04-18

## 1. FlutterFire BoM Bump

When: A new FlutterFire BoM is released and you want to upgrade Firebase packages.

### Steps

1. Check the latest BoM at https://firebase.google.com/docs/flutter/setup
2. Update all Firebase package versions in `pubspec.yaml` as a group (they must stay on the same BoM):
   - `firebase_core`
   - `firebase_auth`
   - `cloud_firestore`
   - `firebase_crashlytics`
   - `firebase_analytics`
   - `firebase_performance`
   - `firebase_app_check`
3. Run `fvm flutter pub get` -- resolve any dependency conflicts
4. Run `fvm flutter analyze` -- fix any deprecation warnings introduced by the new versions
5. Run `fvm flutter test` -- all tests must pass

### Runtime Verification (REQUIRED -- compile-time checks are not sufficient)

6. Build and run on a real device or emulator with Firebase configured:
   ```bash
   fvm flutter run
   ```
7. Verify Firebase initialization completes -- check console output for "Firebase not configured" warning (should NOT appear if `firebase_options.dart` is properly generated via `flutterfire configure`)
8. Test auth flows: sign in with email, sign in with Google (Android), sign in with Apple (iOS), sign out -- verify `authStateChanges` emits correctly by checking the router guard redirects
9. Force a crash in release mode and verify it appears in Firebase Crashlytics Console within 5 minutes:
   ```bash
   fvm flutter build apk --release
   # Install on device, trigger crash, check console
   ```
10. Check Firebase Analytics Console for session events
11. Verify App Check attestation in release builds (see Section 2 below)

### What Can Go Wrong

- **Breaking API changes:** Firebase packages occasionally rename classes or methods. Check the CHANGELOG for each package at pub.dev before upgrading.
- **Native SDK version conflicts:** iOS `Podfile.lock` may pin an older Firebase iOS SDK. Run `cd ios && pod update && cd ..` to resolve.
- **App Check provider rename:** If `AppleAppAttestProvider` or other provider classes change, update `lib/startup_service.dart`. The current App Check activation is:
  ```dart
  await FirebaseAppCheck.instance.activate(
    providerApple: const AppleAppAttestProvider(),
  );
  ```
- **Crashlytics handler signature change:** If `recordFlutterFatalError` or `recordError` signatures change, update the three error handlers in `lib/startup_service.dart` (`_configureCrashlytics` method).
- **Isolate error listener:** The spawned-isolate error listener in `_configureCrashlytics` uses `RawReceivePort` -- verify this pattern is still valid in the new Dart SDK.

### Current Versions (BoM 4.12.0)

| Package | Version |
|---------|---------|
| `firebase_core` | ^4.7.0 |
| `firebase_auth` | ^6.4.0 |
| `cloud_firestore` | ^6.3.0 |
| `firebase_crashlytics` | ^5.2.0 |
| `firebase_analytics` | ^12.3.0 |
| `firebase_performance` | ^0.11.3 |
| `firebase_app_check` | ^0.4.3 |

## 2. App Check Verification

When: After any Firebase upgrade, or when switching App Check providers.

### Current Setup

App Check is activated only in release mode (`lib/startup_service.dart`):

```dart
static Future<void> _configureAppCheck() async {
  if (!kReleaseMode) return; // Skip entirely in dev.
  await FirebaseAppCheck.instance.activate(
    providerApple: const AppleAppAttestProvider(),
  );
}
```

Dev builds skip App Check entirely -- no debug-token registration friction.

### Steps

1. Verify App Check activation code in `lib/startup_service.dart`:
   - Wrapped in `if (!kReleaseMode) return` check
   - Apple uses `AppleAppAttestProvider` (not `DeviceCheckProvider`)
   - Android provider is not currently specified (uses Play Integrity by default)
2. Build a RELEASE build:
   ```bash
   fvm flutter build apk --release
   fvm flutter build ios --release --no-codesign
   ```
3. Install the release APK on a physical Android device
4. Open Firebase Console > App Check > Monitor
5. Verify attestation requests appear from the device within a few minutes

### Runtime Verification

6. On iOS: Install on a physical device (App Attest does not work on Simulator)
7. Make a Firestore read/write from the release build -- verify it succeeds (proving App Check token was accepted)
8. Temporarily enable App Check enforcement in Firebase Console for one collection and verify that debug builds are rejected (expected behavior -- confirms enforcement works)

### What Can Go Wrong

- **Provider enum renamed:** If `AppleAppAttestProvider` changes name in a new `firebase_app_check` version, the code will fail at compile time -- update the class name.
- **Play Integrity not enrolled:** Android App Check requires enrollment in Google Play Console > Release > App integrity. Without this, attestation fails silently and Firestore requests may be rejected when enforcement is enabled.
- **App Attest simulator limitation:** App Attest does not work on iOS Simulator -- always test on a physical device. Debug builds skip App Check entirely by design.
- **Missing Firebase project configuration:** App Check requires the app to be registered in Firebase Console with the correct bundle ID / package name. If `flutterfire configure` was not run, App Check activation will fail.

## 3. auto_route Guard Migration

When: Upgrading auto_route to a new major version.

### Current Setup (auto_route 11)

- `AppRouter` extends `RootStackRouter` directly (no `$AppRouter` codegen base class -- removed in v11)
- Guards declared via `guards` getter override on `AppRouter`:
  ```dart
  @override
  late final List<AutoRouteGuard> guards = [
    onboardingGuard,
  ];
  ```
- `AuthGuard` applied per-route on `LoginRoute` via the `guards` parameter in `AutoRoute()`:
  ```dart
  AutoRoute(
    page: LoginRoute.page,
    path: '/login',
    guards: [AuthGuard(_authService)],
  ),
  ```
- `reevaluateListenable` set on `RouterConfig` in `lib/app.dart` via `Listenable.merge`:
  ```dart
  routerConfig: widget.appRouter.config(
    reevaluateListenable: Listenable.merge([
      ReevaluateListenable.stream(widget.authService.authStateChanges),
      MyApp.onboardingNotifier,
    ]),
    navigatorObservers: () => [AppRouterObserver()],
  ),
  ```
- Route generation: `@RoutePage()` annotation + `build_runner` (generates `router.gr.dart`)
- `OnboardingGuard` uses a pre-cached `bool` flag -- no async I/O in `onNavigation`
- `AuthGuard` checks `_authService.currentUser != null`, redirects to `LoginRoute` if not authenticated

### Migration Steps

1. Read the auto_route CHANGELOG for the new major version at pub.dev
2. Check if `RootStackRouter` API changed -- look for:
   - `guards` getter signature change
   - `AutoRoute()` constructor parameter changes
   - `RoutePage` annotation changes
   - `AutoRouteGuard` interface changes (method signature of `onNavigation`)
3. Check if `reevaluateListenable` parameter still exists on `RouterConfig` (this is the mechanism that re-triggers guards when auth state changes)
4. Check if `ReevaluateListenable.stream()` factory still exists
5. Update `pubspec.yaml`: both `auto_route` and `auto_route_generator`
6. Run `fvm flutter pub get`
7. Run `dart run build_runner build --delete-conflicting-outputs` -- regenerate `router.gr.dart`
8. Fix any compile errors in:
   - `lib/core/router/router.dart` -- guard declarations, route list
   - `lib/core/router/guards/auth_guard.dart` -- `AutoRouteGuard` interface
   - `lib/core/router/guards/onboarding_guard.dart` -- `AutoRouteGuard` interface
   - `lib/app.dart` -- `reevaluateListenable` wiring, `Listenable.merge`
   - `lib/main.dart` -- `AppRouter` constructor
9. Run `fvm flutter analyze`
10. Run `fvm flutter test`

### Runtime Verification

11. Launch app on a fresh install -- verify `OnboardingGuard` redirects to onboarding on first run
12. Complete onboarding -- verify home page loads (guard passes after `markOnboardingSeen()`)
13. Navigate to login route -- verify `AuthGuard` is applied (redirects if not authenticated)
14. Sign in -- verify `reevaluateListenable` triggers guard re-evaluation and navigation updates
15. Check that back navigation works (`maybePop`)
16. Hot restart and verify guard state persists correctly

### Historical Notes

- **auto_route 9 -> 11:** Removed `$AppRouter` codegen base class. Guards moved from class-level implemented interface to a `guards` getter on `RootStackRouter`. `pushNamed` renamed to `pushPath`. `pop` renamed to `maybePop`. `reevaluateListenable` moved from `AutoRouterDelegate` to `RouterConfig`.
- **Guard pattern:** The skeleton uses two guard types -- global (`OnboardingGuard` via `guards` getter) and per-route (`AuthGuard` via `AutoRoute(guards: [...])` parameter). Both extend `AutoRouteGuard` and implement `onNavigation`.

### What Can Go Wrong

- **Generated code out of sync:** After upgrading, always regenerate `router.gr.dart` via `build_runner`. Stale generated code causes confusing type errors that look like user code bugs.
- **Guard interface change:** If `AutoRouteGuard.onNavigation` signature changes (e.g., new parameters), both `AuthGuard` and `OnboardingGuard` must be updated.
- **reevaluateListenable removal:** If this parameter is removed or renamed, the auth-state-driven guard re-evaluation will silently stop working. Users who sign in/out will not see navigation updates until they restart the app. Always verify this wiring after upgrade.
- **NavigationResolver API change:** If `resolver.next()` or `resolver.redirectUntil()` change signatures, guard redirects will break at compile time.

## 4. Drift Schema Migration

When: Adding new tables, columns, or modifying the Drift schema.

### Current Setup

- `AppDatabase` in `lib/core/database/app_database.dart`
- Schema version tracked via `schemaVersion` getter (currently `1`)
- Tables registered via `@DriftDatabase(tables: [CounterEntries])` annotation
- Registered as `@lazySingleton` in DI via `DatabaseModule`
- Testing uses `AppDatabase.forTesting(NativeDatabase.memory())` -- creates a fresh in-memory database from the current schema

### Adding a New Table

1. Create the table class (extends `Table`) in `lib/core/database/tables/`:
   ```dart
   class UserSettings extends Table {
     IntColumn get id => integer().autoIncrement()();
     TextColumn get key => text().withLength(min: 1, max: 255)();
     TextColumn get value => text()();
   }
   ```
2. Add it to the `@DriftDatabase(tables: [...])` annotation in `app_database.dart`:
   ```dart
   @DriftDatabase(tables: [CounterEntries, UserSettings])
   ```
3. Increment `schemaVersion` in `AppDatabase`:
   ```dart
   @override
   int get schemaVersion => 2;
   ```
4. Add a migration step. Currently `AppDatabase` has no explicit `migration` getter -- you need to add one:
   ```dart
   @override
   MigrationStrategy get migration => MigrationStrategy(
     onCreate: (m) => m.createAll(),
     onUpgrade: (m, from, to) async {
       if (from < 2) {
         await m.createTable(userSettings);
       }
     },
   );
   ```
5. Regenerate: `dart run build_runner build --delete-conflicting-outputs`
6. Run `fvm flutter analyze`
7. Run `fvm flutter test` -- repository tests use `NativeDatabase.memory()` which runs `onCreate` from scratch, so they verify the current schema is valid

### Adding a Column to an Existing Table

1. Add the column definition in the table class
2. Increment `schemaVersion`
3. Add an `onUpgrade` step using `customStatement`:
   ```dart
   if (from < 3) {
     await m.addColumn(counterEntries, counterEntries.newColumn);
   }
   ```
4. Regenerate and test as above

### Verifying Migration on Existing Data

8. Install the OLD version of the app on a device (or use an emulator with the old version already installed)
9. Create some data (e.g., increment the counter several times to populate `CounterEntries`)
10. Install the NEW version over it (upgrade install, not clean install):
    ```bash
    fvm flutter build apk --debug
    adb install -r build/app/outputs/flutter-apk/app-debug.apk
    ```
11. Launch the app and verify:
    - Existing data is preserved (counter value is the same)
    - New tables/columns are available (no crash on access)
    - Schema version in the database matches `schemaVersion` in code

### Runtime Verification

12. After upgrade install, run the app and exercise all features that touch the database
13. Check the app logs for any Drift migration errors (they log to stderr)
14. Uninstall and reinstall (clean install) to verify `onCreate` path still works with the full schema

### What Can Go Wrong

- **Missing migration step:** If you increment `schemaVersion` but don't add an `onUpgrade` handler for the transition, existing users' databases will fail to open with a `SchemaVersionMismatch` error. Always test upgrade installs.
- **Column type change:** Drift does not auto-migrate column types. You need manual SQL via `customStatement` for `ALTER TABLE` operations. Example:
  ```dart
  await m.database.customStatement('ALTER TABLE counter_entries ADD COLUMN label TEXT DEFAULT ""');
  ```
- **Generated code stale:** After schema changes, ALWAYS run `build_runner`. Stale `.g.dart` files cause confusing type errors where generated companion classes don't match the table definition.
- **Foreign key constraints:** If adding a foreign key to a new table that references an existing table, the migration must create the referenced table first. Order matters in `onUpgrade`.
- **NativeDatabase.memory() vs file:** Tests use `NativeDatabase.memory()` which always runs `onCreate` (fresh database). This does NOT test the `onUpgrade` path. To test migrations, you need a two-step test: create DB at old schema, then open it at new schema.
