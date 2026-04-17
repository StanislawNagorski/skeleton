# Phase 2: Lints, Error Handling, Local Data Layer - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 02-lints-error-handling-local-data-layer
**Areas discussed:** Sealed Result/Failure design, Drift database design, Preferences & secure storage scope, Lint migration strictness

---

## Sealed Result/Failure design

### Result<T> structure

| Option | Description | Selected |
|--------|-------------|----------|
| Result<T> only | sealed Result<T> with Success<T>(value) and Failure<T>(AppFailure). Separate sealed AppFailure hierarchy. | ✓ |
| Result<T, E> with generic error | Two type params for per-method failure typing. More flexible but more verbose. | |
| You decide | Claude picks. | |

**User's choice:** Result<T> only
**Notes:** Clean separation — Result handles branching, AppFailure handles classification.

### Failure hierarchy organization

| Option | Description | Selected |
|--------|-------------|----------|
| Flat sealed hierarchy | One sealed AppFailure with all types as direct subtypes. Simple, exhaustive switch covers everything. | ✓ |
| Grouped sub-sealed hierarchy | Nested sealed classes (LocalFailure, NetworkFailure, AuthFailure). More structured but deeper nesting. | |
| You decide | Claude picks. | |

**User's choice:** Flat sealed hierarchy
**Notes:** None.

### File location

| Option | Description | Selected |
|--------|-------------|----------|
| Same errors/ dir | result.dart + failures.dart in lib/core/errors/. Minimal disruption. | ✓ |
| Barrel + single file | One file with both types + barrel export. Fewer files. | |
| You decide | Claude picks. | |

**User's choice:** Same errors/ dir
**Notes:** None.

### Starter failure types

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal: local only | Only LocalDataNotFound + LocalDataSource. Other phases add their own types. | ✓ |
| Forward-looking set | Ship all likely types now (including NetworkFailure, AuthFailure, UnknownFailure). | |
| You decide | Claude picks. | |

**User's choice:** Minimal: local only
**Notes:** Each phase adds what it uses — keeps the skeleton lean.

### Convenience extensions

| Option | Description | Selected |
|--------|-------------|----------|
| No extensions | Only exhaustive switch. Minimal API surface. | |
| Minimal extensions | .isSuccess, .valueOrNull, .failureOrNull for quick checks. Switch remains primary. | ✓ |
| You decide | Claude picks. | |

**User's choice:** Minimal extensions
**Notes:** Needed for the existing _getCounter() helper pattern that folds to nullable.

### dartz migration sequencing

| Option | Description | Selected |
|--------|-------------|----------|
| Big bang | Replace all in one pass. Skeleton is small (~6 files). No coexistence. | ✓ |
| Layered bottom-up | Migrate layer by layer with compile-checks between. Safer for large codebases. | |

**User's choice:** Big bang
**Notes:** None.

---

## Drift database design

### AppDatabase registration

| Option | Description | Selected |
|--------|-------------|----------|
| @lazySingleton in DI | Proper DI integration. Created lazily on first injection. | ✓ |
| Static singleton (like ObjectBox) | Same pattern as current code. Bypasses DI, harder to test. | |
| You decide | Claude picks. | |

**User's choice:** @lazySingleton in DI
**Notes:** None.

### Counter table schema

| Option | Description | Selected |
|--------|-------------|----------|
| Single-row pattern | One row, upsert on write, selectFirst on read, watchSingle for reactivity. | ✓ |
| Key-value approach | Generic settings table. Loses type safety, awkward reactive queries. | |
| You decide | Claude picks. | |

**User's choice:** Single-row pattern
**Notes:** Matches current ObjectBox behavior.

### CounterModel approach

| Option | Description | Selected |
|--------|-------------|----------|
| Keep plain Dart model | Domain stays Drift-free. Data source maps between generated row class and model. | ✓ |
| Use Drift-generated directly | Fewer files but leaks persistence into domain. | |
| You decide | Claude picks. | |

**User's choice:** Keep plain Dart model
**Notes:** Clean Architecture principle — domain doesn't know about persistence.

### File location

| Option | Description | Selected |
|--------|-------------|----------|
| lib/core/database/ | Renamed from local_database/. Clean break from ObjectBox naming. | ✓ |
| lib/core/local_database/ | Keep existing directory name. Less import churn. | |
| You decide | Claude picks. | |

**User's choice:** lib/core/database/
**Notes:** None.

### Startup sequence

| Option | Description | Selected |
|--------|-------------|----------|
| DI handles it | Remove _configureDatabases(). Drift lazy-inits via DI. Simpler init. | ✓ |
| Explicit init before DI | Keep _configureDatabases() but with Drift. More control over init order. | |
| You decide | Claude picks. | |

**User's choice:** DI handles it
**Notes:** None.

### ObjectBox cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Full removal in one shot | Delete all ObjectBox files, deps, and pubspec config. Clean slate. | ✓ |
| You decide | Claude handles details. | |

**User's choice:** Full removal in one shot
**Notes:** None.

---

## Preferences & secure storage scope

### Infrastructure scope

| Option | Description | Selected |
|--------|-------------|----------|
| Thin wrappers in core/ | PreferencesService + SecureStorageService abstractions registered in DI. No keys yet. | ✓ |
| Just add deps, no wrappers | Add to pubspec, features use packages directly. | |
| You decide | Claude picks. | |

**User's choice:** Thin wrappers in core/
**Notes:** None.

### API style

| Option | Description | Selected |
|--------|-------------|----------|
| Generic get/set | Typed methods (getBool, setString, etc.). Features define own keys. Core stays agnostic. | ✓ |
| Typed named methods | Named getter/setter per preference. Discoverable but couples core to features. | |
| You decide | Claude picks. | |

**User's choice:** Generic get/set
**Notes:** None.

---

## Lint migration strictness

### Adoption strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Full VGA, strategic ignores | Enable as-is. Fix everything fixable. // ignore only where rules genuinely don't apply. | ✓ |
| VGA with relaxed doc rules | Enable VGA but disable public_member_api_docs. | |
| You decide | Claude picks. | |

**User's choice:** Full VGA, strategic ignores
**Notes:** None.

### Error promotion

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, promote key rules | Promote avoid_print, unawaited_futures, missing_return, dead_code, unused_import to errors. | ✓ |
| Keep VGA defaults | Don't override severity levels. | |
| You decide | Claude picks. | |

**User's choice:** Yes, promote key rules
**Notes:** Sets the quality bar for downstream apps.

---

## Claude's Discretion

- Exact `ResultX` extension method signatures beyond the three decided
- `Result.guard()` convenience factory
- Drift `MigrationStrategy` scaffolding
- `SecureStorageService` default encryption options
- Exact set of `// ignore` comments for VGA compliance
- `path_provider` retention decision
- Feature-level `data/local_database/` folder naming

## Deferred Ideas

- Stream cancellation fix in `HomeCubit.close()` — address during migration or Phase 3
- iOS keychain-access-groups entitlement — Phase 4/5
