# Vanix — Project Context for Claude

Read this file before doing anything. This is the full project brief.

---

## What is this project?

**MyBovine.ai** is an IoT-powered cattle health monitoring app for dairy farmers in India, built by **Vanix Technologies**. The app tracks cow vitals, heat cycles, insemination, pregnancy, calving, and milk yield via a smart collar device on each cow.

This repo contains the **design system and screen mockups** for the MyBovine farmer mobile app.

- **Mobile app** (this project) — Farm Owner + Farmer personas — built in Flutter
- **Web app** (separate) — Admin + Distributor personas — not in scope here

---

## Personas

| Persona | Platform | Access |
|---|---|---|
| Farm Owner | Mobile | Full access — manages farms, cows, farmers, milk logs, edits entries |
| Farmer | Mobile | Stripped down — logs milk, views assigned cows, receives alerts |
| Vanix Admin | Web only | Not in scope for mobile |
| Distributor | Web only | Not in scope for mobile |

---

## Files in this repo

| File | Purpose |
|---|---|
| `vanix_design_system.html` | Visual design reference — tokens, components, rules. Do not edit casually. |
| `vanix_theme.dart` | Flutter theme file — VanixColors, VanixSpacing, VanixRadius, VanixTextTheme, vanixTheme() |
| `vanix_screens.html` | All screen mockups — this is the active build file |
| `index.html` | GitHub Pages landing page — links to screens + design system |

---

## Design tokens (locked — never change without updating vanix_theme.dart too)

```dart
// Colors
brandGreen   = #4DDE95  // accent only — NEVER on white bg
darkPrimary  = #111111  // dark cards, headers, FAB
darkSecond   = #1C1C1C  // sub-cards on dark
bgWarm       = #F2EDE4  // scaffold bg — always use this, never pure white
bgCard       = #FFFFFF  // card surface
activeBg     = #E8F5EE  // active nav pill, success bg
textPrimary  = #111111
textHint     = #8C8780
textOnDark   = #FFFFFF
border       = #D8D0C5
success      = #4DDE95
warning      = #E8A020
danger       = #D44C3A
greenDeep    = #2EBD7E  // CTA fill (Continue/Confirm) with dark text; input focus accents
greenInk     = #1E7A52  // green as text/icon on white — the only green that passes AA on white

// Spacing (dp)
xs=4  sm=8  md=12  lg=16  xl=20  xxl=24  touch=48

// Radius
xs=4  sm=8  md=12  lg=16  pill=24
```

---

## Typography

- **Latin/English:** Noto Sans (bundled) — weights 400, 500, 600
- **Hindi + Bhojpuri:** Noto Sans Devanagari (bundled, same file for both) — weights 400, 500, 600
- Scale: Display 28/600, Heading 22/600, Subhead 18/500, Body 16/400, Small 14/400, Label 12/500
- Line height: 1.7 for Devanagari body, 1.6 for Latin small

---

## Languages

- Phase 1: Hindi (`hi`) — default, Bhojpuri (`bho`), English (`en`)
- Default locale: Hindi — fallback for any unrecognised Indian locale
- Phase 4 (future): Urdu + RTL — use `EdgeInsetsDirectional` everywhere from day one

---

## Bottom navigation (5 tabs)

| Tab | Hindi | Icon |
|---|---|---|
| Home | होम | house |
| Farms | खेत | cow head (custom) |
| Milk Log | दूध | droplet |
| Events | कार्यक्रम | calendar |
| Account | खाता | user-circle |

- Style: frosted floating bar (rgba(255,255,255,0.42) + blur 18px, radius 36, 16px edge margins), equal-width tabs
- Active: solid white capsule, filled icon + label in greenInk #1E7A52 (the only green allowed as text/icon on white)
- Inactive: 20px dark #111 stroke icon + 11px dark label on frost, no pill
- Badge: red (#D44C3A) — count pill on Events, dot on Home, nowhere else

---

## Cow status lifecycle

`IDLE → HEAT ALERT → IN HEAT → INSEMINATED → PREGNANT → CALVED → MILKING`

- Only **CALVED** and **MILKING** cows appear in Milk Log entry forms
- FEVER is a parallel alert path, separate from heat cycle

## Alert escalation

| Time | Action |
|---|---|
| 0h | Farmer notified (push + in-app) |
| 1h | Escalates to Farm Owner |
| 2h | Farm Owner must act — critical state |
| 6h | Heat cycle confirmed in system |

---

## Screens plan

| # | Screen | Status |
|---|---|---|
| 01 | Login — phone OTP | Done |
| 02 | OTP entry | Pending |
| 03 | Home dashboard (Farm Owner) | Pending |
| 04 | Farms list | Pending |
| 05 | Farm detail (cow list) | Pending |
| 06 | Cow profile (vitals, cycle, yield) | Pending |
| 07 | Milk Log | Done — cream hero (dropdown/download/filter outline buttons), outline banners, date-grouped cards w/ coloured yield box + on-time ✓ / late ⏱ pill, filter bottom sheet, black FAB. Sessions: Morning + Evening only |
| 08 | Add milk entry | Done — same-phone page: farm (owner only) + cow (Name—Breed—Belt no.) + date (no future) + session pills (Evening locked till 17:00 today, past-session warning modal) + litres, Save/Cancel |
| 09 | Edit milk entry (bottom sheet) | Pending |
| 10 | Events / alert centre | Pending |
| 11 | Account | Pending |
| 12 | Farmer persona (stripped views) | Pending |

---

## Rules (always apply these)

- Min tap target: 48×48dp — no exceptions
- Min font size: 14px — 16px for body
- NEVER use #4DDE95 on white — fails WCAG AA
- NEVER use #FFFFFF as scaffold bg — always bgWarm (#F2EDE4)
- ALWAYS use `EdgeInsetsDirectional` not `EdgeInsets.only left/right`
- Farm + Cow fields locked on edit — audit trail required
- Every screen needs an offline state — dark banner, never blank
- Milking sessions are Morning and Evening only — no Afternoon anywhere
- Milk entries: no future dates or future sessions, ever — date picker max = today, Evening locked until 17:00
- Dark mode is app-wide (temporary toggle on Account tab) — every new screen needs dark styles
- Hindi/Bhojpuri strings run 20–40% longer than English — no fixed-width containers
- EVERY visual/component change in `vanix_screens.html` must be reflected in `vanix_design_system.html` (and new tokens in `vanix_theme.dart`) in the same session — the design system is the source of truth

---

## Git setup

- Repo: `git@github.com:vaseey21/Vanix.git`
- GitHub Pages: `https://vaseey21.github.io/Vanix/`
- Auto-push hook in `.git/hooks/post-commit`
- Auto-pull on login via launchd agent (Mac) — do same on Windows
- Always `git pull` before starting work on a new machine

---

## Reference apps

- **MyBovine.ai** (`https://mybovine.ai`) — product being built; logo SVG lives at `/assets/logos/vanix-logo.svg`
- **Starbucks India app** — visual style reference (warm bg, clean cards, bottom nav pill)
