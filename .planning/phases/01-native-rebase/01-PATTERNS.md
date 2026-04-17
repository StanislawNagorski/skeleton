# Phase 1: Native Rebase - Pattern Map

**Mapped:** 2026-04-16
**Files analyzed:** 12 new/modified files
**Analogs found:** 9 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.fvmrc` | config | N/A | `.fvmrc` (current) | exact-self |
| `pubspec.yaml` (environment block only) | config | N/A | `pubspec.yaml` (current) | exact-self |
| `android/app/build.gradle` | config | N/A | `android/app/build.gradle` (current) | exact-self |
| `android/settings.gradle` | config | N/A | `android/settings.gradle` (current) | exact-self |
| `android/gradle.properties` | config | N/A | `android/gradle.properties` (current) | exact-self |
| `android/build.gradle` | config | N/A | `android/build.gradle` (current) | exact-self |
| `android/key.properties.template` | config | N/A | none | no-analog |
| `ios/Podfile` | config | N/A | `ios/Podfile` (current) | exact-self |
| `ios/Flutter/AppFrameworkInfo.plist` | config | N/A | `ios/Flutter/AppFrameworkInfo.plist` (current) | exact-self |
| `.gitignore` | config | N/A | `.gitignore` (current) | exact-self |
| `.planning/rebase_manifest.md` | documentation | N/A | none | no-analog |
| `README.md` (release signing section) | documentation | N/A | `README.md` (current) | exact-self |

## Pattern Assignments

### `.fvmrc` (config)

**Analog:** `.fvmrc` (current file, replaced in-place)

**Current content** (line 1-3):
```json
{
  "flutter": "3.29.0"
}
```

**Pattern:** Single JSON object with `flutter` key. Replace version string `3.29.0` with `3.41.5`.

---

### `pubspec.yaml` (config, environment block only)

**Analog:** `pubspec.yaml` (current file, surgical edit)

**Current environment block** (lines 7-8):
```yaml
environment:
  sdk: ^3.6.0
```

**Pattern:** Update SDK constraint to `^3.9.0` per PROJECT.md constraints (Dart 3.9). Leave all other sections (dependencies, dev_dependencies, flutter, objectbox) completely untouched per D-04.

---

### `android/app/build.gradle` (config, release signing scaffolding)

**Analog:** `android/app/build.gradle` (current file)

**Current signing section being replaced** (lines 33-39):
```gradle
    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.debug
        }
    }
```

**Target pattern per D-07/D-08/D-09:** The fresh `flutter create` output will provide the base structure. On top of that, add:
1. A `key.properties` file reader at the top (before `android {}`)
2. A fallback to env vars if `key.properties` is absent
3. A `signingConfigs.release` block populated from whichever source is available
4. When neither source present: no `signingConfigs.release` defined, gradle-config-time warning logged, `buildTypes.release.signingConfig` left unset

**Reference: Gradle key.properties pattern** (standard Flutter/Android convention):
```gradle
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

**Note:** The fresh `flutter create` 3.41.5 output will use Kotlin DSL (`.gradle.kts`) or Groovy depending on the SDK version. The planner must accept whichever format `flutter create` emits, then layer the signing scaffolding on top using that same DSL. Current file uses Groovy.

**Current Java/Kotlin target** (lines 13-19):
```gradle
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8
    }
```

**Target:** Accept fresh `flutter create` defaults for Java compatibility. PROJECT.md says Java 17 -- fresh template should emit that or the planner should verify and adjust.

---

### `android/settings.gradle` (config)

**Analog:** `android/settings.gradle` (current file, replaced by fresh template)

**Current content** (lines 1-25):
```gradle
pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withInputStream { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.1.0" apply false
    id "org.jetbrains.kotlin.android" version "1.8.22" apply false
}

include ":app"
```

**Pattern:** Accept fresh `flutter create` output verbatim. Key version changes expected: AGP `8.1.0` to `8.11.1`, Kotlin `1.8.22` to `2.2.20`, Gradle wrapper to `8.14`. No manual edits needed -- fresh template should align with PROJECT.md constraints.

---

### `android/gradle.properties` (config)

**Analog:** `android/gradle.properties` (current file)

**Current content** (lines 1-3):
```properties
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
```

**Pattern per D-10:** Accept fresh `flutter create` defaults. Do NOT re-apply the custom JVM args. Fresh template will likely emit standard `org.gradle.jvmargs=-Xmx4G` or similar default.

---

### `android/build.gradle` (config, root-level)

**Analog:** `android/build.gradle` (current file, replaced by fresh template)

**Current content** (lines 1-18):
```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = "../build"
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
```

**Pattern:** Accept fresh `flutter create` output verbatim. Flutter 3.41.5 may restructure this significantly (recent Flutter versions have simplified root build.gradle).

---

### `android/key.properties.template` (config, NEW file)

**No analog in codebase.** This is a new file per D-09.

**Pattern from D-09 decisions:**
```properties
# Release signing configuration
# Copy this file to key.properties and fill in your values.
# key.properties is gitignored and must NOT be committed.
#
# Generate a keystore:
#   keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
#
storeFile=keystore.jks
storePassword=
keyAlias=
keyPassword=
```

**Naming convention:** `.template` suffix for committed template files, with the actual file gitignored.

---

### `ios/Podfile` (config)

**Analog:** `ios/Podfile` (current file)

**Current platform line** (line 2):
```ruby
platform :ios, '13.0'
```

**Pattern:** Accept fresh `flutter create` Podfile, then ensure platform floor is set to `'15.0'` per PROJECT.md constraints (Firebase iOS SDK 12.x requires 15). The fresh template might emit a lower default that needs bumping.

**Current structure to preserve** (lines 30-38):
```ruby
target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end
```

---

### `ios/Flutter/AppFrameworkInfo.plist` (config)

**Analog:** `ios/Flutter/AppFrameworkInfo.plist` (current file)

**Current MinimumOSVersion** (line 23-24):
```xml
  <key>MinimumOSVersion</key>
  <string>12.0</string>
```

**Pattern:** Accept fresh `flutter create` output. Per Claude's Discretion section, consider aligning to `15.0` to match Podfile floor if the fresh template still emits a lower value.

---

### `.gitignore` (config, append entries)

**Analog:** `.gitignore` (current file)

**Current content** (48 lines) -- relevant section for signing additions at bottom:
```gitignore
# Android Studio will place build artifacts here
/android/app/debug
/android/app/profile
/android/app/release

# FVM Version Cache
.fvm/
```

**Pattern per D-09:** Append two entries for signing file exclusion:
```gitignore
# Release signing
android/key.properties
android/app/*.jks
```

---

### `.planning/rebase_manifest.md` (documentation, NEW file)

**No analog in codebase.** New deliverable per D-13.

**Pattern:** This is a planning artifact, not code. The planner should structure it as a checklist of every native edit (or explicit non-edit), referencing the D-XX decision IDs from CONTEXT.md. No code pattern to copy -- format is at Claude's discretion per the decisions.

---

### `README.md` (documentation, add release signing section)

**Analog:** `README.md` (current file)

**Current structure** -- sections:
1. Instructions for Changing the Package Name (lines 6-42)
2. Firebase (lines 43-45)
3. Troubleshooting (lines 47-59)
4. Architecture (lines 61-73)
5. Naming convention (lines 75-82)
6. Packages (lines 83-132)
7. Changelog (lines 134-140)

**Pattern per D-09:** Add a `## Release Signing` section. Placement: after the Firebase section, before Troubleshooting. Content: keytool command, copy template, fill values, `flutter build apk --release`.

**Existing heading style:** `## Section Name` (level 2 headings for top sections), `### Subsection` (level 3 for nested).

---

## Shared Patterns

### FVM Usage
**Source:** `.fvmrc` and D-05 decisions
**Apply to:** All commands in the rebase procedure
```
fvm install 3.41.5 && fvm use 3.41.5
fvm flutter create ...
fvm flutter pub get
```
All Flutter CLI invocations must go through FVM to ensure the pinned SDK version is used.

### Fresh Template Acceptance
**Source:** D-10, D-11, D-12 decisions
**Apply to:** All files replaced by `flutter create` output
**Rule:** Accept fresh `flutter create` defaults verbatim. Do not re-apply customizations from the old skeleton unless explicitly decided (only the signing scaffolding D-07/D-08/D-09 and Podfile floor bump are explicit additions).

### Platform Deletion
**Source:** D-02, CONTEXT.md "What Goes Away" section
**Apply to:** Directories `web/`, `macos/`, `linux/`, `windows/`
**Pattern:** These are deleted entirely (never created in the first place if `--platforms=android,ios` is used correctly). Run `flutter clean` after deletion to clear cached references per PITFALLS.md.

### Post-Rebase Regeneration
**Source:** CONTEXT.md "Established Patterns" section
**Apply to:** After all native files are in place
```bash
fvm flutter pub get
dart run build_runner build --delete-conflicting-outputs
```
The `flutter:generate: true` in pubspec.yaml drives l10n generation on `pub get`.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `android/key.properties.template` | config | N/A | New file -- standard Android signing template pattern, not present in current skeleton |
| `.planning/rebase_manifest.md` | documentation | N/A | New planning artifact -- no prior manifest exists |

---

## Metadata

**Analog search scope:** Project root (`/Users/stanislawnagorski/Developer/WeCodeMobile/skeleton/skeleton/`)
**Files scanned:** android/, ios/, .fvmrc, .gitignore, pubspec.yaml, README.md
**Pattern extraction date:** 2026-04-16
