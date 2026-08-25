# Potential Complications

Sharp edges we know about, so none of them is a surprise later. Severity is about project impact, not code difficulty.

## High

- **Invite redemption expressed purely in Firestore security rules** (spec §10). It's the riskiest design decision: four-step redemption with no backend. If the emulator tests prove it inexpressible or racy, fall back to a single Cloud Function doing redemption atomically. This is why rules + emulator tests are build-step one of the Firebase phase.
- **Firebase provisioning is interactive.** Blaze billing, project creation, APNs certs later — none of it can be done autonomously. Every Firebase-phase estimate has a "Dominik in the loop" dependency.

## Medium

- **Storage rules can't query Firestore.** Until custom claims exist, any authenticated user can read video files; private videos are protected only by unguessable paths. Acceptable single-tenant, **blocking for a second clinic** — recorded in spec §10 as a prerequisite, not a nice-to-have.
- **Flutter SDK is pinned old (3.24.3 / Dart 3.5.3, ~2 years).** No `Color.withValues`, package ceilings (flutter_bloc 8, go_router 14). Upgrading Flutter later will touch deprecations across the app — do it as its own task with the full test suite as a net, not casually.
- **Client-side compression on old Android devices** may be slow or fail → fallback already designed: upload original with a size warning. Needs a real low-end device test before shipping.
- **Demo→Firebase swap surface.** The repository interfaces were designed for Firestore, but real implementations bring latency, pagination, and error states the demo never exercises. The `Result` type and BloC failure states exist for this; the swap still deserves its own test pass per feature.

## Low / operational

- **Web click double-fire** through the Chrome extension (canvas hit-testing) — cosmetic for demos; use Playwright for scripted runs.
- **`flutter run -d web-server` release build takes ~1 min**; for repeated Playwright runs, `flutter build web --release` once and serve `build/web` statically instead.
- **Demo data resets on restart** — a feature for showcasing, but don't demo "persistence" claims on web.
- **Time-dependence**: all fixtures are generated relative to "now"; a demo run at 00:05 local can look different (today excluded from adherence, hero states). Tests pin `DateTime(2026, 8, 25, 9, 30)`; live demos just need awareness.
- **One clinic hardcoded seed** — `clinicId` is structurally everywhere, but nothing multi-tenant is exercised. Don't promise multi-clinic until §10 tightening lands.
