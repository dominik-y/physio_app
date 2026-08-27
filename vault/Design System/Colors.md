# Colors

Source of truth in code: `app/lib/design_system/colors.dart`. This page explains the *why*; change both together.

**Direction: Poliklinika Tendo brand** (rebrand 2026-08-25) — Tendo blue `#0090C3` on cool clinical white, extracted from poliklinika-tendo.com (Wix theme variables + inline logo SVG). Replaces the earlier "Warm Recovery" pine palette; screenshots of both live in `baseline-2026-08-25` / `after-2026-08-25` (pine) and `tendo-2026-08-25` (brand).

## Surfaces

| Token | Hex | Use |
|---|---|---|
| `bg` | `#F5F8F9` | Screen background — cool near-white |
| `surface` | `#FFFFFF` | Cards, rows, inputs |
| `border` | `#D5E0E5` | Hairlines, input borders, empty strip dots. Cards are borderless since the 2026-08-27 MacJack merge — one soft ink shadow (`AppShadows.card`, `text` at 12%) does the lifting |
| `videoBg` | `#03262F` | Session player & single-video page — Tendo's deep petrol |

## Text

| Token | Hex | Use |
|---|---|---|
| `text` | `#03262F` | Primary — Tendo ink (deep petrol), 14.9:1 on `bg` |
| `textMuted` | `#546D7A` | Secondary, labels, section headers — 5.1:1 on `bg` (WCAG AA). The clinic's own `#7494AA` measured 3.0:1 and was rejected |

## Brand

| Token | Hex | Use |
|---|---|---|
| `accent` | `#0090C3` | Tendo blue (the logo color). Fills, gradients, large graphics ONLY — 3.4:1 on `bg`, so never small text and never a background for white text |
| `accentDeep` | `#03607F` | Buttons, text-level accent, selected nav — white on it is 7.1:1 |
| `accentSoft` | `#B5E3F2` | Hero eyebrow, New badge fill, subtle fills |
| `accentTint` | `#E1F2F8` | Tonal secondary-button fill and selected-nav pill (MacJack's light-lavender fill, in Tendo blue). `accentDeep` on it: 6.1:1 |
| `onAccent` | `#FFFFFF` | Text/CTA on accent surfaces |

**Hero gradient:** `accentDeep → accent` at 150°.

## Signals

| Token | Hex | Use |
|---|---|---|
| `warning` | `#B45309` | Skipped exercise — amber, informational, never guilt-red |
| `danger` | `#B3261E` | Patient silence (≥7 days) — reserved for the one thing that demands action |
| `warningSoft` | `#F6E3CE` | Warning chip fill |
| `warningOnDark` | `#F0A44C` | Warning text on `videoBg` (7.7:1) — `warning` itself is only 3.2:1 there |
| `chipText` | `#435862` | Small chip text on `border`-filled chips (5.6:1; `textMuted` fails AA at 12 px) |
| `warningChipText` | `#96450B` | Warning-chip text on `warningSoft` (5.3:1) |
| `dangerSoft` | `#F6D9D6` | Danger chip fill |

## Logo

`app/assets/branding/tendo_logo_light.png` (charcoal + blue, for light surfaces) and `tendo_logo_dark.png` (all-white, for dark). Rendered from the site's inline SVGs at 1200px with transparent background (qlmanage fills white — use the Playwright-chromium render script pattern instead).

## Rules

1. **Danger is scarce.** If red appears more than once per screen, something is misclassified.
2. **Skips are amber, always.** Skipping is honest data, not failure — never style it with `danger`.
3. **One accent.** No secondary hue; hierarchy comes from depth (`accent`/`accentDeep`/`accentSoft`), not new colors. Video-thumb gradients stay in the blue/petrol/teal family (teal is in the clinic's own extended palette).
4. **Brand blue is a fill, not a text color.** Anything textual or carrying white text uses `accentDeep`.
5. Opacity variants use `withOpacity` (Flutter 3.24 — `withValues` doesn't exist).
