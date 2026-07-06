# Vanix Flutter app (MyBovine.ai)

Real Flutter implementation of the mobile app, built to match `vanix_screens.html`
/ `vanix_design_system.html` pixel-for-pixel. Those HTML files remain the living
design spec and fast-iteration preview — **this folder is what actually ships.**

**Standing rule (see root `CLAUDE.md`):** every interaction/visual change made
in `vanix_screens.html` gets ported here in the same session — don't let the
two tracks diverge.

## Getting started

```bash
cd flutter_app
flutter pub get
flutter run
```

You'll need to add the actual font files before it runs cleanly (see
"Missing assets" below) — `pubspec.yaml` already declares them.

## What's ported vs. pending

| Screen | Status |
|---|---|
| Login (email/password) | ✅ Ported — `lib/screens/login_screen.dart` |
| OTP verification | ✅ Ported — same file, `_OtpPanel` |
| Forgot password → OTP → reset password | ✅ Ported — `_ForgotPanel` / `_ResetPanel` |
| Theme toggle (sun/moon pill) | ✅ Ported — `_ThemeToggle` |
| Language bottom sheet (searchable) | ✅ Ported — `lib/widgets/language_sheet.dart` |
| Bottom nav (droplet capsule animation) | ✅ Ported — `lib/widgets/vanix_bottom_nav.dart`, shared across every screen |
| Milk Log — hero, banners, date-grouped cards, filter sheet, FAB | ✅ Ported — `lib/screens/milk_log_screen.dart` |
| Add / edit milk entry — duplicate guard, session warning | ✅ Ported — `lib/screens/milk_add_entry_screen.dart` |
| Milk summary / analytics — breed filter, trend chart, top cows, yield-by-breed | ✅ Ported — `lib/screens/milk_summary_screen.dart` |
| Events — All/Needs-action/Reminders tabs, 12-card P0-P3 alert taxonomy (Cattle Health Logic v3.1), reminders, history | ✅ Ported — `lib/screens/events_screen.dart` |
| "View full cycle" — 7-step bottom-sheet walkthrough of the full breeding/lactation year | ✅ Ported — `_FullCycleSheet` in `lib/screens/events_screen.dart` |
| Events badge/dot sync across every nav | ✅ Ported — `AppState.openEventsCount` + `resolveEvent()` |
| Dashboard (Home) | 🚧 Placeholder — content not designed yet in the HTML either |
| Farms list, Cow profile, Account, Farmer persona | ❌ Not designed in HTML yet — nothing to port |

## Structure

```
lib/
  theme/vanix_theme.dart       — design tokens + light/dark ThemeData (canonical Flutter copy)
  i18n/strings.dart            — en/hi/bho strings, mirrors STRINGS in vanix_screens.html
  state/app_state.dart         — dark-mode, language, and openEventsCount — all persist app-wide
  models/milk_models.dart      — MilkEntry, Cow, seed data matching the HTML's mock values
  widgets/
    vanix_bottom_nav.dart      — frosted nav bar, sliding droplet capsule + squish animation
    vanix_nav_items.dart       — shared 5-tab item builder (keeps badge/dot logic in one place)
    language_sheet.dart        — searchable language bottom sheet
    option_sheet.dart          — generic single-select bottom sheet (used for the period picker)
    milk_filter_sheet.dart     — two-pane filter bottom sheet (Farm / Milking time / Sort by)
  screens/
    login_screen.dart          — login/OTP/forgot/reset, all four panels
    dashboard_screen.dart      — placeholder body, real nav
    milk_log_screen.dart       — hero, banners, date-grouped cards, filter sheet, FAB
    milk_add_entry_screen.dart — add/edit entry, duplicate guard, session-mismatch warning
    milk_summary_screen.dart   — breed filter, 8-week trend (CustomPainter), top cows, yield-by-breed
    events_screen.dart         — tabs, fever/heat/pregnancy action-card state machines, reminders, history
main.dart
```

No state-management package is pulled in yet — every screen is a plain
`StatefulWidget` reading `AppState` via `AnimatedBuilder`. Fine at this size;
reach for `provider`/`riverpod` if the app keeps growing.

## Missing assets (must be added before first run)

- **Fonts** — `assets/fonts/NotoSans-{Regular,Medium,SemiBold}.ttf` and
  `NotoSansDevanagari-{Regular,Medium,SemiBold}.ttf`. Download from Google
  Fonts; `pubspec.yaml` already points at these paths.
- **Hero video** — the HTML plays a looping `assets/hero.mp4` behind the
  login sheet before it fades in. `login_screen.dart` has a
  `_HeroBackground` gradient placeholder with a `video_player` TODO comment
  — swap it in once the asset is available.
- **Logo SVG** — `assets/logos/vanix-logo.svg` is declared in `pubspec.yaml`
  but not present in this folder; copy it from the main repo's `assets/`.
  Rendering an `.svg` needs the `flutter_svg` package (not yet added).

## Design-token parity

`lib/theme/vanix_theme.dart` mirrors the root `vanix_theme.dart` and adds
`vanixDarkTheme()`, which the root file didn't have. **Keep both in sync
when tokens change** — colors, spacing, radius, and text styles must always
match `vanix_design_system.html` exactly (source of truth per `CLAUDE.md`).

## Known gaps vs. the HTML

- Hero video is a gradient placeholder (see above).
- OTP paste-to-fill (pasting a 6-digit code splits across boxes) isn't wired
  — currently only single-digit-per-box typing/auto-advance works.
- Milk Log's filter sheet (farm / session / sort) drives the hero's KPI
  numbers and cow count; it doesn't yet re-filter the date-grouped card list
  below the hero — straightforward to extend, just scoped out this pass.
- Milk summary's clip-path "hero grows into the page" expand animation from
  the HTML is a plain page push here — the visual destination is faithful,
  the transition choreography is simplified.
- The Heat card's 24h pre/optimal/suboptimal countdown is a *real* ticking
  `Timer.periodic`, but compressed 24h → 24 real seconds for demo purposes
  (see the comment above `_simHoursPerSecond` in `events_screen.dart`) —
  swap in the real backend `peak_timestamp` before shipping. The 21-day
  pregnancy watch and 9-month gestation timer are still static/mocked text,
  not real timers.
- No `providers`/persistence: dark mode, language, and all app data reset
  on hot restart (no `shared_preferences` wired up).
- This was hand-written without a local Flutter SDK to compile-check —
  run `flutter analyze` as a first step and fix anything it flags.
