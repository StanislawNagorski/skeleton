---
status: partial
phase: 04-firebase-wiring-auth-providers
source: [04-VERIFICATION.md]
started: 2026-04-17T18:45:00Z
updated: 2026-04-17T18:45:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Firebase End-to-End Init
expected: Run `flutterfire configure` + `flutter run` against a real Firebase project — app boots with Firebase initialized
result: [pending]

### 2. Crashlytics Error Surfacing
expected: Force error in release build, verify it appears in Crashlytics dashboard within minutes
result: [pending]

### 3. Auth Provider Flows
expected: Exercise all 6 auth methods (email sign-up, email sign-in, Google sign-in, Apple sign-in, password reset, sign-out) against real Firebase Auth with providers enabled
result: [pending]

### 4. App Check Release Activation
expected: Build release APK/IPA, verify attestation completes (App Check passes in release, skipped in debug)
result: [pending]

### 5. Cross-Platform Build
expected: Both `flutter build apk` and `flutter build ios` succeed after `flutterfire configure`
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
