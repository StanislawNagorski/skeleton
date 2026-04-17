# Skeleton - Flutter App Template

Skeleton is a Flutter application template designed to speed up the development of new projects. Before starting work on a new app, you need to update the package name (`namespace`).
Or delete android and ios folders and run `flutter create .` to generate new ones.

## Instructions for Changing the Package Name

### Android
1. Open the file `android/app/build.gradle`.
2. In the `android {}` section, update the `namespace` to:
   ```gradle
   android {
       namespace = "com.your.new.package"
   }
3. **Rename the Java/Kotlin package folder structure:**
  - Navigate to the folder `android/app/src/main/java/com/example/skeleton`.
  - Rename `example` and `skeleton` folders to match your new package name.
   **Example:**
   For the package name `com.your.new.package`, the structure should be:
4. **Update the `package` attribute in `AndroidManifest.xml`:**
- Open `android/app/src/main/AndroidManifest.xml`.
- Modify the `package` attribute in the `<manifest>` tag:
  ```xml
  <manifest xmlns:android="http://schemas.android.com/apk/res/android"
      package="com.your.new.package">
  ```

### iOS
1. **Update the Bundle Identifier in Xcode:**

- In Xcode:
  - Select the Runner project in the project navigator.
  - Go to the General tab.
  - Update the Bundle Identifier field (e.g., com.your.new.package).
- Update the Info.plist file:
  - Open `ios/Runner/Info.plist`.
  - Update the `CFBundleIdentifier` key:
    ```xml
    <key>CFBundleIdentifier</key>
    <string>com.your.new.package</string>
    ```

### Firebase
1. **Update the Firebase configuration:**
2. fallow: https://firebase.google.com/docs/flutter/setup?hl=pl&platform=ios

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

### Troubleshooting
- Generate boilerplate code:   - `flutter packages pub run build_runner build --delete-conflicting-outputs`
- Some methods to deal with common problems:
    - `flutter doctor` may help you to locate problem
    - `flutter clean` it removes downloaded packages, plugins and builds.
    - `flutter pub upgrade` upgrades packages to latest versions
    - `flutter pub cache repair` sometimes packages cache needs to be clean
- IOS has some problem of its own:
    - When you will face pods problems run those:   
      `pod cache clean --all`   
      `rm -rf ios/Podfile.lock`   
      `rm -rf ios/Pods/`   
      `pod repo update` and `pod install`

## Architecture
- **Clean Architecture**: The project is structured using the Clean Architecture pattern, which separates the app into three layers: data, domain, and presentation.  
  - **Data**: The data layer is responsible for managing the app's data sources, such as local and remote databases. It also contains repositories that provide data to the domain layer.  
    - **model** - classes representing data structures.
    - **data source** - implementation of local or remote API data source. Use Interface to define methods. Avoid implementing logic in this layer.
    - **repository** - provides data to the domain layer and handles errors matching them to Failures that may be used to provide feedback on presentation layer.
  - **Domain**: The domain layer contains the business logic of the app.
    - **services** - classes that provide business logic and may use various repositories.
    - **entities** - classes representing business entities, it is parsed from and to models. It should contain only data which will be used or displayed.
  - **Presentation**: The presentation layer is responsible for displaying the app's UI and handling user interactions.
    - **pages** - contains all pages and widgets that are used to display UI.
    - **cubits** - classes that manage the app's state and UI logic. They are used to communicate between the presentation and domain layers.
    - **widgets** - contains all reusable widgets that are used in the app.

## Naming convention
- **methods** should include verb and be clear about action they do.    
  example: getAllPromotions, validateCode.
- **variables and classes** should be noun.   
  example: ApiClient apiClient, String userInput, int debounceTimeInMilliSeconds.
- **bools** should have question prefix like: _is, should._   
  example: isValid, isFirstTimeLogin, shouldFetchNewData,

## Packages

### Utils packages
- **logger**: Use for console logs. It can also display logs directly in device. To change/manage style go to `lib/core/utils/logger.dart`.   
  Docs: https://pub.dev/packages/logger
- **path_provider**: This package provides information about device default storage folder.It is needed to set up local database.   
  Docs: https://pub.dev/packages/path_provider
- **dartz**: functional programing style to Dart. We use Either pattern.  
  Docs: https://pub.dev/packages/dartz
- **device_info_plus**: package to receive information about user device, like system and version.   
  Docs: https://pub.dev/packages/device_info_plus
- **uuid** for creating UUIDs   
  Docs: https://pub.dev/packages/uuid/
- **auto_route** for managing app navigation   
  Docs: https://pub.dev/packages/auto_route

### Widgets & UI Utils
- **cupertino_icons**: Set of IOS default icons.   
  Docs: https://api.flutter.dev/flutter/cupertino/CupertinoIcons-class.html#constants

### Translations
- **intl**: Package to keep and translate all hardcoded content. It allows for using various grammar rules. Files are located at: `lib/core/localization`   
  Docs: https://docs.flutter.dev/development/accessibility-and-localization/internationalization

### Dependency injection
- **get_it**: This packages allow to inject object in any place of widget tree. We use it to initialize cubits, and inject repositories and services.   
  Docs: https://pub.dev/packages/get_it
- **injectable** && **injectable_generator**: Those allow to use @annotations on class level, which registers them with get_it and allows easy injection by generating all necessary boiler code.   
  Docs: https://pub.dev/packages/injectable

### Database
- **objectbox** && **objectbox_generator** **: Flutter multi-platform local NoSQL database.   
  Docs: https://pub.dev/packages/objectbox
  Docs: https://docs.objectbox.io/getting-started
- **cloud_firestore**: Remote NoSQL database.
  Docs: https://pub.dev/packages/cloud_firestore

### Navigator
- **auto_route** && **auto_route_generator**: Pages navigator for Flutter, and boilerplate generator.   
  Docs: https://pub.dev/packages/auto_route

### State management
- **flutter_bloc**: State management tool. It connects pages with business logic kept in Cubit classes. Pages use methods in Cubit and Cubits emits proper app states to be handled by page builder.   
  Docs: https://pub.dev/packages/bloc

### Developers
- **build_runner**: All boilerplate code generator depends on this package to generate files.   
  Docs: https://pub.dev/packages/build_runner
- **flutter_lints**: Package to provide all good Flutter and Dart coding practices. Default rules can be changed in `analysis_options.yaml`   
  Docs: https://pub.dev/packages/flutter_lints

## Firebase Setup

The skeleton works out of the box without Firebase (`clone -> flutter run`).
When you are ready to connect your Firebase project, follow the steps below.

### Prerequisites

- A Firebase project created in [Firebase Console](https://console.firebase.google.com/)
- FlutterFire CLI installed:
  ```bash
  dart pub global activate flutterfire_cli
  ```

### 1. Generate Firebase Options

```bash
flutterfire configure --project=YOUR_PROJECT_ID
```

This replaces the stub `lib/firebase_options.dart` with real configuration.
After this step, `flutter run` initializes Firebase and registers
`FirebaseAuthService` instead of `FakeAuthService`.

### 2. Google Sign-In Setup

#### Android

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

#### iOS

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

### 3. Apple Sign-In Setup

Apple Sign-In is iOS only (per D-06). The Xcode entitlement is not pre-enabled --
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

### 4. App Check (Release Builds Only)

App Check is activated automatically in release builds (`kReleaseMode`):

| Platform | Provider |
|----------|----------|
| Android  | Play Integrity (requires Play Console enrollment) |
| iOS      | App Attest (requires iOS 14+; skeleton floor is iOS 15) |

No debug-token configuration needed -- dev builds skip App Check entirely.

### 5. Crashlytics

Crashlytics is wired automatically when Firebase is initialized:

- `FlutterError.onError` catches Flutter framework errors
- `PlatformDispatcher.instance.onError` catches async Dart errors
- `Isolate.current.addErrorListener` catches spawned isolate errors

Collection is disabled in debug builds -- only release crashes are reported.

### Dev Mode (No Firebase)

If `firebase_options.dart` is the stub (no `flutterfire configure` run), the app:

- Falls back to the `'dev'` DI environment
- Registers `FakeAuthService` (in-memory, any email/password works)
- Does not register Firebase Analytics, Performance, or Firestore
- Does not activate Crashlytics or App Check

This preserves the `clone -> flutter run` DX promise.

## Changelog
- **1.0.1** **13/02/2025**:
  - LocalDataSource with ObjectBox implemented
  - Base data flow data->domain->presentation added
- **1.0.0** **10/01/2025**:
    - Repo creation and initial setup

