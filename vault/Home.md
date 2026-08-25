# Physio App — Project Vault

Single place for everything about the physio app that isn't code. The code's truth lives in the repo (`app/`, `docs/superpowers/`); this vault holds working knowledge, decisions and direction.

## Map

- [[Findings]] — what we learned building the showcase (bugs caught, math verified, critique results)
- [[TODO]] — the live task list, by phase
- [[Complications]] — known risks and sharp edges, with mitigations
- [[Documentation]] — how the app is built, how to run and test it
- [[Feature Goals]] — what each feature is for, and the post-MVP roadmap
- [[Design System/Colors]] — palette, usage rules
- [[Design System/Typography]] — type scale, usage rules

## Status (2026-08-25)

**Showcase + design polish + Tendo rebrand complete.** Full app runs in demo mode (in-memory repos, no Firebase): 123 Flutter tests green, analyzer clean, zero overflows at 320/375/430 px, Playwright e2e 12/12 at two viewports with console-error gating. Design pass: 16 critique findings applied, judged before/after, regressions fixed. Rebranded to the real clinic identity (Poliklinika Tendo: blue `#0090C3` on cool white, real logo, Manrope + Libre Baskerville) — see [[Findings]]. Repo is git-initialized, **nothing committed yet** (owner commits explicitly).

Next: the Firebase phase (needs owner-interactive setup).

## Key locations

| What | Where |
|---|---|
| Product spec | `docs/superpowers/specs/2026-08-25-physio-app-mvp-design.md` |
| Implementation plan | `docs/superpowers/plans/2026-08-25-showcase-demo-app.md` |
| Flutter app | `app/` |
| Design system code | `app/lib/design_system/` |
| Domain math | `app/lib/core/adherence.dart`, `app/lib/core/session_engine.dart` |
| Demo fixture | `app/lib/data/demo_data.dart` |
| Mockups (original brainstorm) | `.superpowers/brainstorm/51675-1787643500/content/` |

## External references

- Design skill pack installed at `.claude/skills/` (from github.com/Leonxlnx/taste-skill)
- Design guideline collection (link list, not a skill): github.com/voltagent/awesome-design-md
