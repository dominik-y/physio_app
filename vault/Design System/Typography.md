# Typography

Source of truth in code: `app/lib/design_system/typography.dart`. Rebased on the **MacJack design system** (redesign 2026-08-27): **Figtree** for every text role — the serif display face is gone; hierarchy comes from weight (w700/w800), matching the Figma library. OFL-licensed, bundled as statically-instanced TTFs in `app/assets/fonts/` (Flutter 3.24 renders variable fonts at default weight otherwise).

**Base rule (spec §7) still holds:** everything is one step larger than platform default. The audience is post-surgical and older; 15px body is the floor, not the target. This deliberately sits above MacJack's 14px body — we take the design system's voice, not its metrics.

## Scale

| Style | Size / weight | Use |
|---|---|---|
| `heroHeadline` | 26 / w800, height 1.2, onAccent | Hero card number line ("9 remaining") |
| `titleLarge` | 22 / w700 | Page-level names — MacJack H3 idiom |
| `screenTitle` | 20 / w700 | AppBar titles |
| `titleMedium` | 17 / w600 | Card titles, dialog titles |
| `bodyLarge` | 17 / w500, height 1.4 | Emphasis body |
| `bodyMedium` | 15 / w500, height 1.4 | Default body — MacJack body runs Medium, not Regular |
| `bodySmall` | 13 / w500, muted | Subtitles, metadata ("Knee · today") |
| `buttonLabel` | 16 / w600 | Primary/secondary buttons |
| `sectionHeader` | 12.5 / w700, +1.1 tracking, CAPS, muted | "ACTIVE PROTOCOLS" — MacJack Overline |
| `eyebrow` | 12 / w700, +1.4 tracking, CAPS, accentSoft | Hero "TODAY'S SESSION" |
| `chip` | 12 / w600 | StatusChip labels |
| `pillValue` / `pillLabel` | 15 w700 / 10 w600 CAPS | DosagePill number and unit |

## Rules

1. **One face, five weights** (400–800). Hierarchy is weight + size, never a second family.
2. **Two tracking styles only** — eyebrow and sectionHeader. Letterspaced caps mean "label", never content.
3. **Weight carries hierarchy, size carries structure.** Don't invent in-between sizes; pick from the scale.
4. **Line height 1.4 on body** text; 1.2 on the hero headline.
5. **Numbers that update live** (player timer) use tabular figures.
6. Every text in a row layout: `maxLines` + `TextOverflow.ellipsis`. The overflow sweep enforces this at 320px.

## History

- 2026-08-25: Manrope + Libre Baskerville (Tendo web pairing).
- 2026-08-27: Figtree everywhere (MacJack design system merge; Tendo colors kept).
