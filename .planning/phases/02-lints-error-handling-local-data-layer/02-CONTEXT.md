# Phase 2: Lints, Error Handling, Local Data Layer - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Adopt `very_good_analysis` with errors-not-warnings on key rules, replace `dartz` `Either<Failure, T>` with Dart 3 sealed `Result<T>` + sealed `AppFailure` hierarchy, swap ObjectBox → Drift (with `SharedPreferencesAsync` + `flutter_secure_storage` thin wrappers registered in DI), port the counter example end-to-end on the new stack, and remove unused dependencies (`http`, `uuid`, `collection`, `dartz`, `objectbox`). This phase does **not** touch `flutter_bloc` version, `auto_route` version, Firebase wiring, flavors, or the `AuthService` contract — those are owned by Phases 3–5.

</domain>

<decisions>
## Implementation Decisions

### Sealed Result/Failure design
- **D-01:** `sealed class Result<T>` with `final class Success<T>(T value)` and `final class Failure<T>(AppFailure failure)`. A separate `sealed class AppFailure` hierarchy for failure classification. Single type parameter — no generic error type.
- **D-02:** Flat sealed hierarchy — one `sealed class AppFailure` with all failure types as direct `final class` subtypes. No nested sealed sub-hierarchies.
- **D-03:** Files live in existing `lib/core/errors/` dir: `result.dart` (sealed `Result<T>` + `ResultX` extension) and `failures.dart` (sealed `AppFailure` + subtypes).
- **D-04:** Phase 2 ships only `LocalDataNotFound` + `LocalDataSource` failure types. Phase 3 adds `AuthFailure`, Phase 5 adds `NetworkFailure` / `FirebaseFailure`. Each phase extends the hierarchy with what it needs.
- **D-05:** Minimal convenience extensions on `Result<T>`: `.isSuccess`, `.valueOrNull`, `.failureOrNull`. Exhaustive `switch` remains the primary consumption pattern in cubits and services.
- **D-06:** Big-bang migration — replace `dartz` everywhere in one pass. The skeleton is small (~6 files import `dartz`). No coexistence period, no temporary adapters. Write `Result<T>` + `AppFailure`, update all repos/services/cubits, remove `dartz` from pubspec, verify `flutter analyze` exits 0.

### Drift database design
- **D-07:** `AppDatabase` registered as `@lazySingleton` in `get_it` via `injectable`. Created lazily on first injection. Replaces the static `ObjectBox` singleton pattern with proper DI.
- **D-08:** Counter uses a single-row table pattern — `CounterEntries` table with `id` (autoIncrement) + `value` (integer, default 0). Upsert on write, `selectFirst` on read, `watchSingle` for reactive stream.
- **D-09:** `CounterModel` remains a plain Dart class (remove `@Entity()` and `objectbox` import, keep `copyWith`). The data source maps between Drift's generated `CounterEntry` row class and `CounterModel`. Domain layer stays Drift-free.
- **D-10:** Drift files live in `lib/core/database/` (renamed from `local_database/`). Structure: `app_database.dart` (`@DriftDatabase`), `app_database.g.dart` (generated), `tables/counter_entries.dart`, `connection/native.dart` (`drift_flutter` connection helper).
- **D-11:** Remove `_configureDatabases()` from `StartUpService`. Drift `AppDatabase` lazy-inits via DI graph — no explicit init step needed. `StartUpService.initServices()` becomes: Firebase → DI only.
- **D-12:** Full ObjectBox removal in one shot — delete `object_box.dart`, `objectbox.g.dart`, `objectbox-model.json`, remove `objectbox` / `objectbox_flutter_libs` / `objectbox_generator` from pubspec, remove `pubspec.yaml` `objectbox:` block, check whether `path_provider` has other consumers (remove if not).

### Preferences & secure storage
- **D-13:** Thin wrappers in `lib/core/preferences/` (`PreferencesService` abstract + `PreferencesServiceImpl`) and `lib/core/secure_storage/` (`SecureStorageService` abstract + `SecureStorageServiceImpl`). Both registered in DI as `@LazySingleton(as: PreferencesService)` / `@LazySingleton(as: SecureStorageService)`.
- **D-14:** Generic get/set API — `PreferencesService` exposes `getBool(key)`, `setBool(key, value)`, `getString(key)`, `setString(key, value)`, etc. Each feature defines its own key constants. Core stays feature-agnostic.
- **D-15:** No actual preference keys or secure storage keys defined in Phase 2. Phase 5 (auth) adds token keys, Phase 6 (onboarding) adds `hasSeenOnboarding`.

### Lint migration
- **D-16:** Full `very_good_analysis` adoption with strategic `// ignore` comments where rules genuinely don't apply (e.g., `public_member_api_docs` on skeleton example code). Target: `flutter analyze` exits 0.
- **D-17:** Generated files excluded from analysis: `**/*.g.dart`, `**/*.gr.dart`, `**/*.config.dart`, `**/*.freezed.dart`.
- **D-18:** Key lint rules promoted from warnings to errors: `avoid_print`, `unawaited_futures`, `missing_return`, `dead_code`, `unused_import`. These catch real bugs and set the quality bar for downstream apps.

### Claude's Discretion
- Exact `ResultX` extension method signatures beyond `.isSuccess`, `.valueOrNull`, `.failureOrNull` (e.g., whether to add `.mapSuccess`, `.mapFailure`)
- Whether to include a `Result.guard(() async => ...)` convenience factory for try/catch wrapping in repositories
- Drift `MigrationStrategy` scaffolding (empty but correct for `schemaVersion: 1`)
- `SecureStorageService` default encryption options (`AndroidOptions(encryptedSharedPreferences: true)`, `IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device)` per STACK.md recommendation)
- Exact set of `// ignore` comments needed to pass `very_good_analysis` on existing skeleton code
- Whether `path_provider` stays (if Drift's `drift_flutter` `driftDatabase()` helper removes the need)
- Feature-level `data/local_database/` folder rename or keep (the feature-level DAO folder name can stay `local_database/` even though core moved to `database/`)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Drift setup and migration patterns
- `.planning/research/STACK.md` §Drift section — version pins (`drift ^2.32.1`, `drift_flutter ^0.3.0`, `sqlite3_flutter_libs ^0.5.36`, `drift_dev ^2.32.1`), `@DriftDatabase` snippet, `driftDatabase()` native connection helper, `SharedPreferencesAsync` pattern
- `.planning/research/ARCHITECTURE.md` §Local Database Integration — Drift `AppDatabase` as `@lazySingleton`, table structure, reactive query pattern, DAO-per-feature design
- `.planning/research/PITFALLS.md` §ObjectBox → Drift Data Semantics — reactive query differences, schema migration requirements, SQLite initialization needs, stream cancellation gap
- `.planning/research/PITFALLS.md` §"Remove ObjectBox fully before adding Drift" — cleanup sequence (items 1–6)

### Sealed Result/Failure patterns
- `.planning/research/ARCHITECTURE.md` §sealed `Result<T>` — full sealed class definition, `switch` consumption pattern, exhaustiveness enforcement
- `.planning/research/PITFALLS.md` §dartz → Sealed Class Exhaustiveness — `Right(null)` smell fix, migration approach
- `.planning/research/STACK.md` §dartz replacement — sealed class definition, zero-dependency approach

### Lints
- `.planning/research/PITFALLS.md` §very_good_analysis retrofit cascade — expected ~60 new rules, adoption-before-new-code strategy, chunked cleanup approach
- `.planning/research/STACK.md` §Lints (very_good_analysis) — version pin (`^10.2.0`), include path, exclusion patterns

### Preferences and secure storage
- `.planning/research/STACK.md` §SharedPreferencesAsync — `SharedPreferencesAsync` API pattern, version pin
- `.planning/research/STACK.md` §flutter_secure_storage — version pin (`^10.0.0`), Android/iOS default options, keychain-access-groups entitlement requirement
- `.planning/research/PITFALLS.md` §`flutter_secure_storage` on iOS silently drops writes — keychain entitlement requirement for the skeleton's iOS setup

### Phase requirements and success criteria
- `.planning/REQUIREMENTS.md` §Data Layer (DATA-01 through DATA-05), §Core Dart Abstractions (CORE-01, CORE-02, CORE-06), §Tooling (TOOL-03)
- `.planning/ROADMAP.md` §Phase 2 Success Criteria 1–5

### Existing code to modify
- `lib/core/errors/failures.dart` — current `Failure` class hierarchy (replaced by sealed `AppFailure`)
- `lib/core/local_database/object_box.dart` — current ObjectBox singleton (deleted)
- `lib/features/home_page/data/model/counter_model.dart` — `@Entity()` annotation (removed, becomes plain Dart class)
- `lib/features/home_page/data/local_database/counter_local_database.dart` — ObjectBox `Box<T>` queries (rewritten for Drift)
- `lib/features/home_page/data/repository/counter_repository.dart` — `dartz` `Either` signatures (migrated to `Result<T>`)
- `lib/features/home_page/domain/counter_service.dart` — `Either` signatures (migrated)
- `lib/features/home_page/presentation/cubit/home_cubit.dart` — `.fold()` calls (migrated to `switch`)
- `lib/startup_service.dart` — `_configureDatabases()` removed, ObjectBox import removed
- `analysis_options.yaml` — `flutter_lints` → `very_good_analysis`
- `pubspec.yaml` — dependency additions/removals

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **CounterModel.copyWith** pattern: already hand-written, survives verbatim (just remove `@Entity()` and `@Id()` annotations + `objectbox` import)
- **Clean Architecture layering**: data source → repository → service → cubit flow is preserved. Only internals change (ObjectBox → Drift, Either → Result)
- **DI graph via injectable**: `@Injectable(as: X)` pattern stays. Add `@lazySingleton` for `AppDatabase`, `PreferencesService`, `SecureStorageService`
- **StartUpService orchestration**: simplified (fewer init steps), but same pattern
- **Logger usage in repositories**: `_logger.e(...)` before returning failure — pattern preserved through migration

### Established Patterns
- **Abstract class + Impl**: `CounterRepository` / `CounterRepositoryImpl` pattern preserved for all new services
- **part/part of for cubit + state**: unchanged
- **BuildContext extensions**: `context.localizations`, `context.theme` — untouched by Phase 2

### Integration Points
- **Phase 3 inherits**: sealed `Result<T>` as the error boundary contract. `flutter_bloc` 8 still in place (Phase 3 bumps to 9). `auto_route` 9 still in place (Phase 3 bumps to 11). `AuthService` contract in Phase 3 will use `Result<T>` / `AppFailure` from this phase.
- **Phase 5 inherits**: `PreferencesService` and `SecureStorageService` wrappers ready for auth token storage and Firebase config flags.
- **Phase 6 inherits**: `PreferencesService` for `hasSeenOnboarding` flag, Drift `AppDatabase` for any future onboarding data persistence.
- **Phase 7 inherits**: `very_good_analysis` lint baseline — bootstrap script must produce code that passes the stricter lints.

</code_context>

<specifics>
## Specific Ideas

- **Big-bang dartz removal**: the skeleton is small enough that coexistence adds complexity without safety. One pass, one commit for the sealed class migration.
- **Domain stays persistence-agnostic**: `CounterModel` is a plain Dart class. Data sources handle the mapping to/from Drift-generated types. This is the skeleton's Clean Architecture promise.
- **Lazy singleton for AppDatabase**: ObjectBox's static `initObjectBox()` pattern was a DI bypass. Drift integrates properly with `get_it` / `injectable` via `@lazySingleton`, making the startup sequence cleaner and testing easier (swap the singleton in test DI).
- **Generic preferences API**: the skeleton shouldn't know about onboarding or auth tokens at the core level. Features define their own keys — core provides the typed get/set plumbing.
- **Errors-not-warnings lint philosophy**: the skeleton sets the quality bar. If a rule catches real bugs (`unawaited_futures`, `avoid_print`), it should be an error, not a warning that CI scrolls past.

</specifics>

<deferred>
## Deferred Ideas

- Stream cancellation fix in `HomeCubit.close()` (CONCERNS.md bug) — address during the cubit migration in this phase or explicitly in Phase 3 when `flutter_bloc` 9's `close()` semantics may change
- `Result.guard()` factory for try/catch wrapping — if it proves useful during migration, Claude may add it at discretion
- Drift schema migration scaffolding for multi-table apps — Phase 2 only needs `schemaVersion: 1`; real migration patterns documented when a second table lands
- iOS keychain-access-groups entitlement for `flutter_secure_storage` — Phase 4 (flavors) or Phase 5 (Firebase Auth) will set up the entitlements files per scheme; Phase 2 just registers the service wrapper

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-lints-error-handling-local-data-layer*
*Context gathered: 2026-04-17*
