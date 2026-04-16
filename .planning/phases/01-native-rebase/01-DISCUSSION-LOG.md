# Phase 1: Native Rebase - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-16
**Phase:** 01-native-rebase
**Areas discussed:** Rebase safety & rollback, Pubspec merge scope, Release signing scaffolding, Native customizations to preserve

---

## Rebase safety & rollback

### Q1: Pre-rebase rollback marker

| Option | Description | Selected |
|--------|-------------|----------|
| Annotated git tag + branch | Tag `2026-update` HEAD as `pre-rebase-phase-1` (annotated). Rollback via `git reset --hard pre-rebase-phase-1`. Tag persists forever. | |
| New feature branch off 2026-update | Create `phase-1-native-rebase` branch. Merge after success. Keeps `2026-update` clean but adds branch overhead. | |
| Plain commit on current branch | Commit on `2026-update` with clear `pre-rebase` commit message. Use `git reset` against the labeled hash. | ✓ |

**User's choice:** Plain commit on current branch
**Notes:** Lighter-weight than tag/branch. The git history itself is the rollback record.

### Q2: Stale Kotlin source folder cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit delete in rebase | `rm -rf` the old `android/app/src/main/kotlin/com/example/skeleton/` path. Verify single MainActivity.kt post-rebase. | ✓ |
| Trust flutter create | Rely on `flutter create` regenerating from scratch. Risk: orphan folder ships in commits. | |

**User's choice:** Explicit delete in rebase
**Notes:** PITFALLS.md explicitly warns `flutter create` doesn't reliably clean stale Kotlin folders.

### Q3: iOS Pods + Podfile.lock cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-delete in rebase script | Delete `ios/Pods/` and `ios/Podfile.lock`, run `pod install` fresh. Prevents version-conflict cascades. | ✓ |
| Document as manual step | README mentions `pod deintegrate && rm Podfile.lock && pod install`. More skip-and-forget risk. | |

**User's choice:** Auto-delete in rebase script

---

## Pubspec merge scope

### Q1: How much of pubspec.yaml does Phase 1 touch?

| Option | Description | Selected |
|--------|-------------|----------|
| SDK constraints only | Update only `environment:` (Dart ^3.9.0 + Flutter floor). Leave deps, dev_deps, flutter_lints, objectbox block, assets untouched. | ✓ |
| SDK + flutter section structure | Update SDK + replace `flutter:` block (uses-material-design, generate, asset structure) with fresh template shape. | |
| SDK + drop flutter_lints now | Update SDK + remove flutter_lints since Phase 2 swaps to very_good_analysis. Risk: analysis_options.yaml references missing package between phases. | |
| Full template overlay | Full template pubspec as base, re-paste skeleton's deps. ARCHITECTURE.md Step 4 wording. Invisible churn risk. | |

**User's choice:** SDK constraints only
**Notes:** Phase 2 owns dependency bumps + lints swap + ObjectBox removal. Phase 1 stays mechanical.

### Q2: When does .fvmrc flip from 3.29.0 → 3.41.5?

| Option | Description | Selected |
|--------|-------------|----------|
| First step of rebase | Bump `.fvmrc` and run `fvm install 3.41.5 && fvm use 3.41.5` BEFORE temp-dir `flutter create`. | ✓ |
| After temp-dir create | Generate temp scaffold with whatever Flutter is current, bump `.fvmrc` after swap. | |

**User's choice:** First step of rebase
**Notes:** Guarantees scaffold is generated against the target SDK, not whatever the host happened to have.

### Q3: Asset directory declarations (current pub get warnings)

| Option | Description | Selected |
|--------|-------------|----------|
| Add .gitkeep placeholders | Create `assets/images/.gitkeep`, `assets/sounds/.gitkeep`, `assets/images/webp/.gitkeep`. Resolves long-standing pub get warnings. | |
| Remove asset declarations | Strip asset entries from pubspec until something is actually committed. | |
| Leave as-is, defer | Out of scope for Phase 1. Defer to whichever phase actually adds assets. | ✓ |

**User's choice:** Leave as-is, defer
**Notes:** Captured in deferred ideas — Phase 4 (launcher icons) or Phase 6 (RIVE) will revisit.

---

## Release signing scaffolding

### Q1: How is key.properties wired into android/app/build.gradle?

| Option | Description | Selected |
|--------|-------------|----------|
| Properties file only | Standard Flutter docs pattern. `android/key.properties` (gitignored) + `android/key.properties.template` (committed). | |
| Properties file + env var fallback | Read `key.properties` first; fall back to env vars (`ANDROID_KEYSTORE_*`). CI-friendly. | ✓ |
| Env vars only | Pure env-var driven. Cleanest CI but worst local DX. | |

**User's choice:** Properties file + env var fallback
**Notes:** Local devs use the file, CI uses env vars — both populate the same `signingConfigs.release` block.

### Q2: When key.properties is missing, what does the build do?

| Option | Description | Selected |
|--------|-------------|----------|
| Skip release config, log warning | No `signingConfigs.release` defined; `flutter build apk --release` fails with readable Gradle error pointing to README. No accidental debug-signed releases. | ✓ |
| Fall back to debug with loud comment | Use debug signing as fallback. Risk: ships exactly the bug INFRA-04 is meant to fix. | |
| Hard fail on missing properties | Refuse to configure project. Breaks `flutter run` for first-time clones. | |

**User's choice:** Skip release config, log warning
**Notes:** This is the explicit fix for the current `// TODO` in `android/app/build.gradle:33-39`.

### Q3: Where does key.properties.template live and what does the README say?

| Option | Description | Selected |
|--------|-------------|----------|
| android/key.properties.template + README section | Template at `android/key.properties.template`. README adds `Release signing` subsection with keytool one-liner + setup steps. | ✓ |
| Template in docs/, no README mention | Put template under `docs/setup/` and reference only in rebase runbook. Less discoverable. | |

**User's choice:** android/key.properties.template + README section

---

## Native customizations to preserve

### Q1: Re-apply android/gradle.properties JVM args (-Xmx4G -XX:MaxMetaspaceSize=2G)?

| Option | Description | Selected |
|--------|-------------|----------|
| Re-apply | Preserve memory tweak. Build performance regression on >8GB RAM machines if dropped. | |
| Accept fresh template default | Take whatever `flutter create` 3.41.5 emits. Easy to re-add per project. | ✓ |

**User's choice:** Accept fresh template default
**Notes:** Pure-rebase posture — customizations re-earn their place per project.

### Q2: Re-apply iOS CADisableMinimumFrameDurationOnPhone (120Hz unlock)?

| Option | Description | Selected |
|--------|-------------|----------|
| Re-apply | Preserve 120Hz unlock. RIVE animations in Phase 6 benefit. | |
| Accept fresh template default | Drop entry. Re-add per-app if 120Hz becomes a requirement. | ✓ |

**User's choice:** Accept fresh template default
**Notes:** Phase 6 RIVE work will revisit if needed.

### Q3: Preserve iOS CFBundleDisplayName = "Skeleton" literal?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep 'Skeleton' literal | Preserve current display name. Bootstrap script in Phase 7 rewrites per-app. | |
| Reset to flutter create default | Use template default driven by `--project-name=skeleton`. Same effective name, routed through template. | ✓ |

**User's choice:** Reset to flutter create default

### Q4: Produce a rebase_manifest.md as a Phase 1 deliverable?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, in .planning/ | Write `.planning/rebase_manifest.md` listing every native edit. Phase 8's full rebase runbook extends it. | ✓ |
| Defer to Phase 8 documentation | Let Phase 8 consolidate from git diff + memory. Risk: lose running list. | |

**User's choice:** Yes, in .planning/
**Notes:** Captures the running list while it's fresh — future Flutter-major rebases re-read it.

---

## Claude's Discretion

- Exact wording of the gradle-config-time warning when both `key.properties` and env vars are missing
- Comment style and content of `android/key.properties.template`
- Section ordering and depth of `.planning/rebase_manifest.md`
- Exact `flutter create` invocation flags beyond the documented baseline
- Whether to align `ios/Flutter/AppFrameworkInfo.plist` `MinimumOSVersion` to 15.0 alongside the Podfile bump

## Deferred Ideas

- Asset directory `.gitkeep` placeholders → Phase 4 or 6
- Re-adding gradle JVM tweak → revisit if build-memory pressure surfaces in Phase 5/6
- Re-adding 120Hz unlock → revisit in Phase 6 if RIVE stutters on ProMotion
- AppFrameworkInfo.plist `MinimumOSVersion` 12.0 → 15.0 → Phase 5 will force if Phase 1 doesn't catch it
- Per-flavor signing configs → Phase 4
