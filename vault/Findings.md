# Findings

What building the showcase actually taught us — kept because each of these would cost time to rediscover.

## Verified working (with evidence)

- **Adherence math is honest.** Ana's 91% = 51 done of 56 scheduled occurrences (14 days × 4 exercises, bridge missed every 3rd day), recomputed by hand against the UI. Today is excluded from the denominator until the day ends; a brand-new assignment shows `—`, never a punishing 0%.
- **Skips are a first-class signal.** A skip renders amber on both the patient hero strip and the physio's week strip the moment it happens; "skipped heel slides every day this week" (Marko fixture) reads at a glance.
- **Snapshot-on-assign holds.** Editing dosage for one patient never mutates the template (deep-copy verified by bloc test); template edits never rewrite live prescriptions.
- **Live cross-role sync.** Assigning a protocol as physio → patient hero updates instantly with a New chip; completing a session as patient → physio's list shows today's dot instantly. All through `Watchable` streams, no polling.
- **Resume semantics.** Per-exercise persistence: doing 2 of 3 and closing the app resumes at the first unrecorded exercise the same day; next day resets in full. Deterministic completion ID (`{date}_{assignmentId}_{videoId}`) makes double-taps and retries overwrite instead of inflating adherence.

## Bugs caught before they shipped

1. **Josip silence off-by-one** — history generator used an exclusive bound, making him 10 days silent instead of 9. Caught by fixture invariant test.
2. **Video picker overflow** — `private` chip overflowed 15px at 320px width. Caught by the 3-size overflow sweep; fixed with `Flexible`.
3. **`Color.withValues` doesn't exist on Flutter 3.24** — 17 analyzer errors; replaced with `withOpacity` everywhere.

## Multi-agent critique results (25 findings, 4 lenses)

Highest-value catches that changed the build:
- `Stream.multi` alone can't merge repo streams → built `combineLatest2/3/4` in `core/streams.dart` (races/leaks otherwise).
- New badges on protocols had no clearing path → `SessionBloc` marks contributing assignments seen on session start.
- Duplicate video in one assignment would collide completion IDs → constructor assert + picker guard.
- Singles must NOT merge into the guided session (spec §5.1) — hero counts protocols only.
- DST: date iteration must step calendar days, never `add(Duration(days: 1))` (Croatia flips 2026-03-29 / 2026-10-25). Tests cover both transitions.

## Design polish pass (2026-08-25, multi-agent)

3 critique lenses → 16 findings → all applied → 2 before/after judges → 3 flagged regressions → fixed and re-verified. Before/after screenshots live in `Design System/baseline-2026-08-25` vs `after-2026-08-25`.

What changed, and why it stays:
- **Session player**: video now *fills* the leftover height (`DemoVideoPlayer(fill: true)`) — the judges caught that merely top-anchoring it just relocated the dead space.
- **Contrast**: `textMuted` darkened to `#7A6F61` (4.6:1, WCAG AA) — the old value measured ~4.0:1 at 13px, below AA for the older audience.
- **One-accent discipline**: video thumb gradients restricted to pine/olive/sage; the purple and maroon pairs were a silent second and third accent.
- **Cards**: soft warm shadow (`text` @ 5%, blur 10) — `surface` vs `bg` differ ~2% in luminance, so borders alone didn't read as "tappable card".
- **Patients list**: FAB clearance padding (96px), FAB themed `accentSoft`/`accentDeep`, triage dots 10px (9px under 360px width — the judge-caught lesson: bigger dots stole name width on small phones; **trailing elements must yield to names**).
- **Type discipline**: stray 16/15.5/13.5px styles replaced with scale tokens; pill-label tracking unified at 1.1.
- **Small persuasions**: inset footer divider in the dosage editor, session-complete block raised to the upper third, soft trailing captions on short screens ("That's everything for today…"), error snackbars in `danger` (success stays pine), secondary "also assigned" cards lightened (and the `private` chip fill moved to `border` so it survives on the lighter card).

**A11y bug found by Playwright, worth remembering:** Flutter 3.24's web engine dropped the entire hero-card subtree from the semantics tree (empty group + unlabeled button). Fixed with an explicit `Semantics(label:)` + `ExcludeSemantics` pair in `hero_card.dart`. Rule of thumb: signature composite widgets get explicit semantics labels; don't trust engine auto-derivation.

## Tendo rebrand (2026-08-25)

The app now wears the real clinic brand, extracted directly from poliklinika-tendo.com without any special access:

- **Logo**: the site is Wix and serves the logo as inline SVG in the HTML — pulled both variants (full-color + all-white) straight from the page source. Rendered to transparent PNGs with Playwright chromium (`omitBackground: true`); **qlmanage fills the background white even when the PNG reports an alpha channel** — don't use it for transparent renders.
- **Palette**: taken from the Wix theme's `--color_N` variables, then contrast-checked. Two clinic colors failed WCAG AA and were replaced with derived steps: their muted blue-gray `#7494AA` (3.0:1) → `#546D7A` (5.1:1), and brand blue `#0090C3` as a text/button color (3.4–3.6:1) → deep petrol `#03607F` (7.1:1 under white text). Brand blue survives as fills, gradients, and large graphics.
- **Fonts**: the site pairs Libre Baskerville (headings) with Manrope (body). Both are OFL on Google Fonts but ship as variable fonts, which Flutter 3.24 renders at default weight — statically instanced the needed weights with `fonttools varLib.instancer` and bundled the TTFs. Serif title sizes stepped down one notch (Baskerville runs wide); overflow sweep stayed green.
- Verified after the swap: analyzer clean, 123/123 tests, Playwright 12/12 at both viewports. Screenshots in `Design System/tendo-2026-08-25`.

## Automation quirks (not app bugs)

- Chrome-extension clicks sometimes double-fire on Flutter web canvas; widget tests tap once and all guards held there. Playwright behaves better for scripted testing.
- Flutter web renders to canvas → DOM-based assertions are useless; test via screenshots, console errors, and coordinate clicks (or enable Flutter semantics for accessibility-tree testing).

## Pitch-week sprint (2026-08-25, autonomous session)

**Croatian localization** — full gen-l10n (ARB en+hr, ICU plurals with hr one/few/other), Croatian default, persisted 🇭🇷/🇬🇧 toggle (role gate + role menu), fixtures translated (exercise names, protocol names, clinical notes). Convention: button labels use short ti-imperative (Croatian app standard, per Google hr), helper/descriptive text uses formal vi — flagged by review as "mixed", kept deliberately.

**15 s demo video import** — image_picker (gallery/camera) + video_player; duration probed via a throwaway controller, capped at 15 s (`demoImportMaxSec`); in-memory `DemoMediaStore` maps videoId→blob/file URL; `DemoVideoPlayer` transparently swaps to `RealVideoPlayer` when media exists. Library rows became tappable (full-screen player).

**Multi-agent review (32 agents: 6 finders × flows/320px/desktop/a11y/Croatian/code + adversarial verifiers)** — 26 findings, 11 confirmed-worth-fixing. Fixed:
- Empty protocol name could create blank-titled protocol + template cards → submit disabled until named
- "Uđi kao fizioterapeut" ellipsized at 320 px (first tap of the demo) → maxLines 2
- Desktop stretch: no max content width anywhere → shared `ContentColumn` (720 px) on all list screens
- Patient-detail CTA below the fold → pinned bottom bar (learned: a plain `Center` in `bottomNavigationBar` expands to fill the scaffold and zero-heights the body — use `Center(heightFactor: 1)`)
- Session controls full-bleed vs centered video → constrained to 560
- "Preskoči ovu" 3.2:1 on dark → new `warningOnDark` #F0A44C (7.7:1); chip text contrast fixed via `chipText` #435862 / `warningChipText` #96450B
- Croatian terms: zadržaj→**izdržaj**, Donja leđa→**Donji dio leđa**, "Dr." dropped (physios aren't Dr. in Croatia → "Tomislav Perić, mag. physioth."), "Novo zaduženje"→"Novi program vježbi"
- a11y: role cards announced as buttons, close/play/pause got labels, dosage-pill labels FittedBox (PONAVLJANJA clipped at 320)
- LocaleCubit unit tests added (default/restore/toggle/fallback)

**E2E gotcha**: tapping by short labels ("EN") matches substrings case-insensitively ("ENter as physio") — tap toggles by their semantic label instead.

Verification after everything: analyzer 0 · 127 Flutter tests · 16/16 Playwright (two viewports) · iOS simulator build green (ios/ scaffolded with Croatian permission strings, display name Poliklinika Tendo).

Known/parked: VideoFrame GC console warning from video_player on web (benign, not tripping the console gate); locale persistence is fire-and-forget; DateFormat relies on Intl.defaultLocale (fine while locale switching also sets it).

## Tendo reel + simulator (2026-08-25 evening)

- Reel #8 ("PRESEASON MODE ON", instagram.com/reel/DZHhLgLNDGE) pulled via logged-in Chrome session: Instagram serves separate DASH tracks (VP9 video + AAC audio) — sniffed both mp4 CDN URLs from network requests, stripped `bytestart/byteend` params to get full files, muxed + transcoded with ffmpeg to H.264 720p (VP9 does NOT play on iOS AVPlayer). Bundled at `app/assets/videos/tendo_reel8.mp4`, seeded as library video `v-tendo-drill` ("Agilnost — rad s loptom"), registered in `DemoMediaStore` at app init.
- **Gotcha:** `video_player` web has no asset source — on web, bundle assets must load as network URLs (`assets/<key>`). `RealVideoPlayer` handles the split (`asset:` scheme → networkUrl on web, VideoPlayerController.asset on device).
- **Gotcha:** `flutter create --platforms=ios .` left a stale empty `web_plugin_registrant.dart` — web builds threw "init() has not been implemented" from video_player. Fix: `rm -rf .dart_tool/flutter_build` and rebuild.
- **Gotcha:** python `http.server` ignores Range headers; swapped the demo server on :7357 to `npx http-server` (206 support) for video playback.
- App runs on the iPhone simulator (`xcrun simctl install/launch com.tendo.physioApp`) with the reel playing natively.

## Owner feedback round (2026-08-25 late)

- **Swipe-to-delete patients** — Dismissible (endToStart) on patient cards, red delete background, Croatian confirm dialog; `deletePatient` added to PatientsRepository (removes patient + assignments + completions). Gotcha: on web, Dismissible merges the card into one label-only semantics node and the tap action disappears — wrap the child in `Semantics(container: true, explicitChildNodes: true)`.
- **Daily-workload guard removed** (spec §4.6 two-tap confirm) on owner call — SubmitPressed submits directly; warning text + "Svejedno potvrdi" gone from UI and ARB.
- **Patient detail densified** — toolbar 44px, list top padding 0; header now sits right under the back arrow, protocols/singles/notes above the fold.
- Hero-card dots = last-7-days week strip (done/skipped/empty, today rightmost) — owner asked what they mean; candidate improvement: tiny legend or day initials.

