# Ops & Rollout Plan — Tendo Firebase Phase

## 1. Firebase project topology: single prod project + emulator suite

**Recommendation: one Firebase project (`tendo-physio`) plus the local Emulator Suite for all development. No separate dev project.**

Justification against the solo-dev / 2-week reality:

- Every project creation is an **interactive Dominik-in-the-loop event** (Google account, Blaze billing card, region picks). Doubling that doubles the highest-friction step of the whole phase for near-zero benefit.
- The Emulator Suite (Auth + Firestore + Storage + Rules) covers everything a dev project would: rules TDD, repository integration tests, full app runs, seeded data, offline testing. Days 1–8 never touch the cloud at all.
- There are **no real users until ~day 9** (prod cutover) and no destructive-experiment window after that — the risk a dev project exists to absorb doesn't materialize in this timeline.
- The demo build (in-memory fixtures) remains the default and acts as a permanent, zero-cost "staging" environment for UI work.

Guardrails that make single-project safe:

- **Deny-all rules deployed on day 1**, the moment the project exists, before any app is pointed at it.
- The Firebase entrypoint defaults to **emulator mode** (`USE_EMULATOR=true` dart-define default in debug); pointing a build at prod is an explicit, deliberate flag.
- Prod is only touched in three moments: day-1 provisioning, day-9 rules/index deploy + physio provisioning, day 10+ TestFlight builds.

If a second clinic or resale ever happens, spin up a dev project then — the deploy scripts (`firebase deploy --project`) are already project-parameterized, so nothing in this plan blocks it.

## 2. Project creation checklist (day 1, interactive session with Dominik — use the `wizard` skill)

Order matters — Blaze before the Storage bucket, region before anything writes data:

1. Sign into Dominik's Google account; create project `tendo-physio` (Google Analytics: off — not needed, avoids consent complexity).
2. **Upgrade to Blaze immediately** (Dominik's card). EU-region Storage buckets require Blaze, so this precedes step 4.
3. **Budget alerts**: GCP Billing budget at €10 and €50/month with email alerts to Dominik. Expected real spend at this scale: near-zero (inside free-tier quotas); the alert is a tripwire, not a cap — note Firebase has no hard spend cap, the alert email is the control.
4. **Firestore**: create database in **`europe-west3` (Frankfurt)**. This choice is permanent.
5. **Storage**: create the default bucket in **`europe-west3`** (co-located with Firestore; both EU — the region decision is irreversible for both).
6. **Auth**: enable Email/Password provider only. No other providers, no SMS.
7. **Deploy deny-all Firestore + Storage rules** before registering any app.
8. Register apps: **iOS** (bundle id agreed with Dominik, e.g. `hr.tendo.physio`) and **Web**. Android deferred (~3 months per pitch).
9. Run `flutterfire configure` (see §4).
10. Defer: App Check, Crashlytics, Cloud Functions (only created if the rules-only invite redemption fails its emulator tests), Firestore scheduled exports (post-launch hardening, day 13).

## 3. Demo stays default: entrypoint-per-mode, not native flavors, not bare dart-define

**Recommendation: two Dart entrypoints + an injected repository bundle. No iOS schemes, no Android productFlavors.**

- `lib/main.dart` — **unchanged**. Builds `PhysioApp` with the demo repositories exactly as today. `flutter run`, `flutter test`, `flutter build web --release`, and the Playwright suite all use this by default, so **the pitch build stays byte-identical by construction**, not by discipline.
- `lib/main_firebase.dart` — new. `WidgetsFlutterBinding` → `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` → enable Firestore offline persistence (try/catch on web for Safari/private-mode) → optionally `useEmulator(...)` when `const bool.fromEnvironment('USE_EMULATOR', defaultValue: kDebugMode)` → build the Firebase repository bundle → `runApp(PhysioApp(repositories: bundle))`.
- `PhysioApp` (app.dart lines 50–57 seam) gains a `RepositoryBundle` parameter (the five interfaces from `lib/domain/repositories.dart`), defaulting to the demo bundle. app.dart stays flavor-agnostic.

Why not the alternatives:

- **Native flavors**: Xcode scheme + build-config surgery for a solo dev with one real variant is pure overhead, and TestFlight only ever ships the Firebase variant anyway (`flutter build ipa -t lib/main_firebase.dart`).
- **dart-define alone in main.dart**: would force Firebase imports into the default web build (bundle bloat, requires `firebase_options.dart` to exist for every demo build) and makes "demo is untouched" a runtime claim instead of a compile-time fact. Tree-shaking on the `main.dart` target keeps Firebase JS out of the demo web bundle entirely.

Package pins (from platform recon, Dart 3.5.3-compatible, verified mutually compatible): `firebase_core: 3.15.2`, `firebase_auth: 5.7.0`, `cloud_firestore: 5.6.12`, `firebase_storage: 12.4.10`. Pin exact (`=`), not caret — this generation is maintenance-frozen and a resolver bump has nowhere good to go. iOS: raise deployment target to **13.0** (`platform :ios, '13.0'` in `ios/Podfile` + `IPHONEOS_DEPLOYMENT_TARGET` in the Xcode project) — Firebase iOS SDK 11.x requires it; stock Flutter 3.24 projects sit at 12.0.

## 4. FlutterFire CLI & config file layout

- `dart pub global activate flutterfire_cli` (pin the version that still supports firebase_core 3.x if the latest complains; record the working version in the repo README).
- `flutterfire configure --project=tendo-physio --platforms=ios,web --out=lib/firebase_options.dart`
- Files that land, all **committed to git** (Firebase API keys are identifiers, not secrets; security lives in rules):
  - `app/lib/firebase_options.dart` — used by iOS *and* web (web needs no separate file).
  - `app/ios/Runner/GoogleService-Info.plist` — verify it's added to the Runner target in Xcode (flutterfire does this; check once).
- Repo additions at `physio_app/firebase/`: `firebase.json` (emulator ports + rules paths), `firestore.rules`, `firestore.indexes.json`, `storage.rules`, `package.json` (rules tests), `test/` (rules unit tests), `seed/` (emulator seed script + exported fixture data).

## 5. Emulator suite in daily dev

- Tooling: `firebase-tools` via npm (pinned in `firebase/package.json`), **Java 11+ required** for the Firestore emulator — verify on day 1.
- Daily loop: `firebase emulators:start --import=./seed/export --export-on-exit` from `firebase/`. A one-time seed script (Node, using the Admin SDK against the emulator) mirrors `DemoData.seed()` — same six fixture patients, 13 videos, completion history — so the Firebase app boots into a familiar, fully-populated world and every physio/patient screen is exercisable offline.
- Rules TDD: `@firebase/rules-unit-testing` in `firebase/test/`, run with `npm test` against the emulator. This is the **first** code written in the phase (spec §13 order), and the invite-redemption rules get exhaustive tests: happy path, expired code, reused code, wrong-uid race, concurrent redemption.
- App-side integration tests (repository implementations) also run against the emulator via the `USE_EMULATOR` define — kept in a separate `flutter test` directory (`test_firebase/` or tagged) so they never run in the default suite.

## 6. Existing tests stay green — by construction

- **Widget tests (127)**: they inject `DemoStore` directly into `PhysioApp` and never import `main_firebase.dart`. Zero changes. `flutter analyze && flutter test` from `app/` remains the inner loop.
- **Playwright (16)**: builds `flutter build web --release` (default target = `main.dart` = demo). Zero changes. The demo remains the thing the e2e suite pins down, which is exactly right while it's still the pitch artifact.
- **New, additive suites**: `firebase/ npm test` (rules) and emulator-backed repository tests. Full verification loop becomes: `flutter analyze` → `flutter test` → rules tests → `flutter build web --release` → Playwright — the first, fourth and fifth being identical to today.

## 7. CI implications

Currently no CI (vault: nice-to-have, unscheduled). **Recommendation: keep it out of the 2-week critical path.** Everything runs locally and the verification loop is scripted. If/when GitHub Actions lands, the shape is: job A (Flutter: analyze, test, build web, Playwright — no Firebase credentials needed, demo-only) and job B (Node + Java + `firebase emulators:exec 'npm test'` for rules). Nothing in this plan requires secrets in CI because prod deploys stay manual (`firebase deploy` from Dominik's machine, logged in via `firebase login`).

## 8. TestFlight-by-day-10 path

- **Day 1 (or at signature, before day 1 if at all possible): Dominik enrolls in the Apple Developer Program** — individual account, €99/yr, his Apple ID, government-ID verification possible. Approval is usually 24–48 h but can stretch; this is the phase's schedule pacer (see §10).
- Once enrolled: App Store Connect → new app record (name, bundle id `hr.tendo.physio`, primary language Croatian), Xcode automatic signing against his team.
- Build: `flutter build ipa -t lib/main_firebase.dart` → upload via Xcode Organizer or Transporter.
- **Internal TestFlight testing** (no beta review needed, up to 100 testers on the team as App Store Connect users) is the day-10 target — Dominik + clinic director + physios. External testing groups (public-link, requires ~1-day beta review + beta privacy policy) only if the clinic wants wider staff testing later.
- Info.plist prep: `ITSAppUsesNonExemptEncryption = false` (standard-crypto exemption — skips the export-compliance question per build), camera/photo-library usage strings in Croatian (video upload via image_picker), app icon at all sizes.
- Privacy policy URL is required for the App Store listing (post-TestFlight) — Dominik provides a hosted one-pager; not a day-10 blocker for internal testing but needed inside the first term.

## 9. Day-by-day skeleton (see task list for detail)

| Days | Theme |
|---|---|
| 1 | Interactive provisioning (Firebase project + Apple enrollment), emulator suite boots, deny-all rules |
| 2–3 | Rules-first TDD: data model + security rules; **invite-redemption go/no-go on rules-only vs Cloud Function by end of day 3** |
| 4 | Auth end-to-end: entrypoint, auth gate, physio login, invite redemption + account creation (emulator) |
| 5–6 | Five Firestore repositories behind existing interfaces; batch-write side effects; offline persistence |
| 7 | Media: Storage upload + video_compress (720p), URL-on-doc replacing DemoMediaStore call sites, real video_player |
| 8 | Full app wiring pass both roles against emulator; error/latency states; Croatian strings for new screens |
| 9 | Prod cutover: deploy rules+indexes, provision physios, seed real data, device build against prod, invite→signup→assignment integration test |
| 10 | TestFlight upload + internal testers |
| 11 | Real-device shakedown: offline/flaky-network, on-device compression, physio-phone upload |
| 12 | Feedback fixes from Dominik + clinic |
| 13 | Hardening: scheduled Firestore exports (backup), usage/budget review, runbook |
| 14 | Buffer + handoff docs |

## 10. Single riskiest schedule item

**Apple Developer Program enrollment gating TestFlight-by-day-10.** The pitch plan opens the account only at signature; enrollment approval is externally controlled (24 h typical, but ID-verification holds of several days are common) and nothing downstream — App Store Connect record, signing, TestFlight — can start until it clears. Every other risk in the plan has a pre-approved in-repo fallback (invite redemption → Cloud Function; compression failure → upload original), but this one has no technical workaround. Mitigations: start enrollment the moment the director says yes (ideally same afternoon, before day 1 of the build); if it stalls past day 8, demo progress to the clinic via the web build against prod plus an ad-hoc/development-signed install on Dominik's own iPhone while enrollment clears.

The riskiest *technical* item remains rules-only invite redemption — but it is bounded: emulator tests decide it by day 3 and the Cloud Function fallback is pre-approved, costing roughly half a day.