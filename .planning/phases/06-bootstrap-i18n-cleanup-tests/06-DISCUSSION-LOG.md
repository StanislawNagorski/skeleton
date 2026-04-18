# Phase 6: Bootstrap + i18n Cleanup + Tests - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-18
**Phase:** 06-bootstrap-i18n-cleanup-tests
**Areas discussed:** Bootstrap scope, Test patterns, ARB template switch, Post-bootstrap checklist
**Mode:** --auto (all decisions auto-resolved with recommended defaults)

---

## Bootstrap Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Full rename pass | Dart package, iOS bundle, Android namespace+applicationId, Info.plist, pubspec, README | x |
| Minimal rename | Package name and bundle IDs only | |

**User's choice:** [auto] Full rename pass (recommended default)
**Notes:** Covers all rename targets specified in TOOL-01

---

## Test Patterns

| Option | Description | Selected |
|--------|-------------|----------|
| bloc_test + mocktail + Drift memory | Matches existing stack, established Flutter patterns | x |
| mockito + integration_test | Alternative but requires build_runner for mocks | |

**User's choice:** [auto] bloc_test + mocktail + Drift memory (recommended default)
**Notes:** Aligns with project's existing dependency choices

---

## ARB Template Switch

| Option | Description | Selected |
|--------|-------------|----------|
| Switch to app_en.arb template | EN becomes source of truth, reconcile both files | x |
| Keep app_pl.arb template | Status quo, non-standard | |

**User's choice:** [auto] Switch to app_en.arb (recommended default)
**Notes:** Matches TOOL-04 requirement and industry standard

---

## Post-Bootstrap Checklist

| Option | Description | Selected |
|--------|-------------|----------|
| Print to stdout | Checklist printed after successful run | x |
| Write to file | Generate SETUP.md in project root | |

**User's choice:** [auto] Print to stdout (recommended default)
**Notes:** Matches TOOL-02 requirement

---

## Claude's Discretion

- Bootstrap script internal structure
- Test assertion granularity
- Optional --dry-run flag

## Deferred Ideas

None
