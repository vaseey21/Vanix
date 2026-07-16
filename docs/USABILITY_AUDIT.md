# MyBovine.ai — Usability Audit (Mobile App)

**Scope:** Farmer + Farm Owner mobile app (HTML prototype `prototype.html` / `vanix_screens.html` + Flutter `flutter_app/`).
**Method:** Heuristic evaluation (Nielsen's 10) + WCAG 2.1 AA + low-literacy / rural-India context + review against the project's own locked rules (CLAUDE.md).
**Severity:** 🔴 Critical (blocks/mis-leads) · 🟠 Major (friction, likely errors) · 🟡 Minor (polish).

---

## Executive summary

The product is strong on its core promise — picture-first, one-action alerts in the farmer's language, warm daylight-readable UI, and a coherent alert taxonomy. The biggest opportunities are **visual consistency** (typography scale and left/right margins drift screen-to-screen), **persona clarity** (owner vs farmer capability is not yet reflected in the UI), and a handful of **accessibility and feedback** gaps. None of the findings undermine the concept; they are execution polish that materially affects trust for a low-literacy audience.

| Area | Score (5) | Headline |
|---|---|---|
| Learnability / low-literacy fit | 4.5 | Picture-first cards + icon+label are excellent |
| Visual consistency | 3.0 | Type scale + margins drift; needs tokens |
| Consistency & standards | 3.5 | Strong patterns, some one-off variants |
| Error prevention & recovery | 4.0 | Good guards (dates, duplicates); some silent states |
| Accessibility (WCAG/AA) | 3.5 | Palette rules good; tap targets + focus need checks |
| Feedback & visibility of status | 3.5 | Good badges; some actions lack confirmation |

---

## 1. Visual consistency — typography (🟠 Major)

The client explicitly flagged inconsistent font sizes. The prototype sets sizes inline per-element, so the same semantic role renders at different sizes across screens:

- **Page/hero titles:** Farm name 21 px, Cow name 18 px, sheet titles 18 px, Account section headers 19 px, dashboard stat numbers 30 px vs 26 px vs 24 px vs 22 px.
- **Subtitles / secondary lines:** 13 px, 12 px and 11 px all used for the same "supporting line" role.
- **Section labels:** 12 px uppercase in some places, 11 px in others.
- **Body / values:** 16, 15, 14 px mixed for equivalent content.

**Recommendation — adopt the documented type scale as the *only* allowed sizes** (already defined in CLAUDE.md): Display 28/600, Heading 22/600, Subhead 18/500, Body 16/400, Small 14/400, Label 12/500. Map every element to one role, define utility classes (`.t-heading`, `.t-subhead`, `.t-body`, `.t-small`, `.t-label`) and replace inline sizes. In Flutter, route everything through `TextTheme`. This single change resolves the "titles should all be the same, subtitles the same" requirement.

## 2. Visual consistency — margins & alignment (🟠 Major)

Client flagged uneven left/right margins. Observed:

- Screen gutters vary: 16 px on most pages, but hero cards, sheets (24 px) and some lists use different insets, so content edges don't line up vertically as the user scrolls.
- Back-chevron optical alignment: the Farm-Detail back button was inset differently from the right-edge element (fixed this pass to 16/16); the same audit is needed on every pushed page (Cow Profile, Add Cattle, Account sub-pages).
- Right-edge controls (filter buttons, kebabs, temp readouts) don't share a consistent right margin with the content below them.

**Recommendation — one horizontal gutter token (16 dp) for all page content**, applied at a single wrapper; sheets keep 24 dp but their *inner* content aligns to the same 16 dp content column. Verify every back button sits the same distance from the left as the trailing element sits from the right.

## 3. Persona clarity (🔴 Critical for the persona work)

Owner-only capabilities (Farm Management, Cattle Groups, Vet onboarding, milk-edit **approval**, multi-farm dashboard) are currently visible regardless of who is logged in, and the Farmer's simplified action-first Home does not yet exist. For the key (Farmer) persona this is misleading — it offers actions they cannot complete.

**Recommendation** (tracked build): gate every owner-only surface behind the role flag; give the Farmer the Immediate/To-dos Home; make farmer milk edits submit as **pending requests** with a clear "waiting for owner" state rather than showing approve controls.

## 4. Feedback & visibility of status (🟠 Major)

- Several list-level actions (kebab → Edit/Delete, "Assign to me") change state with no toast/confirmation; a low-literacy user can't tell it worked.
- The alerts badge and "All clear" state are good; extend that pattern — every destructive or state-changing action needs an explicit, localized confirmation.
- Offline state: CLAUDE.md mandates a dark offline banner on every screen; confirm it renders on the new farmer Home and all sub-pages.

## 5. Error prevention & recovery (🟡 Minor–🟠)

- **Strong:** milk future-date/session locks, duplicate-entry guard, mandatory reason on status change — keep these.
- **Gap:** destructive actions (Delete cow, Remove manager, Cancel invite) lack an "are you sure?" for a population prone to mis-taps; add confirm dialogs.
- **Gap:** no undo on milk delete / status change beyond the approval queue.

## 6. Accessibility (🟠 Major)

- **Contrast:** palette rules are correctly enforced (no #4DDE95 on white; greenInk for text). Re-verify amber `#8A5A00`/warning text on tinted chips meets AA.
- **Tap targets:** most CTAs meet 48×48; audit small kebab (32 px) and info (26 px) buttons — pad the hit area to 48.
- **Focus / screen-reader:** add semantic labels to icon-only buttons (back, kebab, info, filter) for TalkBack; ensure the picture-first cards expose their question + answer buttons as accessible text.
- **Text scaling:** verify Devanagari at 1.3× line-height doesn't clip in fixed-height chips (Hindi/Bhojpuri run 20–40% longer — CLAUDE.md rule; some chips use fixed heights).

## 7. Consistency & standards (🟡 Minor)

- Filter sheets were unified (good). A few one-off button shapes remain (pill radius 17 vs 18 vs 22/24). Standardise: pill = 24, chip/tab = 17–18, and document it.
- Icon stroke widths vary (1.6–2.5). Pick one (2.0) for UI glyphs.

## 8. Navigation & information scent (🟡 Minor)

- The dashboard-is-home / overlay-pages model works but "return resets to Home" can disorient when deep-linking from an alert. Consider preserving the origin tab.
- Farmer Home action buttons should deep-link to the *specific* event card, not the Events list, to keep the "one tap to act" promise.

## 9. Content & localization (🟡 Minor)

- Icon+label pass is applied to Events; extend to the remaining sentence-length UI (P0 vet-flow copy, Milk session pills + litres) per the pending list in CLAUDE.md.
- Bhojpuri strings need native-speaker review; several are transliterations of Hindi.

---

## Prioritized fix list

| P | Finding | Effort |
|---|---|---|
| 🔴 | Build & gate Farmer vs Owner persona (Home, hidden sections, milk-request-pending) | High |
| 🟠 | Normalise type scale to the 6 documented roles (utility classes / TextTheme) | Medium |
| 🟠 | Single 16 dp content gutter; audit every back-button alignment | Medium |
| 🟠 | Confirmation/toast on every state-changing & destructive action | Medium |
| 🟠 | A11y: 48 dp hit areas, semantic labels on icon buttons, chip text-scaling | Medium |
| 🟡 | Standardise radii, icon stroke widths | Low |
| 🟡 | Deep-link farmer Home actions to the specific event card | Low |
| 🟡 | Bhojpuri copy review | Low |

---

## What's already excellent (keep)

- Picture-first illustration alert cards and the Text/Image display mode — best-in-class for low-literacy comprehension.
- Warm `#F2EDE4` background and daylight-readable contrast.
- Single evolving Heat→Insemination 24-hour card.
- Milk-log guards (no future dates, Evening lock, duplicate guard).
- Frosted floating nav with the sliding capsule.
- Consistent, unified two-pane filter sheets.
