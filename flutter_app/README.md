# Vanix Flutter app (MyBovine.ai)

Real Flutter implementation of the mobile app, built to match `vanix_screens.html`
/ `vanix_design_system.html` pixel-for-pixel. Those HTML files remain the living
design spec and fast-iteration preview — **this folder is what actually ships.**

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
| Bottom nav (droplet capsule animation) | ✅ Ported — `lib/widgets/vanix_bottom_nav.dart` |
| Dashboard (Home) | 🚧 Placeholder — content not designed yet in HTML either |
| Milk Log (hero, cards, filters, analytics, add/edit) | ❌ Not ported — stub only, see `lib/screens/milk_log_screen.dart` |
| Events (fever/heat/pregnancy flows, reminders, history) | ❌ Not ported — stub only, see `lib/screens/events_screen.dart` |
| Farms list, Cow profile, Account, Farmer persona | ❌ Not designed in HTML yet |

Milk Log and Events are the two screens with the most locked-down interaction
logic (bottom sheets, card-morphing state machines, countdowns). Port them
next, following the same pattern as `login_screen.dart`: one file per screen,
plain `StatefulWidget`s reading `AppState` via `AnimatedBuilder`, no external
state-management package pulled in yet (add `provider`/`riverpod` if the team
prefers before this grows further).

## Structure

```
lib/
  theme/vanix_theme.dart     — design tokens + light/dark ThemeData (canonical Flutter copy)
  i18n/strings.dart          — en/hi/bho strings, mirrors STRINGS in vanix_screens.html
  state/app_state.dart       — dark-mode + language, both persist across every screen
  widgets/
    vanix_bottom_nav.dart    — frosted nav bar, sliding droplet capsule + squish animation
    language_sheet.dart      — searchable language bottom sheet
  screens/
    login_screen.dart        — login/OTP/forgot/reset, all four panels
    dashboard_screen.dart
    milk_log_screen.dart     — stub
    events_screen.dart       — stub
main.dart
```

## Missing assets (must be added before first run)

- **Fonts** — `assets/fonts/NotoSans-{Regular,Medium,SemiBold}.ttf` and
  `NotoSansDevanagari-{Regular,Medium,SemiBold}.ttf`. Download from Google
  Fonts; `pubspec.yaml` already points at these paths.
- **Hero video** — the HTML plays a looping `assets/hero.mp4` behind the
  login sheet before it fades in. `login_screen.dart` has a
  `_HeroBackground` gradient placeholder with a `video_player` TODO comment
  — swap it in once the asset is available (`mybovine.ai` has the source
  clip referenced in earlier project discussion).
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
- The HTML's `resend` cooldown networking is obviously mocked here too —
  wire to a real OTP API when the backend exists.
