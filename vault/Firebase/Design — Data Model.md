# Firestore Data Model & Repository Mapping — Tendo

Scope: one clinic, tens of patients, low-hundreds of videos, thousands of completion docs per year. Everything below is sized for that — flat collections, client-side joins (the blocs already do this), no Cloud Functions on the happy path. The demo build stays the default; Firebase lives behind a second entrypoint.

## 1. Design principles

1. **Flat top-level collections.** No subcollections. Every doc that belongs to a patient carries a `patientId` field. This gives the simplest possible queries (`where patientId ==`), the simplest rules (no collection-group matches), and every physio-side "watch all" stream is a plain collection listen — which is exactly what `watchAll()` / `watchAllByPatient()` need.
2. **Rules-first physio check via custom claim.** Physio accounts are hand-provisioned by an admin script that sets `role: physio` as a custom claim. Rules then use `request.auth.token.role == 'physio'` everywhere — no `exists()` reads, and the same check works in **Storage rules** (which cannot read Firestore). This dissolves the vault's "Storage rules can't query Firestore" blocker for *writes* on day one.
3. **Snapshot-on-assign stays sacred.** `ExerciseItem` denormalization (title, durationSec, bodyPart — and now `mediaUrl`) means patients never read `videos` or `templates`. Rules deny both to non-physios outright.
4. **Deterministic completion doc IDs** (`{date}_{assignmentId}_{videoId}`) are the Firestore document ID. `set()` on that ID is a natural idempotent upsert — double-taps, offline retries, and queued writes all collapse to last-write-wins on one doc.
5. **Invite redemption is a rules-validated client batch** (design below). Cloud Function fallback is pre-approved if emulator tests disprove it.

## 2. Collections

### `physios/{authUid}` — doc ID = Firebase Auth uid
| field | type | notes |
|---|---|---|
| name | string | |
| email | string | display only; Auth is source of truth |
| createdAt | timestamp | |

Created by the provisioning script alongside the Auth user + custom claim. Read: any physio. Write: nobody from the client (script only).

### `patients/{patientId}` — auto-ID
| field | type | notes |
|---|---|---|
| name, email | string | |
| uid | string \| null | null = invite not redeemed; set exactly once by the redemption batch |
| notes | string | default '' |
| primaryBodyPart | string \| null | |
| lastActiveAt | timestamp \| null | updated by the completion-record batch |
| inviteCode | string \| null | denormalized copy of the active invite (physio UI shows it; the redemption rule uses it to locate the invite doc) |
| inviteExpiresAt | timestamp \| null | |
| createdAt | timestamp | |

### `invites/{code}` — doc ID = the formatted code, e.g. `LK7-3FQ9`
| field | type | notes |
|---|---|---|
| patientId | string | |
| expiresAt | timestamp | createdAt + 14 days |
| createdAt | timestamp | |
| usedBy | string \| null | auth uid of redeemer; the "used" latch |
| usedAt | timestamp \| null | |

Code space: 7 chars from a 31-char alphabet ≈ 2.7 × 10^10 — unguessable enough that "any signed-in user may `get` a single invite doc by ID" is acceptable (no listing allowed).

### `videos/{videoId}` — auto-ID
| field | type | notes |
|---|---|---|
| title, bodyPart | string | |
| durationSec | int | |
| visibility | string | 'library' \| 'private' |
| privateToPatientId | string \| null | |
| usageCount | int | maintained by the assignment-create batch (`FieldValue.increment`) |
| createdAt | timestamp | |
| **storagePath** | string | `videos/{videoId}/{file}.mp4` — new field, Firebase-only |
| **mediaUrl** | string \| null | Storage download URL, written after upload completes; null while uploading |
| **status** | string | 'uploading' \| 'ready' — physio UI can show in-flight uploads |

Patients never read this collection.

### `templates/{templateId}` — auto-ID
`name`, `bodyPart`, `items` (array of maps: videoId, order, sets, reps, holdSec), `createdAt`. Physio-only.

### `assignments/{assignmentId}` — auto-ID
| field | type | notes |
|---|---|---|
| patientId | string | equality-filter key |
| type | string | 'protocol' \| 'single' |
| name | string | |
| sourceTemplateId | string \| null | provenance only |
| bodyParts | array<string> | |
| daysOfWeek | array<int> | ISO 1..7, sorted |
| items | array<map> | ExerciseItem: videoId, order, sets, reps, holdSec, overridden, **title, durationSec, bodyPart, mediaUrl** — full snapshot incl. playback URL |
| active | bool | |
| seenByPatient | bool | patient may flip false→true, nothing else |
| createdAt | timestamp | |

`mediaUrl` is snapshotted into each item at assign time (read from the video doc the physio already has in memory). Storage download URLs are token-stable; if a video is ever re-uploaded, new assignments pick up the new URL — old assignments keep working because the storage object is only deleted, never overwritten (new upload = new videoId path).

### `completions/{date}_{assignmentId}_{videoId}` — deterministic ID
| field | type | notes |
|---|---|---|
| patientId | string | equality-filter key (assignmentId is patient-unique, so the ID is globally unique) |
| date | string | 'YYYY-MM-DD', **local** — unchanged from demo; the ID embeds it |
| assignmentId, videoId | string | |
| status | string | 'done' \| 'skipped' |
| at | timestamp | |

Append-only in spirit; the only "update" is the idempotent upsert of the same doc ID.

## 3. Auth, roles, and role gate

- Physio: email/password created by Dominik's admin script (`firebase-admin` Node or Dart script): creates Auth user, sets `{ role: 'physio' }` custom claim, writes `physios/{uid}`.
- Patient: self-creates email/password account during invite redemption (below). No claim.
- App role resolution at startup: `token.claims.role == 'physio'` → physio UI; otherwise query `patients where uid == auth.uid limit 1` → patient UI (doc absence = redemption incomplete → back to redemption screen). This replaces the demo `RoleGate` in the Firebase flavor; demo keeps its toggle.

## 4. Invite redemption — the rules-validated batch (highest-risk piece, emulator-tested first)

Client flow (patient app):
1. Patient enters code + email + password.
2. `createUserWithEmailAndPassword` → `auth.uid`.
3. `get(invites/{CODE})` → validate client-side (exists, `usedBy == null`, `expiresAt > now`) → learn `patientId`.
4. One `WriteBatch`:
   - update `invites/{CODE}`: `{ usedBy: auth.uid, usedAt: serverTimestamp() }`
   - update `patients/{patientId}`: `{ uid: auth.uid }`

Rules make the batch atomic-and-honest:

```
match /invites/{code} {
  allow get: if signedIn();                       // by-ID only, never list
  allow update: if signedIn()
    && resource.data.usedBy == null
    && resource.data.expiresAt > request.time
    && request.resource.data.usedBy == request.auth.uid
    && request.resource.data.diff(resource.data).affectedKeys()
         .hasOnly(['usedBy', 'usedAt']);
  allow create, delete: if isPhysio();            // regenerateInvite
}

match /patients/{pid} {
  // redemption: claim yourself, exactly once, only if this same batch
  // consumed the invite this patient doc points at
  allow update: if signedIn()
    && resource.data.uid == null
    && request.resource.data.uid == request.auth.uid
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['uid'])
    && getAfter(/databases/$(database)/documents/invites/$(resource.data.inviteCode))
         .data.usedBy == request.auth.uid;
}
```

`getAfter()` sees the post-batch invite state, so the patient update is only legal inside a batch that also marked the invite used by the same uid. **Race safety:** two devices redeeming the same code concurrently — Firestore serializes the commits; the second batch sees `usedBy != null` and the invite-update rule rejects the whole batch. No partial states are possible (batch atomicity). Emulator tests to write *before* any client code: happy path; expired code; already-used code; wrong-uid mismatch between the two writes; patient-update without invite-update in the batch; extra-field smuggling; concurrent double redemption. If any of these can't be made to pass, fall back to a single callable Cloud Function doing the same in a transaction (pre-approved).

`regenerateInvite` (physio batch): delete old `invites/{oldCode}` if present, create `invites/{newCode}`, update patient `{inviteCode, inviteExpiresAt}`. Returns the code from the client-generated value (7 chars, alphabet `ABCDEFGHJKMNPQRSTUVWXYZ23456789`, formatted `XXX-XXXX`) — collision chance negligible, but do a `get` first and reroll on the (astronomically unlikely) hit.

## 5. Repository → Firestore mapping

All `Firestore*Repository` classes implement the existing interfaces in `lib/domain/repositories.dart` unchanged (one small extension noted in §10). Every `watch*` maps to `.snapshots()` — which emits the current (cached) value immediately on listen, matching the demo `Watchable` behavior-subject semantics, so blocs' `combineLatest` wiring is untouched. Every write is wrapped `try/catch → Ok/Err` preserving the `Result` contract; error messages localized at the UI layer as today.

| Interface method | Firestore operation |
|---|---|
| `PatientsRepository.watchPatients()` | `patients` orderBy `createdAt` `.snapshots()` |
| `.watchPatient(id)` | `patients/{id}.snapshots()` → null when missing |
| `.addPatient(name, email)` | batch: create `patients/{auto}` + create `invites/{code}` (a new patient always gets an invite, mirroring demo) |
| `.updateNotes(id, notes)` | `update({notes})` |
| `.regenerateInvite(id)` | batch per §4; returns new code |
| `.deletePatient(id)` | client-side cascade: query `assignments where patientId==id` + `completions where patientId==id` (+ invite doc), delete in chunked `WriteBatch`es of ≤450 ops, then the patient doc last. Storage objects for private videos left for a later sweep (metadata gone → unreachable) |
| `LibraryRepository.watchVideos()` | `videos` orderBy `createdAt` `.snapshots()` (physio-only screen) |
| `.addVideo(...)` | create `videos/{auto}` with `status:'uploading'`; §10 covers the file itself |
| `TemplatesRepository.watchTemplates()` | `templates` orderBy `createdAt` `.snapshots()` |
| `.saveTemplate(t)` | `templates/{t.id}.set(...)` — **note: this silently gains update semantics vs the demo's append-only; confirmed acceptable? (flagged to Dominik)** |
| `AssignmentsRepository.watchForPatient(pid)` | `assignments where patientId == pid` orderBy `createdAt desc` `.snapshots()` |
| `.watchAll()` | `assignments` orderBy `createdAt desc` `.snapshots()` |
| `.create(a)` | `WriteBatch`: create assignment + `FieldValue.increment(1)` on each referenced **library** video's `usageCount` (private videos too — matches demo recompute). Physio-only, so plain rules |
| `.markSeen(id)` | `update({seenByPatient: true})` — patient-writable via the field-mask rule |
| `CompletionsRepository.watchForPatient(pid)` | `completions where patientId == pid` `.snapshots()`; client sorts |
| `.watchAllByPatient()` | `completions` (physio-only) `.snapshots()` → group by `patientId` in the mapper. Fine at this scale; when it grows, add `where date >= cutoff` (last ~10 weeks covers every adherence view) — composite index already provisioned |
| `.record(pid, c)` | `WriteBatch`: `completions/{c.id}.set(map)` + `patients/{pid}.update({lastActiveAt: c.at})`. Patient-side rules: completion doc ID must equal `date + '_' + assignmentId + '_' + videoId` from its own data, `patientId` must resolve to `auth.uid` (via `get(patients/$(patientId)).data.uid`), and the patient-doc update is field-masked to `lastActiveAt` only |

Mappers live in `lib/data/firebase/mappers.dart` — pure `toMap`/`fromDoc` per model, round-trip unit-tested without any emulator (enums→strings, `Set<int>`→sorted array, `DateTime`↔`Timestamp`, `Completion.date` stays a string).

## 6. Security rules summary

| collection | physio (claim) | patient (auth, no claim) |
|---|---|---|
| physios | read | — |
| patients | read/write all | read own doc (`resource.data.uid == auth.uid`, equality-filtered query); update own `lastActiveAt` (field-masked); redemption update per §4 |
| invites | create/delete/read | `get` by ID only; redemption update per §4 |
| videos | read/write | **none** |
| templates | read/write | **none** |
| assignments | read/write | list/read `where patientId == own` (rule does one `get()` on the patient doc to check uid); update field-masked to `seenByPatient: true` |
| completions | read all; no writes needed (physio never records) | list/read/write own per §5 `record` rule |

Storage: `match /videos/{videoId}/{file}`: write `if request.auth.token.role == 'physio' && request.resource.size < 100 * 1024 * 1024 && request.resource.contentType.matches('video/.*')`; read `if request.auth != null` (unguessable path is the acknowledged single-tenant-acceptable protection for private videos; see §12).

## 7. Composite indexes (`firestore.indexes.json`, committed)

1. `assignments`: `patientId ASC, createdAt DESC`
2. `completions`: `patientId ASC, date ASC` (future date-bounded adherence queries; cheap to provision now)

Everything else is single-field auto-indexed. `firestore.rules`, `storage.rules`, `firestore.indexes.json`, and `firebase.json` (with emulator config) live in a new `firebase/` directory at repo root, next to a small npm package holding the `@firebase/rules-unit-testing` suite.

## 8. Offline persistence

- Mobile: Firestore disk persistence is **on by default** in cloud_firestore 5.6.x — nothing to enable. All patient-side queries are single-collection equality filters (`patientId ==`, `uid ==`) which serve fully from cache; a patient who opened the app once can run entire home + session flows in airplane mode.
- Offline writes: `record()` batches queue and replay; the deterministic doc ID makes replayed retries idempotent. `markSeen` and `lastActiveAt` are last-write-wins by nature.
- One UX rule: never `await` a write before updating UI state on the patient side — with the server unreachable, the Future doesn't complete until reconnect. Blocs should treat the local snapshot echo (which arrives immediately) as the confirmation; `Result.Err` is reserved for rule rejections/immediate failures.
- Web: wrap `enablePersistence()` in try/catch (Safari private mode falls back to memory); single-tab mode is fine.
- Video files are NOT offline — `mediaUrl` is a network URL. Acceptable per vault ("offline downloads only on complaint"); the session page must show a Croatian "no connection — video unavailable" state rather than a spinner.

## 9. Media pipeline & the synchronous `DemoMediaStore` problem

`DemoMediaStore.urlFor(videoId)` is synchronous and consumed outside repositories. Rather than rewriting call sites, the Firebase repositories **feed the same store**: `FirestoreLibraryRepository.watchVideos` registers `videoId → mediaUrl` as video snapshots arrive (physio side), and `FirestoreAssignmentsRepository.watchForPatient` registers each item's snapshotted `mediaUrl` (patient side). Since every screen that plays a video is already downstream of one of those streams, the store is always populated before `urlFor` is called. Rename to `MediaStore`; the `asset:` scheme for the bundled reel keeps working in demo.

Upload flow (physio): pick file → `video_compress` to 720p (fallback: original + size warning if compression fails) → `addVideo` creates the doc (`status:'uploading'`) → `putFile` to `videos/{videoId}/video.mp4` with progress → on success `update({mediaUrl, status:'ready'})`. **Small interface extension needed:** `LibraryRepository.addVideo` gains an optional `String? localFilePath` (demo impl keeps registering the blob/file URL in MediaStore and ignores upload) — the one interface change of the whole phase.

## 10. Fixtures, seed, and what production gets

- **Demo fixtures never touch production.** They are fake patients with fabricated medical context.
- A `tool/seed_emulator.dart` script reuses `DemoData.seed(now)` + the §5 mappers to populate the **emulator** (Firestore + Auth users incl. claim for the fixture physio) — giving instant realistic data for dev, integration tests, and the rules suite's fixture layer. This doubles as a proof that mappers cover every model.
- Production day-1 content: physio accounts via the provisioning script, real videos uploaded by physios, real templates created in-app. Optionally pre-create the 3 demo protocol *templates* with real videos if the clinic wants starters — Dominik's call, trivial either way.

## 11. Demo/Firebase coexistence (flavor seam)

- New `RepositoryBundle` value class holding the five repository interfaces (+ MediaStore hook). `PhysioApp` takes the bundle instead of constructing `Demo*` itself; `lib/main.dart` (default target, untouched behavior) builds the demo bundle exactly as today — demo build, e2e suite, and pitch flow stay byte-identical in behavior.
- `lib/main_firebase.dart`: `Firebase.initializeApp()` (options from `flutterfire configure`), builds the Firestore bundle, adds the auth gate ahead of the router. Run with `flutter run -t lib/main_firebase.dart` (and a proper `--flavor` for iOS bundle IDs when TestFlight time comes: `hr.tendo.physio` prod vs demo).
- Package pins (verified compatible with Flutter 3.24.3 / Dart 3.5.3): `firebase_core: 3.15.2`, `firebase_auth: 5.7.0`, `cloud_firestore: 5.6.12`, `firebase_storage: 12.4.10`. iOS `Podfile` platform bump to 13.0. These lines are maintenance-frozen — a Flutter upgrade later unlocks current majors and is its own scheduled task.
- Verification loop unchanged: `flutter analyze` → `flutter test` (127 + new mapper/repo tests) → `flutter build web --release` → Playwright 16 — all against the **demo** target, proving Firebase work never regresses the pitch build.

## 12. Second-clinic paragraph (one, as promised)

Resale to clinic #2 should be a **second Firebase project**, not a `clinicId` field: `flutterfire configure` per client flavor, same codebase, zero data-model changes, hard isolation, per-clinic billing visibility on Dominik's card. The only genuine code work it forces is what's already flagged: Storage *read* rules must move from unguessable-paths to enforced access (patient custom claim or short-lived signed URLs via one Cloud Function), and the provisioning script grows a `--project` flag. Nothing in this document needs `clinicId` today, and adding it prematurely would put a dead field in every rule and mapper.
