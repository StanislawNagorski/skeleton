# Phase 4: Firebase Wiring + Auth Providers - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 04-firebase-wiring-auth-providers
**Areas discussed:** Startup sequence & DI switchover, Google & Apple Sign-In native setup, Crashlytics & error handler wiring, App Check activation strategy

---

## Startup sequence & DI switchover

### Q1: Should the skeleton still boot without Firebase config files?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — FakeAuthService fallback | If Firebase config files are missing, skip Firebase.initializeApp and register FakeAuthService. Preserves DX promise. | ✓ |
| No — Firebase required | After Phase 4, skeleton requires Firebase to be configured. Simpler code but breaks instant-boot DX. | |
| Compile-time flag | Use --dart-define=USE_FIREBASE=true to switch. Explicit but adds friction. | |

**User's choice:** Yes — FakeAuthService fallback
**Notes:** User confirmed this preserves the clone → flutter run promise.

### Q2: How should the DI graph switch between FakeAuthService and FirebaseAuthService?

| Option | Description | Selected |
|--------|-------------|----------|
| @Environment annotations | FakeAuthService @Environment('dev'), FirebaseAuthService @Environment('prod'). Injectable's native mechanism. | ✓ |
| Runtime conditional in @module | Custom @module method checks Firebase init state, returns the right impl. Single environment. | |
| Manual getIt override | Always register Fake, then unregister/re-register if Firebase succeeds. | |

**User's choice:** @Environment annotations
**Notes:** User raised concern about apps with custom backends (no Firebase). Clarified: custom-backend apps write their own impl under a new @Environment. FakeAuthService is dev-only, never production for any backend type.

### Q3: Where should Firebase.initializeApp live?

| Option | Description | Selected |
|--------|-------------|----------|
| In StartUpService, before DI | Sequential flow: ensureInitialized → Firebase.initializeApp → Crashlytics + App Check → configureDependencies(env). | ✓ |
| In main.dart directly | Makes sequence visible in entrypoint but splits startup logic. | |
| Lazy in FirebaseAuthService | Firebase.initializeApp on first access. Decouples but delays init. | |

**User's choice:** In StartUpService, before DI
**Notes:** None.

---

## Google & Apple Sign-In native setup

### Q1: How much native config should be pre-wired?

| Option | Description | Selected |
|--------|-------------|----------|
| Code only, native = documented | Full Dart code for sign-in. Native config as README checklist for post-bootstrap. | ✓ |
| Placeholder entries in native files | Add placeholder entries in Info.plist, Xcode, build.gradle. Bootstrap replaces them. | |
| Full template with conditionals | Pre-wire everything with compile-time checks. | |

**User's choice:** Code only, native = documented
**Notes:** None.

### Q2: How should Google Sign-In serverClientId be provided?

| Option | Description | Selected |
|--------|-------------|----------|
| Read from firebase_options.dart | FirebaseAuthService reads Web client ID from DefaultFirebaseOptions at runtime. | ✓ |
| Separate config constant | Manual GOOGLE_SERVER_CLIENT_ID constant. | |
| --dart-define at build time | Pass via build flag. | |

**User's choice:** Read from firebase_options.dart
**Notes:** None.

### Q3: Apple Sign-In Xcode entitlement?

| Option | Description | Selected |
|--------|-------------|----------|
| Document only | Don't touch Xcode entitlements. README documents the step. | ✓ |
| Pre-enable in Xcode | Add entitlement file and capability now. | |

**User's choice:** Document only
**Notes:** Avoids entitlement/bundle-ID mismatches after bootstrap.

---

## Crashlytics & error handler wiring

### Q1: How should Crashlytics collection behave in debug builds?

| Option | Description | Selected |
|--------|-------------|----------|
| Disable collection entirely | setCrashlyticsCollectionEnabled(kReleaseMode). Debug crashes local only. | ✓ |
| Collect but mark as debug | Enable in all modes, tag debug crashes with custom key. | |
| You decide | Claude picks standard approach. | |

**User's choice:** Disable collection entirely
**Notes:** None.

### Q2: Should the skeleton wire the isolate error listener?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — wire it | Isolate.current.addErrorListener forwarding to Crashlytics. Future-proofs for downstream apps. | ✓ |
| Skip — document only | Skeleton doesn't use isolates. Document pattern in README. | |
| You decide | Claude's discretion based on FIRE-03. | |

**User's choice:** Yes — wire it
**Notes:** None.

---

## App Check activation strategy

### Q1: App Check Apple provider?

| Option | Description | Selected |
|--------|-------------|----------|
| appAttest | Stronger attestation, Apple's recommended. Requires iOS 14+ (floor is 15). | ✓ |
| deviceCheck | Weaker but broadly compatible. Works iOS 11+. | |
| appAttestWithDeviceCheckFallback | Try appAttest, fall back to deviceCheck. Fallback never triggers at iOS 15 floor. | |

**User's choice:** appAttest
**Notes:** None.

### Q2: Should dev builds skip App Check entirely?

| Option | Description | Selected |
|--------|-------------|----------|
| Skip entirely in dev | if (kReleaseMode) activate. No debug provider, no token friction. | ✓ |
| Debug provider in dev | Activate with debug providers. Requires per-developer token registration. | |

**User's choice:** Skip entirely in dev
**Notes:** None.

---

## Claude's Discretion

- Firebase package version bumps to BoM 4.12.0 matrix
- FirebaseAuthService implementation details (error mapping, stream management)
- Whether to refine AuthError into granular subtypes
- cloud_firestore offline persistence config
- FirebaseAnalytics / FirebasePerformance DI registration approach
- README section structure for post-bootstrap checklist

## Deferred Ideas

- @Environment('test') split for test harness → Phase 6
- Granular auth failure subtypes → Claude's discretion during implementation
- OnboardingGuard → Phase 5
