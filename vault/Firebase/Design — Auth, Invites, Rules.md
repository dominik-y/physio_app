# Auth, Invite Redemption & Security Rules — Design

## 1. Summary of decisions

| Decision | Choice | Why |
|---|---|---|
| Physio provisioning | **Admin script** (firebase-admin, Node), not console | Console cannot set custom claims; script is repeatable, documented, and doubles as the account-recovery tool |
| Role model | **Hybrid: custom claim for physios, document-link for patients** | Storage rules cannot read Firestore, so physio-only upload *requires* a claim; patients cannot get claims without Admin SDK/Functions, so patient identity = `uid` written onto their `patients/{id}` doc by the rules-governed redemption batch |
| Invite redemption | **Rules-only, no Cloud Functions** — atomic 2-doc batched write cross-checked with `get()`/`getAfter()` | Feasible with the documented getAfter pattern; keeps MVP at zero Functions (no cold starts, no deploy pipeline, no Node runtime maintenance). Cloud Function fallback pre-approved if emulator tests disprove it (decision checkpoint end of day 3) |
| Cross-doc side effects (usageCount, lastActiveAt, cascade delete) | Client-side batched writes, permitted by rules | Same "zero Functions" principle; all are performed by the party rules already trust |
| Collections layout | Flat top-level collections (`patients`, `invites`, `videos`, `templates`, `assignments`, `completions`, `physios`) with `patientId` fields | Mirrors the demo repositories and domain model 1:1; single rules pattern; `watchAll`/`watchAllByPatient` are plain collection listens |
| Patient video access | **None to Firestore `videos`**; playback via tokened download URL stored on docs | ExerciseItem already denormalizes video metadata (spec 4.7); `DemoMediaStore.urlFor` is synchronous, so the URL must live on the doc, not behind an async Storage call |
| Email verification | **Not required** | The invite code is the gate; verification adds friction for non-technical patients. Typo'd email is recoverable via admin script (see §10) |

Firebase project: single project, `europe-west3`, Blaze. Auth provider: **Email/Password only** (no SMS, no anonymous, no OAuth). Email enumeration protection: left **on** (default) — UI shows generic Croatian errors.

## 2. Firebase Auth setup

- Enable Email/Password sign-in only.
- Auth emulator + Firestore emulator + Storage emulator in `firebase/firebase.json` from day 1; all rules work happens against emulators first.
- Croatian email templates (password reset, email change) configured in console: sender name "Poliklinika Tendo"; client calls `FirebaseAuth.instance.setLanguageCode('hr')` at startup.
- Authorized domains: add the web-hosting domain when known.
- App Check: deferred post-MVP (noted in risks).
- Pinned packages (verified compatible with Flutter 3.24.3 / Dart 3.5.3): `firebase_core: 3.15.2`, `firebase_auth: 5.7.0`, `cloud_firestore: 5.6.12`, `firebase_storage: 12.4.10`. iOS deployment target must be raised to 13.0 in `app/ios/Podfile`.

## 3. Physio provisioning (admin script)

`firebase/admin/` (Node + firebase-admin, auth via service-account key kept only on Dominik's machine, never committed):

- `provision_physio.mjs <name> <email>` — creates Auth user with a generated temp password, sets custom claim `{ role: 'physio' }`, creates `physios/{uid}` profile doc (`name`, `email`, `createdAt`). Prints temp password once; physio changes it at first login via the normal password-reset email (script triggers `generatePasswordResetLink` so no password ever travels by chat).
- `reset_password.mjs <email>`, `change_email.mjs <old> <new>` — the account-recovery toolkit (§10).
- Claims are read from the ID token; a physio provisioned *before* first sign-in needs nothing special. If a claim is ever changed on a live session, the client must call `getIdToken(true)`; otherwise propagation takes up to ~1 h.

Patients are **never** provisioned by script — they self-create at redemption.

## 4. Role resolution in the client

On `authStateChanges`:
1. Signed out → login screen (tabs: "Prijava" / "Imam pozivni kod").
2. Signed in → `getIdTokenResult()`; `claims.role == 'physio'` → physio shell.
3. Otherwise → query `patients where uid == myUid limit 1`:
   - found → patient shell (patientId from the doc);
   - empty → **redeem screen** ("Unesite pozivni kod"). This screen is what makes orphaned accounts (crash between signup and redemption) self-healing — redemption is retryable by any signed-in, unlinked user.

This replaces the demo `RoleCubit` in the Firebase flavor; demo mode keeps it untouched.

## 5. Data model additions (Firebase-only; demo unchanged)

- `invites/{code}` — **doc ID is the invite code** (7 chars, alphabet `ABCDEFGHJKMNPQRSTUVWXYZ23456789`, stored without the display dash: `LK73FQ9`; UI formats `LK7-3FQ9`). Fields: `patientId`, `expiresAt` (Timestamp, +14d), `redeemed: false`, `redeemedBy: null`, `redeemedAt: null`, `createdAt`, `createdBy` (physio uid), optional `displayName` (patient first name for the welcome screen). Code space ≈ 31⁷ ≈ 2.7 × 10¹⁰ — unguessable at auth-throttled rates.
- `patients/{patientId}` — domain model + `uid: null` (written **explicitly null**, never absent — rules rely on `== null`), `inviteCode` (current code, authoritative), `inviteExpiresAt` (mirror for physio UI).
- `physios/{uid}` — profile only; role lives in the claim.
- `videos/{videoId}` — domain model + `storagePath`, `downloadURL` (tokened Firebase download URL). At assign time the physio client snapshots `downloadURL` into each `ExerciseItem`, so patients resolve playback URLs synchronously from the assignment doc (replaces `DemoMediaStore` call sites).
- `completions/{id}` — deterministic ID `{date}_{assignmentId}_{videoId}` (globally unique because assignmentId is), field `patientId` added.

`regenerateInvite(patientId)` (physio, one batch): create `invites/{newCode}`, delete `invites/{oldCode}` if any, update patient `inviteCode`/`inviteExpiresAt`. Because the patient-side redemption rule validates against `patients.inviteCode` via `getAfter`, an old leaked code becomes dead the moment a new one is issued even if its doc briefly survived.

## 6. Invite lifecycle end-to-end

1. **Physio** creates patient → app writes `patients/{id}` (uid: null) + `invites/{code}` in one batch. Physio hands the code to the patient privately (in person at the clinic — it is a bearer secret).
2. **Patient** installs app, opens "Imam pozivni kod", enters **code + email + password in one form** (pre-auth code validation is impossible because `invites` reads require auth — this is deliberate, it keeps invites unreadable to unauthenticated bots).
3. Client: `createUserWithEmailAndPassword` → `get(invites/{code})`:
   - not found / `redeemed` / expired → **delete the just-created Auth user** (`user.delete()`, allowed since login is seconds old), show a specific Croatian error ("Kod je iskorišten ili je istekao — javite se svom fizioterapeutu").
   - valid → show "Dobrodošli, {displayName}" and commit the **redemption batch**:
     - `update patients/{invite.patientId}`: `{ uid: myUid }` (only field)
     - `update invites/{code}`: `{ redeemed: true, redeemedBy: myUid, redeemedAt: now }`
4. Rules enforce atomicity in both directions (each side `getAfter`-checks the other — see §7), so a partial batch is impossible and the whole thing commits or rejects as one.
5. Client routes to patient home; assignments stream in (and offline-persist).

**Stolen/reused code:** the second redeemer's batch fails the `redeemed == false` and `uid == null` preconditions — Firestore evaluates rules against committed state at commit time, so two concurrent redemptions serialize and exactly one wins. **Crash mid-flow:** orphan Auth account, handled by the redeem-again screen (§4). **"Email already in use":** UI offers "Prijavite se pa unesite kod" — sign in, land on redeem screen.

## 7. Firestore security rules

Full access matrix (P = physio via claim, O = owning patient via uid-link, ✗ = denied):

| Collection | get | list | create | update | delete |
|---|---|---|---|---|---|
| `patients` | P, O | P; O only with `uid == auth.uid` filter | P | P; O: redemption transition OR `lastActiveAt`-only | P |
| `invites` | P; any signed-in user if unredeemed & unexpired | P only | P | P (revoke); signed-in: redemption transition | P |
| `videos` | P | P | P | P | P |
| `templates` | P | P | P | P | P |
| `assignments` | P, O | P; O with `patientId` filter | P | P; O: `seenByPatient: true` only | P |
| `completions` | P, O | P; O with `patientId` filter | O (own, valid shape, deterministic ID) | O (same — upsert) | P (cascade) |
| `physios` | P | P | ✗ (admin script only) | ✗ | ✗ |

Rules (the load-bearing parts, `firebase/firestore.rules`):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    function signedIn() { return request.auth != null; }
    function isPhysio() { return signedIn() && request.auth.token.get('role', '') == 'physio'; }
    function pat(pid) { return get(/databases/$(db)/documents/patients/$(pid)).data; }
    function ownsPatient(pid) { return signedIn() && pat(pid).uid == request.auth.uid; }
    function onlyKeys(keys) {
      return request.resource.data.diff(resource.data).affectedKeys().hasOnly(keys);
    }

    match /patients/{pid} {
      allow get: if isPhysio() || (signedIn() && resource.data.uid == request.auth.uid);
      allow list: if isPhysio() || (signedIn() && resource.data.uid == request.auth.uid);
      allow create, delete: if isPhysio();
      allow update: if isPhysio()
        || (signedIn() && resource.data.uid == request.auth.uid && onlyKeys(['lastActiveAt']))
        || redemption();

      function redemption() {
        return signedIn()
          && resource.data.uid == null
          && request.resource.data.uid == request.auth.uid
          && onlyKeys(['uid'])
          && resource.data.inviteCode != null
          && get(/databases/$(db)/documents/invites/$(resource.data.inviteCode)).data.redeemed == false
          && get(/databases/$(db)/documents/invites/$(resource.data.inviteCode)).data.expiresAt > request.time
          && getAfter(/databases/$(db)/documents/invites/$(resource.data.inviteCode))
               .data.redeemedBy == request.auth.uid;   // batch MUST also mark the invite
      }
    }

    match /invites/{code} {
      allow get: if isPhysio()
        || (signedIn() && resource.data.redeemed == false && resource.data.expiresAt > request.time);
      allow list, create, delete: if isPhysio();
      allow update: if isPhysio() || redeem();

      function redeem() {
        return signedIn()
          && resource.data.redeemed == false
          && resource.data.expiresAt > request.time
          && request.resource.data.redeemed == true
          && request.resource.data.redeemedBy == request.auth.uid
          && onlyKeys(['redeemed', 'redeemedBy', 'redeemedAt'])
          && getAfter(/databases/$(db)/documents/patients/$(resource.data.patientId))
               .data.uid == request.auth.uid;          // batch MUST also link the patient
      }
    }

    match /videos/{vid}     { allow read, write: if isPhysio(); }
    match /templates/{tid}  { allow read, write: if isPhysio(); }
    match /physios/{uid}    { allow read: if isPhysio(); allow write: if false; }

    match /assignments/{aid} {
      allow get, list: if isPhysio() || ownsPatient(resource.data.patientId);
      allow create, delete: if isPhysio();
      allow update: if isPhysio()
        || (ownsPatient(resource.data.patientId)
            && onlyKeys(['seenByPatient'])
            && request.resource.data.seenByPatient == true);
    }

    match /completions/{cid} {
      allow get, list: if isPhysio() || ownsPatient(resource.data.patientId);
      allow create, update: if signedIn()
        && ownsPatient(request.resource.data.patientId)
        && cid == request.resource.data.date + '_'
                + request.resource.data.assignmentId + '_'
                + request.resource.data.videoId
        && request.resource.data.date.matches('\\d{4}-\\d{2}-\\d{2}')
        && request.resource.data.status in ['done', 'skipped']
        && get(/databases/$(db)/documents/assignments/$(request.resource.data.assignmentId))
             .data.patientId == request.resource.data.patientId;
      allow delete: if isPhysio();   // cascade delete only
    }
  }
}
```

Notes:
- The two `getAfter` cross-checks are the atomicity mechanism: neither doc can be written alone, and both rules' preconditions (`uid == null`, `redeemed == false`) close the reuse race because rules are evaluated against committed state at commit time. **This exact shape is what the day-2/3 emulator tests must prove before anything else is built.**
- Patient `list` rules rely on the query carrying an equality filter (`where('patientId', '==', myPatientId)` / `where('uid', '==', myUid)`), which makes `resource.data.<field>` statically constrained so the `get()` path is concrete. This is the documented pattern but must be explicitly emulator-verified on the pinned SDK; fallback if it misbehaves: a `users/{uid} → {patientId}` mapping doc written as a third leg of the redemption batch, with rules switching to `get(/users/$(auth.uid))`.
- Rule `get()` calls are billed reads (cached per request) — one per patient query/write. Negligible at clinic scale; noted for cost hygiene.
- Physio batched writes the rules must (and do) permit: assignment create + N video `usageCount` increments; patient create + invite create; regenerate-invite batch; cascade delete (assignments + completions + invite + patient, chunked ≤ 500 ops per batch, idempotent so a mid-way failure is fixed by re-running).
- Patient batched write: completion upsert + patient `lastActiveAt`-only update.

## 8. Storage rules

Path: `videos/{videoId}/{fileName}`.

```
service firebase.storage {
  match /b/{bucket}/o {
    match /videos/{videoId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.get('role', '') == 'physio'
        && request.resource.size < 100 * 1024 * 1024
        && request.resource.contentType.matches('video/.*');
      allow delete: if request.auth.token.get('role', '') == 'physio';
    }
    match /{path=**} { allow read, write: if false; }
  }
}
```

- Upload caps (100 MB; 90 s enforced client-side pre-compression) live in rules + a config constant — "raise caps in a config, never in a renegotiation".
- Playback uses the tokened `downloadURL` stored on docs, so the authenticated-read rule is belt-and-braces.
- **Known accepted gap (single-tenant only):** Storage rules can't read Firestore, so *any* authenticated user can read *any* video file if they learn its path; private videos are protected by unguessable paths + URLs only. Blocking prerequisite for clinic #2: per-clinic claims + path scoping (`videos/{clinicId}/...`), already structurally compatible with this design.

## 9. Emulator test plan — rules unit tests FIRST

Harness: `@firebase/rules-unit-testing` v3 + Vitest against the emulator suite, in `firebase/tests/`. TDD: every scenario written red before the corresponding rule exists. Test principals: `physio` (token `{role:'physio'}`), `anaUid` (linked patient), `markoUid` (other linked patient), `newUid` (authed, unlinked), `anon` (unauthenticated).

**Block A — redemption (highest risk, days 2–3, gates everything):**
1. Happy path: full batch (patient uid + invite redeemed) by `newUid` with valid code → **allow**.
2. Stolen-code reuse: same batch by a second user after redemption → **deny** (both preconditions).
3. Expired code → deny. 4. Partial batch, patient-update only → deny (`getAfter` invite check). 5. Partial batch, invite-update only → deny (`getAfter` patient check). 6. `redeemedBy != auth.uid` or `uid != auth.uid` → deny. 7. Redemption batch touching extra fields (e.g. `notes`) → deny (`affectedKeys`). 8. Redeeming a code that is not the patient doc's *current* `inviteCode` (post-regenerate) → deny. 9. `get` unredeemed invite by any signed-in user → allow; redeemed/expired invite `get` → deny; `list` invites as patient → deny; anything as `anon` → deny.
10. **Checkpoint (end day 3):** if any of A is inexpressible or racy → switch to single Cloud Function `redeemInvite` (Admin SDK transaction; ~1 extra day: Functions setup, deploy pipeline, cold-start UX on the redeem button, Node runtime to maintain).

**Block B — patient isolation:**
11. Ana reads own patient doc / queries `uid == anaUid` → allow; reads Marko's doc, or lists patients without the uid filter → deny.
12. Ana lists own assignments (`patientId` filter) → allow; Marko's, or unfiltered → deny — this test also proves the query-constrained `get()` pattern of §7.
13. Ana sets `seenByPatient: true` on own assignment → allow; sets it `false`, edits `items`/`active`, or touches Marko's → deny.
14. Ana writes own completion with correct deterministic ID and `status in {done, skipped}` → allow; overwrite same ID (retry/double-tap upsert) → allow; wrong ID format, bogus status, completion for Marko's `patientId`, or `assignmentId` belonging to Marko → deny.
15. Ana `lastActiveAt`-only self-update (batched with completion) → allow; `notes` update → deny.
16. Ana reads `videos` or `templates` → deny (proves the denormalization contract holds).

**Block C — physio scope:** full CRUD on all collections with claim → allow; `newUid` (no claim, no link) → deny everywhere; assignment-create batch incrementing `usageCount` on videos → allow; cascade-delete batch → allow; `physios` writes even as physio → deny.

**Block D — Storage:** physio upload ≤100 MB `video/*` → allow; patient upload → deny; >100 MB or `image/*` as physio → deny; authenticated read → allow; unauthenticated read → deny; write outside `videos/**` → deny.

**Block E — integration (day 11):** scripted flow against emulators — physio creates patient + invite → patient signs up + redeems → patient sees assignment stream → records completion offline-shaped upsert. Reuses fixture shapes from `app/lib/data/demo_data.dart`.

## 10. Password reset & account recovery (non-technical patients)

- **Self-serve:** "Zaboravljena lozinka?" on the login screen → `sendPasswordResetEmail` (Croatian template, Tendo sender name). Generic success copy regardless of whether the email exists (enumeration protection stays on).
- **In-app guidance:** the login error state and the redeem screen both show the clinic's support contact ("Ne ide? Nazovite Tendo: …") — patients call the clinic, not Dominik.
- **Runbook (clinic → Dominik channel, admin scripts from §3):**
  1. *Forgot password, has email:* self-serve; clinic staff can walk them through it.
  2. *Typo'd email at signup* (reset mail never arrives): `change_email.mjs` fixes the address, then self-serve reset. This is the accepted cost of not forcing email verification.
  3. *Lost access to email account:* `change_email.mjs` to a new address + reset link.
  4. *Wants to start over / device handed to a sibling:* physio regenerates the invite? No — uid is already linked; instead Dominik deletes the Auth user + nulls `patients.uid` via script, physio regenerates the invite. (Rare; script `unlink_patient.mjs` covers it.)
- New phone / reinstall: plain sign-in; Firestore offline cache rebuilds itself.
- Constraint to document for the clinic: **one email = one patient account** (a parent managing two children needs two email addresses).

## 11. Client integration seam

- New entrypoint `app/lib/main_firebase.dart`: `Firebase.initializeApp()` → build Firestore repository bundle → `PhysioApp(repositories: …)`. `app/lib/main.dart` (demo) stays byte-identical in behavior; `app/lib/app/app.dart` becomes flavor-agnostic by accepting the repository bundle (it already takes an injectable `DemoStore`).
- New domain interface `AuthRepository`: `Stream<AuthUser?> watchAuth()`, `signIn(email, password)`, `signOut()`, `sendPasswordReset(email)`, `redeemInvite({code, email, password}) → Future<Result<void>>` (encapsulates §6 steps 3–4 including orphan cleanup). Demo implementation is a no-op backed by `RoleCubit` so the pitch build never changes.
- Firestore streams already satisfy the `Watchable` emit-current-value-on-listen contract; any mapping layer must preserve it.

## 12. Deferred hardening (explicitly out of MVP)

App Check; Storage per-clinic claims and path scoping (blocking for clinic #2 / resale); push notifications; rate limiting beyond Firebase Auth's built-in abuse protection; FlutterFire upgrade off the EOL 3.x generation (requires Flutter/Dart upgrade, its own task).