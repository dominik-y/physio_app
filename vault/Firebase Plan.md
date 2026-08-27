# Firebase Plan — canonical (2026-08-26)

The merged, reconciled plan for the 2-week Firebase build. Produced by a 12-agent design workflow (4 designs + adversarial critiques + gap check), then reconciled here. The four full designs live in [[Firebase/Design — Data Model|Data Model]], [[Firebase/Design — Auth, Invites, Rules|Auth/Invites/Rules]], [[Firebase/Design — Media Pipeline|Media Pipeline]], [[Firebase/Design — Ops & Rollout|Ops & Rollout]] — **where a design conflicts with this file, this file wins** (reconciliation decisions in §7).

Starts only after the director says **yes**. Promise: 2 weeks full-time, TestFlight ~day 10.

> **Progress 2026-08-26 (pre-signature, emulator-only — no cloud, no cost):**
> ✅ `firebase/` workspace scaffolded (emulators, vitest, rules-unit-testing)
> ✅ Full rules suite written TDD and GREEN: **49/49** (Blocks A–D incl. split Storage delete, field allowlists, collection-group sealed)
> ✅ **GO verdict: rules-only invite redemption is PROVEN in the emulator** — reuse race, both partial-batch shapes, smuggling, stale-code-after-regenerate all rejected; no Cloud Function needed
> ✅ Day-4 seam refactor done: `RepositoryBundle` (domain) + `demoRepositoryBundle`, `PhysioApp` flavor-agnostic; demo verified byte-identical (analyzer clean, 127 tests, web build, 16/16 e2e)
> ✅ Clinical notes decided physio-only: `patientNotes/{patientId}` collection, patient-denied by rule (owner recommendation, flag if you disagree)
> Run the rules suite: `cd firebase && npm test`
>
> **Progress 2026-08-26 later (still pre-signature, still €0 — Apple enrollment deferred by owner):**
> ✅ FlutterFire pins added + iOS target 13.0; pitch build fully re-verified (simulator build, analyzer, tests, web, 16/16 e2e)
> ✅ Mappers (`app/lib/data/firebase/mappers.dart`) + 7 round-trip tests; VideoItem/ExerciseItem gained nullable media fields (demo untouched)
> ✅ All five `Firestore*Repository` implementations (`firestore_repositories.dart`) — batches for addPatient+invite, regenerate, usageCount, record+lastActiveAt, chunked cascade delete; physio bundle merges `patientNotes`
> ✅ `lib/main_firebase.dart` — emulator-wired entrypoint (`demo-tendo`, dummy options), DEV_LOGIN bootstrap (physio/ana) until the real auth gate lands
> ✅ Admin toolkit (`firebase/admin/`): provision_physio, reset_password, change_email, unlink_patient, delete_user, disable_physio — all exercised against the emulator
> ✅ Date-parameterized emulator seeder (`npm run seed`) — 5 patients in named states, videos/templates/assignments, 3 weeks of completions
> ✅ **End-to-end smoke PASSED**: Firebase flavor on iOS simulator boots; web flavor driven by Playwright shows the seeded caseload, Ana's detail with adherence %, private video, and notes — all streaming live from the Firestore emulator, zero console errors
> Next buildable without money: real auth gate UI (login / invite redemption / password reset / account deletion, Croatian), upload pipeline vs Storage emulator, integration_test suite. Needs money/accounts: real project (day-1 wizard), TestFlight.
>
> **Progress 2026-08-27 (day-5 work done pre-signature, still €0):**
> ✅ **Real auth gate shipped** — DEV_LOGIN is now an opt-in shortcut, the gate is the default: Croatian Prijava (email/lozinka, Zaboravljena lozinka?), "Imam pozivni kod" redemption (create-account → rules-validated 2-doc batch; email-already-in-use falls back to sign-in; orphan Auth user deleted on bad code), notLinked recovery screen, offline-first cached identity (shared_preferences, background refresh), sign-out + patient-only "Izbriši račun" (reauth + delete, App Store 5.1.1(v)) in the avatar menu
> ✅ Architecture: `AuthService` interface (pure Dart) / `FirebaseAuthService` impl / `AuthCubit` with stream suppression during redemption (the create-user auth event must not flash "notLinked"), `TendoFirebaseApp` bootstrap swaps gate ↔ `PhysioApp`; `SessionScope` seam threads patientId/displayName/sign-out into shared UI with demo behavior byte-identical (null session)
> ✅ Tests: 154/154 flutter (11 cubit incl. race + offline cold start, 8 full-stack gate widget tests in Croatian, invite-code normalization), analyzer clean, 16/16 demo Playwright — pitch build untouched
> ✅ **Live emulator smoke 8/8** (`e2e/scripts/auth-smoke.mjs`): physio login → caseload, sign-out, wrong password rejected in Croatian, Luka redeems LK7-3FQ9 (typed sloppy "lk7 3fq9" — normalization works) → lands on his home, **reused code rejected for a second account**, Luka re-login with his new password
> Decisions taken by owner today: web upload YES, Crashlytics YES (§6 updated). Remaining €0 work: upload pipeline vs Storage emulator, integration_test suite, free-provisioning install on the iPhone (task #5).
>
> **2026-08-27 later — architect-critique pass (pre-commit) + iPhone install:**
> ✅ Adversarial review of the auth gate found 4 MAJOR + 4 MINOR, all fixed same day: (1) cache-served empty patient query no longer reads as notLinked (only the SERVER may eject a cached identity — `metadata.isFromCache` → network), (2) stale in-flight resolutions are discarded (`_stale(uid)` guard: no emit, no cache repoison after account switch/sign-out), (3) auth events swallowed during redemption suppression are replayed (`_resyncWithAuth` — a network-dead link batch now lands on notLinked recovery, not a dead login form), (4) physio pages show `session.displayName`, not the hardcoded demo name; plus catch-all → retry screen instead of frozen splash, emit-after-close guards, cache cleared on externally-driven sign-out, gate re-reads locale after in-app toggle. 5 new regression tests → **159/159**, smoke re-run **8/8** post-fix.
> ✅ **Task #5 done**: pitch demo build installed AND launched on Dominik's iPhone via free provisioning (personal team, no paid account). Signature expires ~Sept 3 — rebuild before the pitch if later.
> ⚠️ Known deferred (review follow-ups, fine pre-signature): Firestore `clearPersistence()` on sign-out for shared clinic devices; delete-account dialog + ResolveErrorScreen widget tests.
>
> **Progress 2026-08-27 evening — day-8 media pipeline shipped (still €0, emulator-only):**
> ✅ **Upload pipeline vs the Storage emulator, end to end**: `MediaUploader` seam (XFile-based, pure Dart) + `MediaConfig` (demo: no uploader, 15 s cap / Firebase: real uploader, 90 s cap) injected through `PhysioApp`; `UploadCubit` keeps the demo simulation byte-identical (incl. the "!"-trigger) and drives the same Compressing/Uploading states from real progress when an uploader is present
> ✅ `FirebaseMediaUploader`: mobile = video_compress **Res1280x720Quality** + poster frame + wakelock; web = uncompressed bytes with the 100 MB pre-check (web-upload decision), no poster; explicit contentTypes match the Storage rules
> ✅ **Ordering deviation from the plan sketch — upload-first**: media lands in Storage *before* the video doc exists, so the doc is born `status:'ready'` with matching id and no killed app can strand an 'uploading' doc (kills the retry/delete-stuck-uploads UI scope; orphan Storage files are invisible and admin-sweepable). `status` + assign-flow `isReady` filter kept as defense-in-depth
> ✅ Players are session-aware: real `mediaUrl` threads through library/single-video/session pages and the **assignment item snapshot** (patients never read `videos`); failed loads show "Video je trenutačno nedostupan." + Pokušaj ponovno instead of an eternal spinner; a signed-in session with no URL shows the honest unavailable stage, never the demo fake
> ✅ Tests **173/173** (+ real-path cubit suite with scripted fake uploader, player fallback widget tests, ready-filter + snapshot bloc tests), analyzer clean, demo Playwright **16/16** — pitch build untouched
> ✅ **Live upload smoke 16/16** (`e2e/scripts/upload-smoke.mjs`): Tomislav uploads the 3.46 MB reel through the sheet → bytes verified in the Storage emulator, doc `ready` with URLs → plays for him in a real `<video>` → assigned single to Ana (snapshot carries mediaUrl) → **Ana signs in and watches the actual footage**
> 🐛 Found & fixed (emulator-only): web reload races `connectAuthEmulator` — the JS SDK restores the persisted session against production endpoints with the fake API key, then every auth call bypasses the emulator; web+emulator now forces `Persistence.NONE` (reload = sign in again; real config keeps LOCAL persistence)
> ⚠️ Untested until a device build: the mobile compression path (video_compress needs real hardware — the plan's day-1 on-device smoke; can be pulled earlier by running the Firebase flavor on the iPhone with EMULATOR_HOST pointed at the Mac)
> Remaining €0 work: integration_test suite vs seeded emulator; cache-first playback (day 9). Uploader failure strings are hardcoded Croatian pending the day-12 copy review.
>
> **2026-08-27 night — on-device compression test (iPhone 14 Pro vs emulators over hotspot) + gate UX fixes:**
> ✅ **Real on-device pipeline proven**: owner filmed an 11 s clip on his iPhone → compressed on device → poster + video in the Storage emulator → doc `ready` → **plays back in-app**; progress bars behaved. The plan's day-1 "on-device video_compress smoke" is done early and free.
> 🐛 **Found: iOS compressor emits 720p at ~10 Mbps** (preset controls resolution only, ~6× the cost model; 90 s ≈ 110 MB > the 100 MB rule cap). Interim (owner call): **Storage cap 100→150 MB** (rules 49/49 re-green, client pre-check + hr string updated). Proper fix planned in [[Firebase/Media Bitrate Plan]] — own AVAssetWriter encode at ~2.2 Mbps, paid-phase day 9; cap returns to 100 MB then.
> ✅ Gate UX fixes from owner's device testing: client-side email-format validation (no account-existence disclosure — enumeration), **15 s command timeouts** (30 s redemption; unreachable backend answered in ~30+ s OS-timeout before), spinner inside the busy submit button, fixed-height error slot (killed the ~10 px layout jump on every attempt). Tests **178/178**.
> 🔧 Device-vs-emulator lessons: emulators must bind `0.0.0.0` (firebase.json hosts) + same Wi-Fi (mobile data can't route to a LAN IP; company Wi-Fi may isolate clients — hotspot works: Mac joins phone's hotspot, EMULATOR_HOST=Mac's hotspot IP); `NSLocalNetworkUsageDescription` added to Info.plist; iOS Local Network permission required.

> **2026-08-27 — forgot-password + invite-flow browser audit (Playwright vs :7358) + fixes:**
> ✅ 17-check sweep of both flows. Solid: anti-enumeration "sent" message for unknown emails, all invite validation, **orphan cleanup after a bad code** (created account really deleted), sloppy-code normalization, idempotent re-redemption, dead-code rejection, `emailInUseWrongPassword`, full OOB reset loop (`accounts:resetPassword`).
> 🐛 Fixed: (1) forgot-password skipped the email-shape check → typo'd address got "link sent" (backend swallows user-not-found by design, so the client must catch shape errors); (2) no busy-guard on forgot-password → double-tap sent **2** reset emails (proved via emulator oobCodes; now `_resetBusy` locks all gate buttons, spinner stays on sign-in only); (3) invite weak password now stops client-side (<6 chars, mirrors Firebase minimum); (4) `fieldRequired` copy "Obavezno"→"Ispunite sva polja.". Tests **181/181**, analyze clean, auth-smoke 8/8.
> 🔑 Dev credentials aligned to owner's request: emulator password now **`tendo1`** for tomislav + ana (Firebase hard-rejects 5-char "tendo"); seeder + both smokes updated.
> 🔧 Lesson: rebuilt web on :7358 is masked by Flutter's **service worker** — unregister + clear caches (or hard-reload) before re-testing, or you're testing the old build.

---

## 1. Architecture in five lines

1. **Single Firebase project** `tendo-physio`, everything in **europe-west3** (Frankfurt), Blaze. No dev project — the **Emulator Suite** (Auth+Firestore+Storage) is the dev environment; days 1–8 never touch the cloud.
2. **Demo mode stays the default build by construction**: `lib/main.dart` untouched; new `lib/main_firebase.dart` entrypoint builds a `RepositoryBundle` of `Firestore*Repository` classes implementing the existing interfaces in `domain/repositories.dart` unchanged. The 127 tests + 16 Playwright keep running against demo, proving the pitch build never regresses.
3. **Flat Firestore collections** (`physios`, `patients`, `invites`, `videos`, `templates`, `assignments`, `completions`), every patient-owned doc carries `patientId`. Deterministic completion doc IDs (`{date}_{assignmentId}_{videoId}`) make offline retries idempotent upserts. ExerciseItem denormalization extends to `mediaUrl` — patients never read `videos`.
4. **Auth**: physios = hand-provisioned via admin script + custom claim `role:'physio'`; patients = invite code + email/password, redemption is a **rules-validated 2-doc batch** (`getAfter` cross-check) — emulator-tested FIRST, Cloud Function fallback pre-approved with a go/no-go gate end of day 3.
5. **Media**: physio uploads via `video_compress` → 720p → Storage `clinics/tendo/videos/{videoId}/`, tokened download URL stored on the doc and snapshotted into assignments; **cache-first playback** on patient devices (download once, play from file).

## 2. Verified version pins (Dart 3.5.3 / Flutter 3.24.3 — do not caret)

```yaml
firebase_core: 3.15.2
firebase_auth: 5.7.0
cloud_firestore: 5.6.12
firebase_storage: 12.4.10
video_compress: 3.1.4      # use VideoQuality.Res1280x720Quality — MediumQuality is ~360p!
```

- Latest FlutterFire majors need Dart ≥3.6 — **incompatible** with our pin. This set is the last compatible generation, verified mutually resolvable against this exact toolchain.
- ⚠️ This generation is **maintenance-frozen** (last release mid-2025). Escaping it = Flutter/Dart upgrade, scheduled post-phase against Apple's next SDK deadline (Apple will eventually reject builds from old Xcode/SDK — the pin has a hard external expiry, not a "someday").
- iOS deployment target must be raised **12.0 → 13.0** (`ios/Podfile` + Xcode project).
- `flutterfire_cli` may need an older pinned version to generate configs for core 3.x — verify day 1.

## 3. The ten hard-won corrections (from the adversarial critiques — these are load-bearing)

1. **Test harness**: `cloud_firestore` throws MissingPluginException under plain `flutter test`, and `dart run` scripts can't use the plugin at all. Repository integration tests run via `integration_test` on the macOS target/iOS simulator with `useFirestoreEmulator`; emulator seeding via Node Admin SDK (or emulator REST API) with `now` as a parameter — a **script**, not a static export (fixtures are relative-date-anchored and rot).
2. **Storage rules**: `allow write` covers delete, but `request.resource` is null on delete → every delete denied. Split: `allow create, update` (claim + size + contentType) / `allow delete` (claim only). Test both.
3. **Offline cold start**: ID tokens expire after 1 h; `getIdTokenResult()` offline on an expired token throws → patient can't reach their own cached data. Persist resolved identity (role + patientId) in shared_preferences, route from cache immediately, refresh in background. Airplane-mode cold start is a day-5 test, not day-13.
4. **Redemption failure paths**: catch `email-already-in-use` → fall back to `signInWithEmailAndPassword` → continue to redeem screen; delete just-created Auth user on invalid code; password reset (`sendPasswordResetEmail`) on both sign-in screens; `setLanguageCode('hr')` (stock Croatian templates — body text is NOT customizable, only sender name).
5. **Upload seam**: demo's UploadCubit simulation, "!"-failure trigger, and 15 s cap are pitch behavior covered by tests — inject a `MediaUploader` + max-duration config instead of replacing internals. 90 s cap exists only in the Firebase flavor.
6. **Upload interface**: pass `XFile` (not a String path) — works on web (`putData(bytes)`) and mobile (`putFile`). Web path: no compression, pre-upload size check. **Decision needed on web-upload scope (§6).**
7. **Video readiness**: `status: 'uploading' | 'ready'` on video docs; assign flow filters non-ready videos (else a null `mediaUrl` gets snapshotted into an assignment forever); player renders "video nedostupan" on null/failed URL instead of spinning; retry/delete affordance for stuck uploads; wakelock during upload (iOS kills backgrounded transfers).
8. **Account deletion is mandatory** (App Store Guideline 5.1.1(v)) — any app with account creation gets rejected without in-app delete. Minimal compliant version: patient-side "Izbriši račun" → Auth `currentUser.delete()`; scheduled day 5, not discovered at submission.
9. **PITR on day 1**: client-driven cascade deletes + no undo = one mis-tap destroys a patient's history. Enable Firestore point-in-time recovery (7-day) in the day-1 console session + type-the-name confirm on deletePatient. Weekly backup schedule via `gcloud firestore backups schedules create` (built-in, zero infra — not a hand-rolled export pipeline).
10. **Rules hygiene**: field allowlists on completions (`keys().hasOnly`), `lastActiveAt is timestamp` type check, invites `get`-by-ID-only / `list` denied, collection-group completions denied for patients — all in the emulator test matrix.

## 4. Day-by-day (reconciled single schedule)

**Day 0 (at signature, before the build):** Dominik starts **Apple Developer enrollment** (€99, can take days — this is the single riskiest schedule item, no technical workaround) and the day-1 wizard session is booked.

| Day | Work | Gate/Note |
|---|---|---|
| **1** | Wizard session (~2 h with Dominik): project `tendo-physio`, Blaze + **budget alerts €10/€25/€50**, Firestore + Storage both europe-west3, **PITR on**, bucket soft-delete, Email/Password auth only, Croatian sender name + `hr` language check, **deny-all rules deployed**, register iOS+web apps, `flutterfire configure`. Locally: pins, iOS 13.0, `firebase/` scaffold, emulator suite (Java 11+ check), **on-device video_compress smoke test**, integration-test harness decision proven with one running test. | Nothing starts before this. |
| **2** | Rules test harness (`@firebase/rules-unit-testing` + Vitest) + **redemption tests RED**: happy path, expired, reused, uid mismatch, both partial-batch shapes, extra-field smuggling, stale-code-after-regenerate, concurrent double redemption. | TDD — tests before rules. |
| **3** | Redemption rules GREEN (`getAfter` cross-check) + full matrix (patient isolation, physio scope, field allowlists, collection-group denial) + Storage rules (**split delete**). | **GO/NO-GO**: rules-only unprovable → pivot to callable Cloud Function (+1 day, pre-approved). |
| **4** | Pure refactor, demo-verified: `RepositoryBundle` seam in app.dart, router/role abstraction. Mappers (`toMap`/`fromDoc`, round-trip unit tests, pure Dart). Admin scripts: `provision_physio`, `reset_password`, `change_email`, `unlink_patient`, `delete_user`, `disable_physio`. Node emulator seeder from DemoData shapes. Composite indexes. | Demo suite green same day. |
| **5** | Auth end-to-end vs emulator: `main_firebase.dart`, login (Prijava / Imam pozivni kod), **cached-identity role resolution** (offline cold start test), redemption screen with all failure paths, password reset, **account deletion**, Croatian strings. | |
| **6** | `FirestorePatientsRepository` + invites (addPatient batch, regenerateInvite batch, chunked cascade delete + confirm-by-name). **If Apple enrollment cleared: throwaway TestFlight build of the auth shell** — front-loads all App Store Connect friction. | |
| **7** | Remaining four repositories (assignment-create batch w/ usageCount increments, completion upsert batch w/ lastActiveAt, templates, library) + MediaStore population from snapshots + `ExerciseItem.mediaUrl` field (nullable, demo null). | Demo suite re-run same day. |
| **8** | Media pipeline: `MediaUploader` seam, XFile-based upload, compress **Res1280x720Quality** → poster → Storage → `downloadURL`+`status:'ready'`, assign-flow ready-filter, player error/retry UI + poster backdrop, wakelock. | |
| **9** | **Cache-first playback** (flutter_cache_manager keyed by videoId). Full both-role pass vs seeded emulator; error/latency states; offline drills (airplane session, queued writes, cold start). | |
| **10** | **Prod cutover + TestFlight**: deploy rules+indexes, provision real physios, `flutter build ipa -t lib/main_firebase.dart`, internal testers (Dominik + director + physios). | Contingency if enrollment stalled: web build vs prod + dev-signed install on Dominik's iPhone. |
| **11** | Scripted end-to-end integration test (create patient → invite → redeem → assignment → completion → adherence) + adversarial pass with a second account against **prod** rules + on-device compression timing. | |
| **12** | Real content with the clinic: physios film/upload, real templates, first real patient end-to-end. Croatian review of every new string with Dominik. | Dominik + clinic availability needed. |
| **13** | Hardening: weekly backup schedule, **test-data purge** (keep only the App-Review demo pair), `config/minVersion` forced-upgrade gate, **Crashlytics** (decision §6), usage-vs-estimate check, runbook (provisioning, recovery, invite resend, restore, physio offboarding). | |
| **14** | Buffer (absorbs: Function pivot, TestFlight processing, device bugs). Vault docs to as-built state, demo target re-verified, App Store submission checklist drafted. | |

**Post-phase (first maintenance term, scheduled not vague):** App Store public submission (listing, screenshots, privacy labels, privacy policy URL, ToS/medical disclaimer in Croatian, App-Review demo credentials — invite-only signup means reviewers need a standing demo physio + redeemable invite), web hosting decision, Flutter/FlutterFire upgrade, Android (~3 months per pitch).

## 5. What Dominik must provide (the ask-list)

**Before/at day 1**
- [ ] ~2 h interactive session: Google account, **Blaze billing card**, region confirmations
- [ ] **Apple Developer enrollment started at signature** (Apple ID, €99, possible ID verification)
- [ ] Bundle ID + app display name (suggestion: `hr.tendo.physio` / "Tendo Vježbe")
- [ ] Service-account key custody (his machine only, never committed)

**During the build**
- [ ] Physio roster: names + emails (day 4/10)
- [ ] App icon 1024 px master (day 10)
- [ ] TestFlight tester emails — director + physios as App Store Connect users (day 10)
- [ ] Croatian review of all new auth/redemption/error strings (day 12, extends existing arb review)
- [ ] Clinic support contact (phone/email) shown on account-problem screens
- [ ] Availability days 10–12 for real-human testing; an older iPhone/Android if possible
- [ ] Real clinic videos, or approval to launch with an empty library (day 12)

**Business/paperwork (not code, but real)**
- [ ] Privacy policy URL + Croatian ToS/medical disclaimer (needed for App Store submission, not TestFlight)
- [ ] Data-processing agreement with the clinic + contract clause for **contract-end data handover** (Firestore export + video files, or project ownership transfer)
- [ ] Credential-escrow/bus-factor arrangement (someone besides Dominik can reach the project if he's unavailable)
- [ ] Brief the clinic: invite codes are bearer secrets handed over in person; one email = one patient account

## 6. Open decisions for Dominik (each has a recommendation)

1. **Web upload for physios at launch?** → ✅ **DECIDED 2026-08-27 (owner): yes** — uncompressed with 100 MB pre-check.
2. **`saveTemplate` semantics**: demo is append-only; Firestore `set`-by-id gains update. → Recommend **allow update** (what physios expect).
3. **Clinical `notes` visibility**: under owner-readable patient docs, a technically savvy patient could read the physio's notes. → Recommend **move notes to a physio-only `patientNotes/{patientId}` doc** (small, decided before day-3 rules; avoids an awkward conversation later).
4. **Crashlytics** → ✅ **DECIDED 2026-08-27 (owner): yes**, wired day 13.
5. **Duration cap 90 s** (demo's 15 s was a memory constraint) + Storage backstop **100 MB** (matches the pitched cap — not 150). → Recommend confirm as stated.
6. **Starter content**: pre-create the 3 demo protocol templates with real videos, or start empty. → Recommend **ask the clinic on day 12**.

## 7. Reconciliation decisions (where designs disagreed, resolved here)

- Storage path: **`clinics/tendo/videos/{videoId}/`** (media design) — one-line multi-tenant door-opener, costs nothing.
- Storage size backstop: **100 MB** (matches Pitch Plan), not 150.
- Invite doc fields: **`redeemed` / `redeemedBy` / `redeemedAt`** (auth design's shape — its rules are fully drafted against it).
- Schedule: single merged table above (designs had rules on 2–3 vs repos on 5–8 vs 6–7; merged as rules 2–3, seam+scripts 4, auth 5, repos 6–7, media 8–9).
- "Storage rules can't read Firestore" is **false** (cross-service `firestore.get()` is GA) — claims are chosen for cost/simplicity, and the second-clinic upgrade path is cross-service rules, not a claims migration.
- Accepted single-tenant gap, stated honestly: tokened download URLs bypass all rules; private videos are protected by unguessable IDs + Firestore doc-read rules gating URL disclosure. Hard blocker before clinic #2, fine for Tendo.

## 8. Standing risks (top of mind, full lists in the design notes)

1. **Apple enrollment timing** — the only risk with no technical fallback; mitigated by day-0 start + day-6 early TestFlight + web/dev-signed contingency.
2. **Rules-only redemption unproven in this exact shape** — bounded by the day-3 gate + pre-approved Function fallback.
3. **EOL FlutterFire generation** — no security fixes will land; upgrade scheduled against Apple's SDK deadline, inside the paid maintenance term.
4. **video_compress on real low-end hardware** — day-1 smoke test moves discovery early; fallback = upload original (~5× egress, still <€10/mo at scale).
5. **Days 6–7 are the densest block** (five repositories, three cross-doc batches) — slippage eats the day-14 buffer first.

Cost estimate at realistic scale (100 videos × 30 MB, 30 active patients, cache-first playback): **≈ €2–8/month** — under 5 % of the €170/month fee.
