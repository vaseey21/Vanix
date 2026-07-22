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
| Login (email + OTP, no password) | ✅ Ported — `lib/screens/login_screen.dart` |
| OTP verification | ✅ Ported — same file, `_OtpPanel` |
| Theme toggle (sun/moon pill) | ✅ Ported — `_ThemeToggle` |
| Language bottom sheet (searchable) | ✅ Ported — `lib/widgets/language_sheet.dart` |
| Bottom nav (droplet capsule animation) | ✅ Ported — `lib/widgets/vanix_bottom_nav.dart`, shared across every screen |
| Milk Log — hero, banners, date-grouped cards, filter sheet, FAB | ✅ Ported — `lib/screens/milk_log_screen.dart` |
| Add / edit milk entry — duplicate guard, session warning | ✅ Ported — `lib/screens/milk_add_entry_screen.dart` |
| Milk summary / analytics — breed filter, trend chart, top cows, yield-by-breed | ✅ Ported — `lib/screens/milk_summary_screen.dart` |
| Events — All/Needs-action/Reminders tabs, 14-card P0-P3 alert taxonomy (Cattle Health Logic v3.1), reminders, history | ✅ Ported — `lib/screens/events_screen.dart` |
| Full-screen "push notification" Heat alert (MyGate-style, entry point of View full cycle) | ✅ Ported — `lib/screens/heat_alert_screen.dart` |
| "View full cycle" — 8-step bottom-sheet walkthrough of the full breeding/lactation year | ✅ Ported — `_FullCycleSheet` in `lib/screens/events_screen.dart` |
| Events badge/dot sync across every nav | ✅ Ported — `AppState.openEventsCount` + `resolveEvent()` |
| Events title-tap no longer auto-opens the walkthrough; a dedicated "View full cycle ›" link under the title does instead | ✅ Ported — `events_screen.dart` header row |
| Farm-owner-only card context: Fever/Heat show elapsed unactioned time + farm/manager meta, Heat reads "HIGH" (not "CRITICAL") until it's overdue | ✅ Ported — `_ActionCard.showOwnerContext`/`timeAgo`/`severityLabel` fields, gated on `!AppState.isFarmer` |
| Home's "Cows in heat"/"Cows in gestation" cards open the walkthrough's real full-width alert step instead of a plain Events sheet | ✅ Ported — see Dashboard (Home) row below |
| Icon drift fix pass — Cow Profile overview tiles matched to HTML's icon-free `ovStatCardNoIcon` design (removed the added calendar/thermometer/pets icons), Account nav icon swapped from `account_circle_outlined` (has an extra ring) to `person_outline` to match the plain bust silhouette, added the missing bell+"P1" chip on Heat/Pregnancy/Gestation/Milking-notification cards, Quarterly-vet-check-up reminder icon swapped from a medical-bag glyph to `event_available_outlined` (calendar+check) matching the HTML SVG; Delivery (bottle) and FMD (vaccine) reminder icons checked and already matched | ✅ Ported — `cow_profile_screen.dart` (`_ovStatCard`), `vanix_nav_items.dart`, `events_screen.dart` (`_P1Chip`, `_ReminderCard` icons) |
| Dashboard (Home) — header (logo + farm selector), 6 compact summary tiles (Total Cattle/Cows Pregnant/Cows in Heat/Pending Approvals/Milkings Missed/Unresolved Alerts, the last with an info button opening the per-farm breakdown + Kajri triage sheet), Today/This-week schedule tabs, "Cows in heat" + "Cows in gestation" horizontal-scroll rows, Updates list | ✅ Ported — `dashboard_screen.dart` rebuilt to match Home r2 in the HTML (was stale, pre-redesign 2x2/schedule-tab layout); "Cows in heat" cards push `HeatAlertScreen` then open `_FullCycleSheet` via the new `openFullCycleFlow()` helper (same path as Events' "View full cycle"), "Cows in gestation" cards deep-link into `_FullCycleSheet` at its gestation step via the new `openGestationSliderFlow()` helper (added `_FullCycleSheet.initialStep`) — both helpers now public top-level functions in `events_screen.dart` |
| Farms list — hero (Total Farms/Cattle/Alerts + activity ticker), search + two-pane filter sheet (Status/Location), farm cards (severity tag, chips row), Setup rows | ✅ Ported — `lib/screens/farms_screen.dart` |
| Farm detail (cow list) — temp+level hero, Cattle/Herd Activity tabs, Cattle pane (search + filter sheet Status/Breed/Age, cow cards + kebab), Herd Activity pane (Activity/Cows filter sheet, 4 activity summary tiles, rumination-style graph w/ anomaly pill) | ✅ Ported — `lib/screens/farm_detail_screen.dart` |
| Cow profile — hero (photo/status/temp), Timeline (dots centered on cards, tap-to-expand inline w/ Hide instead of a bottom sheet), Overview (thinner weekly graph + tiles), Vet Logs; floating + actions | ✅ Ported — `lib/screens/cow_profile_screen.dart` |
| Account / Settings — profile row → read-only Profile, Alert-sound toggle, Language + Dark-mode, Legal (Privacy/Terms), Help, Log Out | ✅ Ported — `lib/screens/account_screen.dart` |
| Vet Contacts — invite-link onboarding (Pending/Confirmed/Declined), Add-Vet sheet, per-vet edit sheet | ✅ Ported — `_VetsPage` in `lib/screens/account_screen.dart` |
| Farm Management — 3-option manager chooser (select new / send invite w/ Pending state + Resend/Cancel / assign self), remove manager, per farm; same chooser reachable via a pencil icon on the Farm Detail hero | ✅ Ported — `_FarmMgmtPage` in `lib/screens/account_screen.dart` + `farm_detail_screen.dart` |
| Cattle Groups (Account → Cattle Groups: create groups, add/remove cattle; "Add to group" from a cow's kebab menu in Farm Detail / Cow Profile) | ✅ Ported — `groups_screen.dart` (`GroupsScreen` + `showAddToGroupSheet`), `models/group_models.dart` (`kGroups`); Account row + both cow kebabs wired |
| Events refinements — filter-as-sheet, title-opens-walkthrough, P2/P3 fever-photo + Call-vet cards, past-event detail sheets | 🚧 Partial — Events base ported; these later HTML tweaks not yet reflected |
| Filters v2 (boxless rows, left radio/checkbox, white rail, Reset/Cancel everywhere) | ❌ Pending — HTML done, not yet ported to the Flutter filter sheets |
| Milk summary polish (hero merges w/ page while open, header button stays a filter) | ❌ Pending — HTML done |
| Cow profile v3 — underline tabs, borderless shadowed tiles, kebab Delete-last, colourful Overview v2 (stat cards + green→orange→red temperature line + activity + reminders) | ✅ Ported — `cow_profile_screen.dart` |
| Cow profile Milk Data tab (green area-fill 8-week graph, accent Highest/Lowest tiles, sun/moon session pills, session history) | ✅ Ported — `cow_profile_screen.dart` (`_buildMilkData`) |
| Add Cattle page (photo, type, breed/gender, age, status, belt/MAC, cow-history w/ lactation stepper) | ✅ Ported — `add_cattle_screen.dart`, opened by the Farm Detail + FAB |
| Cow actions sheet — full multi-step flow engine (change status + reason, request vet visit + schedule, add vet log, Heat w/ date+time, Insemination vet→type→log, Pregnancy w/ date, Delivery yes/no→vet→log) | ✅ Ported — `_ActionsSheet` in `cow_profile_screen.dart` |
| Cow profile re-sync pass — hero rebuilt as full-bleed photo (gradient scrim, back/kebab floating over the photo, name·breed·age·temp + gender/battery/status chips on the scrim — the old card hero + separate Status/Current-Temp tiles are gone), kebab now Edit / Add to group / Download Report / Share Report with vet / Delete (report-type full/critical chooser → report-period sheet; share opens a vet picker → toast), and a 5th **Activity** tab split out of Overview (Activity Status tiles + inline day-chip strip + 30-min action rows, same hash-seeded mock as before) — tab order is now Timeline / Overview / Activity / Milk Data / Vet Logs | ✅ Ported — `cow_profile_screen.dart` (`_buildHero`, `_kebab`, `_openReportTypeSheet`, `_openShareWithVetSheet`, `_buildActivity`); new i18n keys in `farm_strings.dart` (`tabActivity`, `downloadReport`, `shareReportVet`, `reportTypeTitle`, `fullReport`, `criticalReport`, `activityLogWord`, `reportSharedWith`) |
| Events inputs-as-sheets (vet picker callback sheet + generic form sheet for Fever/Gestation/P0 flows) | ❌ Pending — HTML done |
| Farmer persona (stripped views) | ✅ Ported — persona toggle on login (`_PersonaToggle`), `AppState.persona`/`isFarmer`/`isSingleFarm`, `FarmerDashboardScreen` (Immediate/To-dos tabs, action rows → Events), single-farm farmer opens Farm Detail directly, owner-only Account sections (Farm Mgmt/Cattle Groups/Vet Contacts) + Farm-Detail manager-edit hidden for farmers. Milk-edit approval workflow ported: farmer edit/delete → pending owner-approval sub-card (no Approve control); owner sees Approve/✕, approve applies + "Updated" badge (`MilkEntry.pendingKind/pendingLitres`, `milk_log_screen.dart`). |

## Structure

```
lib/
  theme/vanix_theme.dart       — design tokens + light/dark ThemeData (canonical Flutter copy)
  i18n/strings.dart            — en/hi/bho strings, mirrors STRINGS in vanix_screens.html
  state/app_state.dart         — dark-mode, language, and openEventsCount — all persist app-wide
  models/milk_models.dart      — MilkEntry, Cow, seed data matching the HTML's mock values
  models/farm_models.dart      — FarmModel, CowModel, VetModel, timeline/vet-log data (kFarms, kVets)
  i18n/farm_strings.dart       — en/hi labels for Farms/Cow/Account (bho falls back to hi)
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
    events_screen.dart         — tabs, fever/heat/pregnancy/gestation/milking action-card state machines, reminders, history
    heat_alert_screen.dart     — full-screen "push notification" style Heat alert
    farms_screen.dart          — Farms list: stat tiles, activity ticker, filter sheet, farm cards
    farm_detail_screen.dart    — cow list: temp/level hero, Cattle/Herd Activity tabs, Status/Breed/Age filters, herd activity summary + rumination graph, kebab
    cow_profile_screen.dart    — Timeline / Overview / Vet Logs tabs + floating actions
    account_screen.dart        — Settings, Profile, Vet Contacts, Farm Management, Privacy/Terms
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
- `_FullCycleSheet` is deliberately self-contained — its own local state and
  its own copy of the Heat countdown timer, separate from `_heat`/`_preg` on
  the main Events screen. Running the walkthrough never calls
  `AppState.resolveEvent()`, so it never decrements the real badge/counter.
- No `providers`/persistence: dark mode, language, and all app data reset
  on hot restart (no `shared_preferences` wired up).
- This was hand-written without a local Flutter SDK to compile-check —
  run `flutter analyze` as a first step and fix anything it flags.
