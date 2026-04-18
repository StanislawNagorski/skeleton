# Phase 5: UX Patterns (Onboarding + RIVE Splash + Coach Marks) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 05-ux-patterns-onboarding-rive-splash-coach-marks
**Areas discussed:** Splash handoff flow, Guard ordering & first-run routing, Coach mark UX, Onboarding slide content

---

## Splash Handoff Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed duration (2-3s) | Consistent experience every launch | |
| Init-bound + minimum | Splash stays until init finishes AND minimum elapses | ✓ (later revised) |
| You decide | Claude picks based on RIVE 0.14 best practices | |

**User's choice:** Init-bound + minimum (initially)
**Notes:** Later revised — see "Splash Revision" below.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated SplashRoute | First route in auto_route | ✓ (later revised) |
| Widget overlay above router | Full-screen overlay in MyApp | |
| You decide | Claude picks | |

**User's choice:** Dedicated SplashRoute (initially)
**Notes:** Later revised — see "Splash Revision" below.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Placeholder .riv from RIVE community | Free community .riv as placeholder | |
| No .riv bundled, just the wiring | Ship code but no asset | |
| Simple custom .riv | Minimal custom .riv for skeleton | ✓ |

**User's choice:** Simple custom .riv
**Notes:** This decision stands — the custom .riv moved to the RIVE demo page instead of splash.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Fade out | RIVE animation fades to transparent | |
| RIVE state machine trigger | Outro state machine input triggers exit animation | ✓ (later revised) |
| You decide | Claude picks | |

**User's choice:** RIVE state machine trigger (initially)
**Notes:** Later revised — splash dropped entirely.

---

### Splash Revision (user-initiated)

**User feedback (freeform):** "Nobody likes splash screens, they should be as short as possible or not exist at all. User should land in onboarding. The example RIVE animation should be added to the home screen above the counter. Putting animations on a splash screen is an anti-pattern."

**Revised decision:** No RIVE animated splash. No SplashRoute. Native splash only. RIVE demo on a separate page navigable from Home.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Home page only | RIVE widget on home page, no separate demo | |
| Keep demo screen too | RIVE on home + separate demo screen | |

**User's choice (freeform):** Two screens — Home page with counter and navigation to RIVE demo page. RIVE widget NOT on home page, only on the dedicated demo page.

---

## Guard Ordering & First-Run Routing

| Option | Description | Selected |
|--------|-------------|----------|
| Onboarding first, then auth | Splash → Onboarding → Login → Home | ✓ |
| Auth first, then onboarding | Splash → Login → Onboarding → Home | |
| You decide | Claude picks | |

**User's choice:** Onboarding first, then auth

---

| Option | Description | Selected |
|--------|-------------|----------|
| OnboardingGuard runs first in guards list | Guards: [OnboardingGuard, AuthGuard] | ✓ |
| SplashRoute handles routing decision | SplashRoute checks flag, OnboardingGuard as safety net | |
| You decide | Claude picks | |

**User's choice:** OnboardingGuard runs first in guards list

---

| Option | Description | Selected |
|--------|-------------|----------|
| HomeRoute (guards re-evaluate) | Flip flag, replace to HomeRoute, AuthGuard kicks in | |
| LoginRoute directly | Flip flag, navigate to LoginRoute | |
| You decide | Claude picks | |

**User's choice (freeform):** "Home page should be accessible without login. Why guarding it? Add login as separate option screen."

**Follow-up confirmation:** Home is public. AuthGuard moves from global to per-route. Login is an optional screen accessible from Home. User confirmed: "Yes, exactly."

---

## Coach Mark UX

| Option | Description | Selected |
|--------|-------------|----------|
| On first visit only | Auto-fires once, flag persisted per tourId | ✓ |
| Triggered from help button | No auto-trigger, user-initiated replay | |
| Both: auto + replay button | Auto on first visit + help icon to replay | |

**User's choice:** On first visit only

---

| Option | Description | Selected |
|--------|-------------|----------|
| Just the FAB | Single-target tour | |
| FAB + counter display | Two targets, shows multi-step tours | ✓ |
| You decide | Claude picks | |

**User's choice:** FAB + counter display

---

| Option | Description | Selected |
|--------|-------------|----------|
| Per-screen tours only | Each tour scoped to one screen | ✓ |
| Global tour chain support | Ordered tours across screens | |
| You decide | Claude picks | |

**User's choice:** Per-screen tours only

---

## Onboarding Slide Content

| Option | Description | Selected |
|--------|-------------|----------|
| Generic placeholder content | Title + subtitle + placeholder image per slide | ✓ |
| Skeleton-specific content | Slides explain the skeleton itself | |
| Data-driven slides from config | Slides read from JSON/YAML config | |

**User's choice:** Generic placeholder content

---

| Option | Description | Selected |
|--------|-------------|----------|
| Static illustrations (placeholder images) | Image.asset placeholder per slide | ✓ |
| RIVE animations per slide | Small RIVE animation per slide | |
| You decide | Claude picks | |

**User's choice:** Static illustrations (placeholder images)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Skip jumps to last slide | Animates to final slide first | |
| Skip exits onboarding immediately | Flips flag, navigates to Home | ✓ |
| You decide | Claude picks | |

**User's choice:** Skip exits onboarding immediately

---

## Claude's Discretion

- Exact onboarding placeholder text and image assets
- CoachMarkService internal implementation details
- RIVE Demo page layout and state-machine toggle implementation
- OnboardingGuard reevaluateListenable stream strategy
- Navigation pattern from Home to RIVE Demo
- flutter_native_splash configuration
- AuthGuard refactor approach (per-route guards property vs route metadata)

## Deferred Ideas

- Cross-screen tour sequencing — per-app addition
- RIVE animations in onboarding slides — decided against, per-app option
- Help/replay button for coach marks — per-app addition
- UX-07 (RIVE animated splash with handoff) — explicitly dropped
