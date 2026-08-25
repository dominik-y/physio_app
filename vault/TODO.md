# TODO

The live list. Checked = done and verified.

## Now — design polish pass (2026-08-25)

- [x] Install taste/design skills into `.claude/skills/`
- [x] Create this vault
- [x] Split design system: `colors.dart` + `typography.dart` (code) and [[Design System/Colors]] + [[Design System/Typography]] (docs)
- [x] Playwright harness (`e2e/`): semantics-driven, 12 tests × 2 viewports, console-error gate, screenshots — found & fixed hero a11y bug (empty semantics group)
- [x] Multi-agent design critique (3 lenses, 16 findings) → all applied: session player top-anchored, FAB clearance + themed, tonal video thumbs, WCAG-AA muted text, card shadows, type-scale cleanup, inset dividers, soft empty-space anchors, error snackbars in danger, bigger triage dots
- [x] Re-run: `flutter analyze` clean, 123 Flutter tests green, Playwright 12/12 on rebuilt bundle
- [x] Before/after screenshots into vault (`Design System/baseline-2026-08-25` vs `after-2026-08-25`)

## Waiting on Dominik

- [ ] **First git commit** — repo is initialized, nothing committed (explicit "commit" required)
- [ ] Decide when to start the Firebase phase (needs his Google account + Blaze billing, interactive)

## Firebase phase (next, spec §13 order)

- [ ] Firebase project + Blaze + emulator suite
- [ ] Security rules with emulator tests FIRST (invite redemption via rules is the highest-risk piece; Cloud Function is the named fallback)
- [ ] Real auth: physio login, patient signup, invite redemption end-to-end
- [ ] Firestore repository implementations behind existing interfaces
- [ ] Storage + client-side compression (`video_compress`, 720p target) + real `video_player`
- [ ] Swap `DemoVideoPlayer` behind the same widget contract
- [ ] Integration test: invite → signup → redeem → see assignment

## Post-MVP (spec §11)

- [ ] Push notifications (first thing after MVP — needs Cloud Function + APNs)
- [ ] Pain scores / session logging (`completions` doc is already shaped for it)
- [ ] Storage rule tightening via custom claims — **blocking prerequisite for any second clinic**
- [ ] Offline downloads — only if someone actually complains

## Nice-to-have hygiene

- [ ] Consider CI (GitHub Actions: analyze + test on push) once repo has a remote
- [ ] Golden tests for design-system components once design settles
