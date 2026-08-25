# Physio App — MVP Design

**Date:** 2026-08-25
**Status:** Approved — showcase phase in progress (§15)
**Stack:** Flutter · BloC · feature-first · Firebase (Auth, Firestore, Storage)

---

## 1. Purpose

A single place where a physiotherapist assigns personalized rehab videos to specific patients, and where each patient does a guided daily session and reports completion.

Two problems it solves:

- **For the physio:** exercise videos currently live scattered across WhatsApp threads, YouTube links, and printed sheets. There is no way to know whether a patient actually did the work between appointments.
- **For the patient:** no single trustworthy place showing what to do today, how many reps, and what it looks like done correctly.

**Non-goal:** this is not a clinic management system. No scheduling, no billing, no clinical records.

---

## 2. Tenancy

Single practice at launch, with multi-tenancy structurally pre-wired.

Every domain document carries a `clinicId`, and all Firestore paths are nested under `clinics/{clinicId}`. Security rules scope every read and write by the caller's `clinicId`. With one clinic this is invisible overhead; it removes a data migration if the physio ever refers colleagues.

**Explicitly out of scope:** clinic self-signup, clinic switching UI, per-clinic branding. The data model supports many clinics; the MVP ships one, seeded manually.

---

## 3. Roles and Access

One Flutter app, two roles. After login the router reads the user's role and routes to the physio shell or the patient shell. Two separate apps would mean two store submissions, two build pipelines, and duplicated auth and model code for a product with exactly one physio.

### 3.1 Physio

Single seeded account. No self-signup path exists in the MVP.

### 3.2 Patient — invite-bound signup

The physio and patient already have a real-world relationship before any app exists, so the app follows that order:

1. Physio creates a patient record: **name and email only.**
2. App generates a single-use invite code with an expiry.
3. Physio gives the patient the code (in person, SMS, however he likes).
4. Patient installs the app, signs up with email and password.
5. Patient enters the code. Their Firebase Auth UID is linked to the existing patient record.

**Design decisions inside this flow:**

- **No condition or diagnosis field at signup.** Clinical context lives in the physio's private notes on the patient record, added whenever he wants. Onboarding asks a patient for nothing a physio already knows.
- **A signup without a valid code has no clinic and no patient record, and therefore sees nothing.** There is no orphan-account state to design around.
- **Codes are single-use and expire after 14 days.** A leaked or forwarded code cannot be reused.
- **The physio can regenerate a code** from the patient detail screen, covering the common case of a patient losing it before redeeming.
- Videos can be uploaded and protocols assigned **before** the patient ever installs the app. Nothing on the physio's side is blocked on patient onboarding.

---

## 4. Content Model

### 4.1 Videos belong to the clinic, not to a patient

A physio filming "seated quad extension" has eleven knee patients. Uploading that file eleven times wastes his time, his mobile data, and makes re-filming it later an eleven-place edit.

So: **videos are uploaded once into a clinic library, tagged with a body-part category.** Assigning references a library video — assignment is instant and involves no upload.

Body-part categories (knee, shoulder, lower back, hip, neck, …) serve double duty: the physio picks one when uploading, and they group content for browsing on both sides.

### 4.2 Patient-private videos

Some videos genuinely are for one person — "Dominik, here's what I want you to focus on this week." These are flagged private to a patient. They live in the library structurally but only ever surface for that patient, and never appear in general browse lists.

### 4.3 Dosage lives on the assignment, not the video

Your reps are not the next patient's reps, even for an identical video. Sets, reps, hold time, and frequency are properties of the prescription, never of the file.

### 4.4 Protocol templates, and snapshot-on-assign

The physio builds "Meniscus Recovery — Phase 1" once: an ordered list of videos with default dosage. Assigning it to a patient takes two taps, after which he adjusts that patient's copy.

**Assigning copies the template. It does not link to it.**

This is the single most important decision in the data model. If assignments *referenced* their template, then tweaking a template while setting up a new patient would silently rewrite the live prescriptions of everyone already on it — eleven people's rehab changing as a side effect of an unrelated edit. With snapshots, template edits affect only future assignments, and edits to one patient's plan affect nobody else. This matches what a clinician would intuitively expect and is the safe default in a health context.

### 4.5 Three ways to assign

1. **From a template** — the common case for routine injuries. One tap, then adjust dosage.
2. **Build a custom protocol** — pick videos from the library, set order and dosage. Offers **"save as template"** on completion, so his template library grows out of real work rather than requiring an authoring session up front.
3. **Send a single video** — one clip, no protocol, no dosage ceremony.

### 4.6 Multiple concurrent protocols

A patient can have several active protocols at once. The realistic case is a knee injury plus the lower back strained by compensating for it.

- **Physio side:** assign as many as he likes, each honestly named and drawn from the right template.
- **Patient side:** protocol boundaries are invisible. The home hero merges everything due today into one session; the player walks through knee exercises, then back exercises, in one pass.

**Guard rail:** when assigning a second protocol, the confirmation screen states the resulting total ("Dominik will have 11 exercises daily"). Managing load is the physio's judgment, but he should not discover the total by accident — an over-prescribed patient quietly gives up.

### 4.7 Video metadata is denormalized into assignments

At assign time, each assignment item stores the video's `title`, `storagePath`, `thumbPath`, and `durationSec` alongside its dosage.

Two benefits: patients never read the `videos` collection at all, so no security rule has to expose the clinic library to them; and rendering a session is a single document read.

Consistent with the snapshot decision in 4.4 — renaming a library video does not retroactively rename it inside existing prescriptions.

---

## 5. Patient Experience

### 5.1 Home — one screen, no tabs

Tabs would display emptiness. A realistic patient has one or two protocols and a couple of loose videos; a four-tab shell means a Progress tab holding a single week-strip on an otherwise blank screen.

Top to bottom:

- **Hero card** (dark pine, the visual anchor): `Today's session · 8 exercises`, the contributing protocol names, a seven-day completion strip, and the primary action **Start today's session**.
- **"Also assigned"** — single videos not part of any protocol.
- **Body-part sections** — everything else grouped under headings, shown only when there is more than one category.

Profile sits behind the avatar in the header.

The hero exists for focus, not decoration: a single dark card with one action, rather than a list asking the patient to choose.

### 5.2 Session player — one exercise at a time

Tapping the hero opens a focused, full-screen flow:

- Video at top, playing the current exercise
- `Exercise 2 of 3`, exercise name
- Dosage pills — sets / reps / hold
- **Done · next exercise** — advances automatically
- **Skip this one** — advances, recorded distinctly

Two things this buys over a checklist. The patient sees one thing at a time, which is what focus actually means. And completion becomes a side effect of doing the work rather than a separate tick-three-boxes chore.

**Skips are recorded separately from completions.** "He has skipped heel slides every day this week" is a far better clinical signal than a missing checkmark, and it gives the patient an honest exit on a bad-pain day instead of abandoning the session.

The player screen is dark regardless of theme — it is mostly video.

### 5.3 Resuming an interrupted session

A patient who does two of three exercises and closes the app has their progress persisted per exercise, not per session — each `Done` or `Skip` writes a `completions` document immediately.

Reopening the app the same day shows the hero as `Today's session · 1 remaining`, and **Start** resumes at the first exercise with no recorded outcome for that date. Exercises already marked done or skipped are not repeated.

The next calendar day the session resets in full: yesterday's outcomes stay in history and today starts from exercise one.

### 5.4 New-assignment indicator

Since the MVP has no push notifications (§11), an assignment the patient has not yet opened shows a **New** badge on its row, and its protocol contributes a **New** marker to the hero. The badge clears on first open.

---

## 6. Physio Experience

### 6.1 Patients list

One row per patient: avatar initials, name, primary body part, last-active, and a seven-dot strip for the last week — filled = completed, amber = skipped, empty = nothing.

- Long silence renders in red. Nine days of nothing is the single most actionable thing on his screen and is precisely what a paper file cannot tell him.
- Patients who have not yet redeemed their invite show an `invited` chip instead of dots.

### 6.2 Patient detail

- **Active protocols** — each with counts of done and skipped, plus an adherence percentage

  **Adherence is defined as:** exercise-outcomes recorded as `done`, divided by exercise-occurrences scheduled, counted from the assignment's creation date to today across its `daysOfWeek`. Skips count against adherence — that is the point of recording them separately. Today is excluded from the denominator until the day ends, so a patient is never shown as behind for work still ahead of them.

- **Single videos** assigned to this patient, private ones marked
- **Private notes** — free text, physio-only, where clinical context lives
- **Assign something** — primary action
- Invite management (regenerate code) for un-redeemed patients

### 6.3 Assign flow

Fork screen offering the three paths from 4.5, with recent templates listed directly beneath so the common case is one tap.

**Adjust dosage screen:** reorder exercises by drag, edit sets / reps / hold per exercise, remove exercises. **Values overridden from the template default are visually marked** (outlined pills), so he can see at a glance what is bespoke about this patient's plan versus what is standard.

### 6.4 Library

Videos grouped under body-part headings, each showing duration and a usage count ("used by 9"). Private videos carry a badge.

**Upload lives in two places:** the ＋ on the Library screen, and inline within the video picker while building a protocol. The inline path matters — "let me film this for you right now," with the patient standing in front of him, is the reason he wants this app. Forcing him to abandon the assign flow to upload is the friction that gets apps abandoned.

---

## 7. Design System

**Direction: Warm Recovery.** Neither hospital nor gym.

A cool-blue clinical palette looks like every insurance portal and makes rehab feel like paperwork. A high-contrast athletic palette with an electric accent looks best in isolation but flatters the wrong person — much of the roster is post-surgical, in pain, or sixty, and that palette shouts at you on a bad knee day. Deep pine green on warm off-white reads as healing rather than performance, and the warm background is easier on older eyes.

### Tokens

| Token | Value | Use |
|---|---|---|
| `bg` | `#faf7f2` | Screen background |
| `surface` | `#fffdfa` | Cards, rows |
| `border` | `#ece5da` | Hairlines, card borders |
| `text` | `#2b2620` | Primary text |
| `textMuted` | `#857b6e` | Secondary text, labels |
| `accent` | `#2c7a63` | Primary actions, active states |
| `accentDeep` | `#1f5a4c` | Hero gradient start, pressed states |
| `accentSoft` | `#a7d9c8` | Hero eyebrow text, subtle fills |
| `onAccent` | `#fdfbf7` | Text and CTA fill on accent surfaces |
| `warning` | `#b45309` | Skipped-exercise indicator |
| `danger` | `#b3261e` | Inactive-patient warning |

- **Hero gradient:** `#1f5a4c → #2c7a63` at 150°
- **Typography:** system fonts (SF Pro / Roboto), base size one step above default for legibility
- **Radii:** 9–13px — softer than material default
- **Light mode only.** The session player is dark because it is mostly video, so dark appears where it earns its keep without maintaining two themes.

---

## 8. Video Storage

**Firebase Storage plus client-side compression.**

At this scale — roughly 30 patients, 100 videos, 2 minutes each — cost is a non-issue on any option (~$3–4/month either way). The decision rests on two things that do differ.

**The real problem is upload size, not bandwidth.** An iPhone produces 150–300MB for two minutes. Serving that unmodified to a patient's phone is what makes an app feel broken.

**The real advantage of Firebase is access control.** Storage security rules read the Firebase Auth token declaratively, with no backend code. Cloudflare Stream requires signed URLs, which requires a Cloud Function, which means deploying backend infrastructure in week one.

**Decision:** compress on the physio's device before upload (`video_compress`), targeting 720p and roughly 15MB for a two-minute clip — ample for watching an exercise. At that size adaptive bitrate stops mattering; playback is progressive MP4 via `video_player`.

**Accepted cost:** compression runs on his phone and takes 20–40 seconds for a two-minute clip, behind a progress indicator. Acceptable for a few videos a week; it would be miserable at fifty a day.

**Rejected:** Cloudflare R2 — zero egress is its whole pitch, but it does not transcode *and* loses the Firebase Auth integration. Worst of both at this scale.

**Exit path:** every video document stores a `provider` field, and playback URLs resolve through a `VideoStorageRepository` interface. Migrating to Cloudflare Stream is one new implementation class, not a refactor. Trigger conditions: the bill starts mattering, or patients report buffering.

Firebase Storage requires the Blaze plan regardless of volume.

---

## 9. Firestore Structure

```
users/{uid}
  role: 'physio' | 'patient'
  clinicId: string
  patientId: string?          // patients only

invites/{code}                // top-level: readable by code, never listable
  clinicId, patientId
  expiresAt: timestamp
  redeemedBy: uid | null

clinics/{clinicId}
  name, createdAt

clinics/{clinicId}/patients/{patientId}
  name, email
  uid: string?                // set on invite redemption
  notes: string               // physio-only clinical context
  primaryBodyPart: string?
  lastActiveAt: timestamp?
  createdAt

clinics/{clinicId}/videos/{videoId}
  title, bodyPart, durationSec
  storagePath, thumbPath
  provider: 'firebase'
  visibility: 'library' | 'private'
  privateToPatientId: string?
  usageCount: int
  createdAt

clinics/{clinicId}/templates/{templateId}
  name, bodyPart
  items: [{ videoId, order, sets, reps, holdSec }]
  createdAt

clinics/{clinicId}/patients/{patientId}/assignments/{assignmentId}
  type: 'protocol' | 'single'
  name
  sourceTemplateId: string?   // provenance only, never followed
  bodyParts: [string]
  daysOfWeek: [int]           // ISO 1=Mon..7=Sun; daily is [1,2,3,4,5,6,7]
  items: [{
    videoId, order, sets, reps, holdSec,
    overridden: bool,         // differs from template default
    title, storagePath, thumbPath, durationSec   // denormalized, see 4.7
  }]
  active: bool
  createdAt

clinics/{clinicId}/patients/{patientId}/completions/{date}_{assignmentId}_{videoId}
  // deterministic ID: one outcome per exercise per day, so a double-tap
  // or a retry after a dropped connection overwrites rather than duplicates
  date: 'YYYY-MM-DD'          // local date, for day grouping
  assignmentId, videoId
  status: 'done' | 'skipped'
  at: timestamp
```

`completions` is deliberately shaped to accept a `painScore` or `notes` field later without migration — the deferred logging feature (§11) hangs off this document.

---

## 10. Security Rules

Rules carry the entire authorization burden, since the MVP has no backend. They are therefore the highest-risk component and are tested against the emulator as a first-class deliverable, not an afterthought.

**Core scoping:** every read and write under `clinics/{clinicId}` requires the caller's `users/{uid}.clinicId` to match. Writes to library, templates, and assignments require `role == 'physio'`.

**Patient scope:** a patient may read only their own patient document and its `assignments` subcollection, and may create `completions` only under their own patient path. Because video metadata is denormalized into assignments (§4.7), no rule ever needs to expose the `videos` collection to a patient.

**Invite redemption**, achieved with rules alone:

1. Any authenticated user may `get` (never `list`) `invites/{code}` — knowing the code is the authorization.
2. That user may update the invite exactly once, setting `redeemedBy` to their own UID, only if `redeemedBy == null` and `expiresAt` is in the future.
3. They may then create `users/{uid}` only if `get(/invites/{inviteCode}).redeemedBy == request.auth.uid`, with `clinicId` and `patientId` copied from the invite.
4. They may set `uid` on the matching patient document under the same condition.

### Known limitations, accepted for the MVP

**Storage rules cannot query Firestore.** Firebase Storage rules see only the auth token, so per-patient file authorization is not expressible without custom claims — and setting custom claims requires the Admin SDK, meaning a Cloud Function.

The MVP therefore allows any authenticated user to read video files. In a single-tenant deployment where accounts exist only by invite, the audience is exactly this clinic's patients plus the physio. Private videos are protected only by unguessable storage paths, not by rule.

**This must be tightened before a second clinic exists**, via custom claims carrying `clinicId` and a Cloud Function to set them. Recorded here as a blocking prerequisite for multi-tenancy, not a nice-to-have.

---

## 11. Out of Scope

| Cut | Reasoning |
|---|---|
| **In-app messaging** | The physio and patient already have WhatsApp. Building chat means read receipts, notifications, and a physio checking a second inbox. Largest single scope saving available. |
| **Offline downloads** | Rehab happens at home on wifi, and 15MB streams instantly. Downloads mean cache management, storage limits, and stale-video invalidation. Add if someone actually complains. |
| **Push notifications** | Needs a Cloud Function plus APNs certificates, entitlements, permission prompts, and token lifecycle — roughly a day of unpleasant, hard-to-test setup, before anyone knows whether they like the app. The MVP's daily habit comes from the session player, not a push. **First thing to build post-MVP.** New assignments get an in-app "New" badge instead (§5.4). |
| **Pain scores, charts, session logging** | Where rehab apps become real products, and where MVPs die. The `completions` document is already shaped to accept it. |
| **Clinic self-signup / multi-clinic UI** | Data model is ready (§2); the UI and the Storage rule tightening (§10) are the actual work. |

---

## 12. Architecture

Feature-first, with each feature owning its data, domain, and presentation layers.

```
lib/
  app/              bootstrap, router (go_router), theme, DI
  core/             Result type, failures, Firestore refs, date helpers
  design_system/    tokens, typography, buttons, cards, dosage pills, hero
  features/
    auth/           login, signup, invite redemption
    patients/       list, detail, notes, invite management   (physio)
    library/        browse, upload, compression              (physio)
    templates/      list, builder, save-as-template          (physio)
    assignments/    assign fork, dosage editor               (physio)
    home/           patient home, hero, grouped sections     (patient)
    session/        guided player state machine              (patient)
    profile/        shared
```

Each feature: `data/` (DTOs, repository implementations), `domain/` (entities, repository interfaces), `presentation/` (bloc, pages, widgets). Features depend on `core` and `design_system`, never on each other — cross-feature needs go through a domain interface.

### BloCs

| BloC | Responsibility |
|---|---|
| `AuthBloc` | Global. Auth state, role resolution, router redirects. |
| `InviteRedemptionBloc` | The multi-step redemption sequence in §10. |
| `PatientsBloc` | Patient list with adherence strips. |
| `PatientDetailBloc` | One patient: assignments, notes, invite state. |
| `LibraryBloc` | Browse videos by body part. |
| `UploadCubit` | Compression and upload progress. Separate — it outlives the screen. |
| `TemplatesBloc` | Template list and builder. |
| `AssignFlowBloc` | The fork, video picking, dosage editing, snapshot creation. |
| `PatientHomeBloc` | Merges today's exercises across active protocols. |
| `SessionBloc` | Player state machine: current index, done, skip, complete. |

### Testing

- `bloc_test` unit tests per BloC against fake repositories
- **Security rules tests against the Firestore emulator** — non-negotiable, since rules are the entire authorization layer (§10)
- Widget tests for `SessionBloc`-driven advance and skip behavior
- Integration test for the full invite → signup → redeem → see-assignment path, the most failure-prone sequence in the app

### Error handling

- Repositories return a `Result` type; BloCs map failures to user-facing state. No exceptions crossing layer boundaries.
- Firestore's offline cache covers transient connectivity; no custom sync layer.
- Upload failures are retryable from the `UploadCubit` without re-selecting the file.
- Compression failure falls back to uploading the original, with a file-size warning to the physio.

---

## 13. Build Order

1. Firebase project, Blaze plan, emulator setup, **security rules with tests**
2. `design_system` tokens and core components
3. Auth: physio login, patient signup, invite redemption end-to-end
4. Physio: patient list and detail, invite generation
5. Physio: library browse and upload with compression
6. Physio: templates and the assign flow with snapshotting
7. Patient: home with hero and merged session
8. Patient: session player with done and skip
9. Adherence surfacing back on the physio side

Rules come first because everything else depends on them and they are the piece most likely to force a data-model change.

---

## 14. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Invite redemption expressed purely in security rules | **High** | Emulator tests first (step 1). Fallback: a single Cloud Function to perform redemption atomically. |
| Storage read rule too broad (§10) | Medium | Acceptable single-tenant. Blocking prerequisite for multi-tenancy — custom claims plus a Cloud Function. |
| Client-side compression on older Android devices | Medium | Fall back to original upload with a size warning. Test on a low-end device before shipping. |
| Physio finds compression wait annoying | Low | Background the upload so he can keep working; surface progress non-modally. |
| Patient over-prescribed across two protocols | Low | Total-exercise warning at assign time (§4.6). |

---

## 15. Showcase Phase — Demo Mode

Provisioning Firebase (project creation, Blaze billing, Auth setup) requires the owner's Google account and cannot be done autonomously. The showcase phase therefore builds the **complete app UI and domain logic against in-memory demo repositories**, so the app runs and is fully navigable today with zero backend. Firebase comes next as drop-in repository implementations — the architecture in §12 (repository interfaces, `Result` type, BloCs that never touch Firestore directly) exists precisely so this substitution is invisible to every screen.

### 15.1 What demo mode replaces

| Real thing | Demo stand-in |
|---|---|
| Firebase Auth + login/signup/invite redemption | Role-pick screen at launch: **Enter as physio** / **Enter as patient**. The real auth screens are out of showcase scope; the router's role-gate logic is real and reused later. |
| Firestore repositories | In-memory implementations seeded from a single `DemoData` fixture: one clinic, six patients (mixed states: adherent, skipping, silent 9 days, un-redeemed invite), a video library across four body parts, three templates, active assignments incl. one two-protocol patient, and three weeks of completion history. |
| Firebase Storage + `video_player` | A `DemoVideoPlayer` widget: poster gradient with exercise name, play/pause, simulated progress bar driven by an `AnimationController` over the real `durationSec`. Sits behind the same widget interface a real player will implement. Avoids per-platform codec issues and needs no bundled media. |
| Client-side compression | Simulated: upload flow shows the compression progress stage on a timer, then "uploads" into the in-memory library, which immediately appears everywhere. |

### 15.2 What is fully real in demo mode

All domain logic ships production-shaped and unit-tested: today's-session merge across protocols (§4.6), per-exercise completion with deterministic IDs and resume (§5.3), skip-vs-done distinction (§5.2), adherence math (§6.2), week strips and silence detection (§6.1), snapshot-on-assign with override marking (§4.4, §6.3), the New badge lifecycle (§5.4), and the entire design system (§7). Demo repositories mutate live in memory — assigning a protocol as the physio and then switching roles shows it on the patient's home with a New badge.

### 15.3 Showcase quality bar

- `flutter analyze` clean; all unit/bloc/widget tests pass.
- **No render overflows:** every screen is pumped in widget tests at 320×568, 375×667, and 430×932 logical sizes; a `RenderFlex` overflow fails the test.
- Runs on macOS desktop and Chrome from `flutter run` with no setup.

### 15.4 Deferred to the Firebase phase

Security rules + emulator tests (§10), real auth and invite redemption, real upload/compression/playback, `lastActiveAt` writes from real sessions. The build order in §13 still governs that phase; nothing in demo mode forecloses it.
