# Tendo × MacJack visual redesign

**Date:** 2026-08-27 · **Branch:** `redesign/tendo-macjack` (worktree `.worktrees/redesign`)

## Goal

Merge two inputs into one visual system for the physio app:

1. **Color scheme — poliklinika-tendo.com.** Already extracted into `app/lib/design_system/colors.dart` (Tendo blue `#0090C3`, deep petrol ink `#03262F`, cool clinical white). Kept as-is, one addition (`accentTint`).
2. **Design system — MacJack app redesign (Figma `X0d33wP6JfDNc9GhbuTjYC`).** Component language reviewed across 30 nodes: cards, buttons, chips, nav, dialogs, inputs, stat tiles, progress, notifications.

Rule of the merge: **MacJack supplies the shapes, Tendo supplies the colors.** MacJack's own hues (`#0047e8` blue, brand red/orange, lime green) are not imported — Colors.md rule 3 (one accent) stands.

## What the MacJack system is (from the Figma library)

- Figtree typeface everywhere; hierarchy by weight (Body 14/500, H3 22/700, Overline 12/600 caps, Amount 34–44/600).
- Borderless white cards, radius ~16–20, one soft drop shadow (`0 4 5 #31363F40`).
- Fully-round pills for everything tappable-and-small: buttons, chips, segmented controls, progress bars.
- Secondary buttons are flat tonal fills (light brand tint, no border).
- Solid brand circular FAB; white bottom nav with tinted pill indicator.
- Dialogs: white, radius ~24, centered icon, full-width pill CTA.
- Inputs: outlined, small floating label sitting on the border.

## Decisions

| Area | Change | Why |
|---|---|---|
| Typeface | Manrope + Libre Baskerville → **Figtree** (400–800, static TTFs) | MacJack is a one-face system; serif display dropped. Sizes keep the app's legibility floor (15px body ≥ MacJack's 14px) — DS voice, not DS metrics |
| Radii | card 13 → **20**; button/chip → **pill (stadium)**; new **tile = 12** for dosage pills, thumbs, inputs | MacJack radius idiom |
| Cards | Border removed; shadow `text` @ 12%, blur 10, offset (0,4) (`AppShadows.card`) | MacJack "card" effect recolored to Tendo ink |
| Primary buttons | Stadium shape; **default bg `accentDeep`** (was `accent`) | Pill idiom; white on `accent` is 3.6:1 — fails AA and violated Colors.md rule 4. Theme-level `FilledButton` default matched |
| Secondary buttons | Outlined → **flat tonal pill** on new `accentTint` `#E1F2F8` (`accentDeep` text, 6.1:1) | MacJack's light-lavender tonal fill, in Tendo blue |
| FAB | `accentSoft` square-ish → **solid `accentDeep` stadium** | MacJack solid-brand FAB; stadium keeps extended FABs a pill (CircleBorder clipped the label — caught in screenshot review) |
| Dialogs | Radius 24, white, transparent tint, bold title | MacJack modal style |
| Inputs | Radius 12 (tile), bold floating label in `accentDeep` | MacJack floating-label idiom |
| Nav bar | Indicator `accentTint` pill | MacJack tinted selected state |
| Hero card | Radius 20, headline w800 | Wallet-card idiom |
| Left alone | Week-strip dots, adherence semantics, layout structure, l10n, spacing scale (already matches DS: 4/8/16/24) | Visual-only branch; structure follows after Dominik's go-ahead |

## Verification

- `flutter analyze` clean; full test suite passes.
- Playwright e2e: **16/16** (mobile 390px + small 320px), no console errors, no overflows at 320px.
- Screenshots regenerated in `e2e/screenshots/{mobile,small}/` against the new build (stale-server pitfall checked — FontManifest confirmed Figtree before trusting shots).
- Vault docs updated: `Design System/Typography.md` (rewritten), `Design System/Colors.md` (accentTint, borderless-card note).
