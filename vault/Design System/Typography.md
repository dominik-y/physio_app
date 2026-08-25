# Typography

Source of truth in code: `app/lib/design_system/typography.dart`. Brand pairing (rebrand 2026-08-25, matching poliklinika-tendo.com): **Manrope** for all UI text, **Libre Baskerville** for display headings. Both OFL-licensed, bundled as statically-instanced TTFs in `app/assets/fonts/` (instanced from Google Fonts variable files with fonttools — Flutter 3.24 renders variable fonts at default weight otherwise).

**Base rule (spec §7):** everything is one step larger than platform default. The audience is post-surgical and older; 15px body is the floor, not the target.

## Scale

| Style | Face | Size / weight | Use |
|---|---|---|---|
| `heroHeadline` | Baskerville | 24 / w700, height 1.25, onAccent | Hero card number line ("9 remaining") |
| `titleLarge` | Baskerville | 22 / w700 | Page-level names (patient name on detail/home) |
| `screenTitle` | Baskerville | 20 / w700 | AppBar titles |
| `titleMedium` | Manrope | 17 / w600 | Card titles, dialog titles |
| `bodyLarge` | Manrope | 17, height 1.4 | Emphasis body |
| `bodyMedium` | Manrope | 15, height 1.4 | Default body |
| `bodySmall` | Manrope | 13, muted | Subtitles, metadata ("Knee · today") |
| `buttonLabel` | Manrope | 16 / w600 | Primary/secondary buttons |
| `sectionHeader` | Manrope | 12.5 / w700, +1.1 tracking, CAPS, muted | "ACTIVE PROTOCOLS" |
| `eyebrow` | Manrope | 12 / w700, +1.4 tracking, CAPS, accentSoft | Hero "TODAY'S SESSION" |
| `chip` | Manrope | 12 / w600 | StatusChip labels |
| `pillValue` / `pillLabel` | Manrope | 15 w700 / 10 w600 CAPS | DosagePill number and unit |

Serif sizes were stepped down from the old system-font scale (26→24, 23→22, 21→20) because Libre Baskerville runs wide; the 320px overflow sweep verifies the fit.

## Rules

1. **Serif is for display only** — titles a reader glances at, never body, labels, or anything under 20px. Libre Baskerville ships in w400/w700 only; don't ask for w600.
2. **Two tracking styles only** — eyebrow and sectionHeader. Letterspaced caps mean "label", never content.
3. **Weight carries hierarchy, size carries structure.** Don't invent in-between sizes; pick from the scale.
4. **Line height 1.4 on body** text; 1.25 on the serif hero headline (serif needs more air than the old 1.15).
5. **Numbers that update live** (player timer) use tabular figures.
6. Every text in a row layout: `maxLines` + `TextOverflow.ellipsis`. The overflow sweep enforces this at 320px.
