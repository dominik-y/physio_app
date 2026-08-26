// Seed the emulator with a demo-shaped world (fixture patients in named
// states, videos, templates, assignments, ~3 weeks of completions) plus the
// dev Auth accounts main_firebase.dart's DEV_LOGIN bootstrap signs into.
// Dates are relative to `now` (or --now=YYYY-MM-DD) so fixtures never rot.
// Refuses to run against production: emulator-only by construction.
import { auth, db, fail } from './common.mjs'

if (process.env.TENDO_PROJECT) fail('seed is emulator-only — unset TENDO_PROJECT')

const nowArg = process.argv.find((a) => a.startsWith('--now='))
const now = nowArg ? new Date(`${nowArg.slice(6)}T09:30:00`) : new Date()
const day = (n) => new Date(now.getTime() - n * 864e5)
const ymd = (d) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
const iso = (d) => d.getDay() === 0 ? 7 : d.getDay() // ISO 1=Mon..7=Sun

// ---- Auth users -----------------------------------------------------------
const PHYSIO_UID = 'uid-physio-tomislav'
const ANA_UID = 'uid-ana'
const PASSWORD = 'tendo-dev-1'

async function ensureUser(opts) {
  await auth.deleteUser(opts.uid).catch(() => {})
  await auth.getUserByEmail(opts.email).then((u) => auth.deleteUser(u.uid)).catch(() => {})
  return auth.createUser(opts)
}

await ensureUser({ uid: PHYSIO_UID, email: 'tomislav@tendo.hr', password: PASSWORD, displayName: 'Tomislav Perić' })
await auth.setCustomUserClaims(PHYSIO_UID, { role: 'physio' })
await ensureUser({ uid: ANA_UID, email: 'ana@example.com', password: PASSWORD, displayName: 'Ana Kovačević' })

// ---- Firestore ------------------------------------------------------------
// Wipe collections so re-seeding is idempotent.
for (const col of ['physios', 'patients', 'invites', 'videos', 'templates', 'assignments', 'completions', 'patientNotes']) {
  const snap = await db.collection(col).get()
  const batch = db.batch()
  snap.docs.forEach((d) => batch.delete(d.ref))
  await batch.commit()
}

const batch = db.batch()
const set = (path, data) => batch.set(db.doc(path), data)

set(`physios/${PHYSIO_UID}`, { name: 'Tomislav Perić, mag. physioth.', email: 'tomislav@tendo.hr', createdAt: day(60) })

// Videos (Croatian titles, mirroring the demo library's spirit).
const videos = [
  { id: 'v-heel', title: 'Klizanje petom', bodyPart: 'Knee', durationSec: 60 },
  { id: 'v-quad', title: 'Stisak kvadricepsa', bodyPart: 'Knee', durationSec: 45 },
  { id: 'v-bridge', title: 'Glutealni most', bodyPart: 'Lower back', durationSec: 50 },
  { id: 'v-step', title: 'Kontrolirani uspon na step', bodyPart: 'Knee', durationSec: 70 },
  { id: 'v-plank', title: 'Izdržaj — bočni plank', bodyPart: 'Core', durationSec: 40 },
  { id: 'v-balance', title: 'Ravnoteža na jednoj nozi', bodyPart: 'Knee', durationSec: 55 },
  { id: 'v-ana-focus', title: 'Ana — fokus na koljeno ovaj tjedan', bodyPart: 'Knee', durationSec: 130, visibility: 'private', privateToPatientId: 'pat-ana' },
]
for (const v of videos) {
  set(`videos/${v.id}`, {
    title: v.title,
    bodyPart: v.bodyPart,
    durationSec: v.durationSec,
    visibility: v.visibility ?? 'library',
    privateToPatientId: v.privateToPatientId ?? null,
    usageCount: 0,
    createdAt: day(30),
    mediaUrl: null,
    posterUrl: null,
    storagePath: null,
    status: 'ready',
  })
}
const vmap = Object.fromEntries(videos.map((v) => [v.id, v]))
const item = (videoId, order, sets_, reps, holdSec = 0) => ({
  videoId,
  order,
  sets: sets_,
  reps,
  holdSec,
  overridden: false,
  title: vmap[videoId].title,
  durationSec: vmap[videoId].durationSec,
  bodyPart: vmap[videoId].bodyPart,
  mediaUrl: null,
  posterUrl: null,
})

// Templates.
set('templates/t-meniscus', {
  name: 'Oporavak meniskusa — faza 1',
  bodyPart: 'Knee',
  items: [
    { videoId: 'v-heel', order: 0, sets: 3, reps: 10, holdSec: 0 },
    { videoId: 'v-quad', order: 1, sets: 3, reps: 12, holdSec: 5 },
    { videoId: 'v-step', order: 2, sets: 2, reps: 10, holdSec: 0 },
  ],
  createdAt: day(45),
})
set('templates/t-core', {
  name: 'Stabilnost trupa',
  bodyPart: 'Core',
  items: [
    { videoId: 'v-bridge', order: 0, sets: 3, reps: 8, holdSec: 0 },
    { videoId: 'v-plank', order: 1, sets: 3, reps: 1, holdSec: 30 },
  ],
  createdAt: day(40),
})

// Patients in named states.
const patients = [
  { id: 'pat-ana', name: 'Ana Kovačević', email: 'ana@example.com', uid: ANA_UID, primaryBodyPart: 'Knee' },
  { id: 'pat-ivana', name: 'Ivana Marić', email: 'ivana@example.com', uid: 'uid-ivana', primaryBodyPart: 'Knee' },
  { id: 'pat-marko', name: 'Marko Horvat', email: 'marko@example.com', uid: 'uid-marko', primaryBodyPart: 'Lower back' },
  { id: 'pat-josip', name: 'Josip Novak', email: 'josip@example.com', uid: 'uid-josip', primaryBodyPart: 'Knee' },
  { id: 'pat-luka', name: 'Luka Babić', email: 'luka@example.com', uid: null, inviteCode: 'LK7-3FQ9' },
]
for (const p of patients) {
  set(`patients/${p.id}`, {
    name: p.name,
    email: p.email,
    uid: p.uid ?? null,
    primaryBodyPart: p.primaryBodyPart ?? null,
    lastActiveAt: null, // refined below for active patients
    inviteCode: p.inviteCode ?? null,
    inviteExpiresAt: p.inviteCode ? day(-10) : null,
    createdAt: day(50),
  })
}
set('invites/LK7-3FQ9', {
  patientId: 'pat-luka',
  expiresAt: day(-10),
  createdAt: day(4),
  createdBy: PHYSIO_UID,
  redeemed: false,
  redeemedBy: null,
  redeemedAt: null,
})
set('patientNotes/pat-ana', { notes: 'Oprez s desnim koljenom — ne forsirati fleksiju preko 90°.', updatedAt: day(3) })
set('patientNotes/pat-marko', { notes: 'Preskače vježbe za donji dio leđa, provjeriti tehniku.', updatedAt: day(6) })

// Assignments.
const assignments = [
  { id: 'as-ana-knee', patientId: 'pat-ana', type: 'protocol', name: 'Oporavak meniskusa — faza 1', sourceTemplateId: 't-meniscus', days: [1, 2, 3, 4, 5, 6, 7], items: [item('v-heel', 0, 3, 10), item('v-quad', 1, 3, 12, 5), item('v-step', 2, 2, 10)], createdDaysAgo: 21, seen: true },
  { id: 'as-ana-core', patientId: 'pat-ana', type: 'protocol', name: 'Stabilnost trupa', sourceTemplateId: 't-core', days: [1, 2, 3, 4, 5, 6, 7], items: [item('v-bridge', 0, 3, 8), item('v-plank', 1, 3, 1, 30)], createdDaysAgo: 14, seen: true },
  { id: 'as-ana-single', patientId: 'pat-ana', type: 'single', name: 'Ana — fokus na koljeno ovaj tjedan', sourceTemplateId: null, days: [1, 2, 3, 4, 5, 6, 7], items: [item('v-ana-focus', 0, 1, 1)], createdDaysAgo: 2, seen: false },
  { id: 'as-ivana', patientId: 'pat-ivana', type: 'protocol', name: 'Oporavak meniskusa — faza 1', sourceTemplateId: 't-meniscus', days: [1, 3, 5], items: [item('v-heel', 0, 3, 10), item('v-quad', 1, 3, 12, 5)], createdDaysAgo: 21, seen: true },
  { id: 'as-marko', patientId: 'pat-marko', type: 'protocol', name: 'Stabilnost trupa', sourceTemplateId: 't-core', days: [1, 2, 3, 4, 5], items: [item('v-bridge', 0, 3, 8), item('v-plank', 1, 3, 1, 30)], createdDaysAgo: 18, seen: true },
  { id: 'as-josip', patientId: 'pat-josip', type: 'protocol', name: 'Oporavak meniskusa — faza 1', sourceTemplateId: 't-meniscus', days: [2, 4, 6], items: [item('v-heel', 0, 3, 10), item('v-step', 1, 2, 10)], createdDaysAgo: 25, seen: true },
]
const usage = {}
for (const a of assignments) {
  a.items.forEach((i) => (usage[i.videoId] = (usage[i.videoId] ?? 0) + 1))
  set(`assignments/${a.id}`, {
    patientId: a.patientId,
    type: a.type,
    name: a.name,
    sourceTemplateId: a.sourceTemplateId,
    bodyParts: [...new Set(a.items.map((i) => i.bodyPart))],
    daysOfWeek: a.days,
    items: a.items,
    active: true,
    seenByPatient: a.seen,
    createdAt: day(a.createdDaysAgo),
  })
}
for (const [vid, count] of Object.entries(usage)) {
  batch.update(db.doc(`videos/${vid}`), { usageCount: count })
}

// Completion history (~3 weeks), per-patient adherence personalities:
//   ana: adherent, but misses v-bridge every 3rd day (hollow-dot fixture);
//        TODAY is half-done (resume state — v-quad done this morning)
//   ivana: ~94% adherent; marko: skips often; josip: silent for 9 days
const lastActive = {}
function complete(patientId, assignment, videoId, d, status, hourOffset = 0) {
  const date = ymd(d)
  const at = new Date(d.getTime() - hourOffset * 36e5)
  set(`completions/${date}_${assignment}_${videoId}`, {
    patientId,
    date,
    assignmentId: assignment,
    videoId,
    status,
    at,
  })
  if (!lastActive[patientId] || at > lastActive[patientId]) lastActive[patientId] = at
}

for (let n = 20; n >= 1; n--) {
  const d = day(n)
  // Ana: both protocols scheduled daily.
  for (const a of assignments.filter((x) => x.patientId === 'pat-ana' && x.type === 'protocol' && x.createdDaysAgo >= n)) {
    for (const i of a.items) {
      if (i.videoId === 'v-bridge' && n % 3 === 0) continue // missed, not skipped
      complete('pat-ana', a.id, i.videoId, d, 'done', 2)
    }
  }
  // Ivana: scheduled Mon/Wed/Fri, one skip a week.
  if ([1, 3, 5].includes(iso(d)) && 21 >= n) {
    for (const i of assignments.find((x) => x.id === 'as-ivana').items) {
      complete('pat-ivana', 'as-ivana', i.videoId, d, n % 7 === 2 ? 'skipped' : 'done', 5)
    }
  }
  // Marko: weekdays, skips the plank half the time, missing lately.
  if (iso(d) <= 5 && 18 >= n && n > 4) {
    for (const i of assignments.find((x) => x.id === 'as-marko').items) {
      const status = i.videoId === 'v-plank' && n % 2 === 0 ? 'skipped' : 'done'
      complete('pat-marko', 'as-marko', i.videoId, d, status, 8)
    }
  }
  // Josip: was adherent, silent for the last 9 days.
  if ([2, 4, 6].includes(iso(d)) && 25 >= n && n > 9) {
    for (const i of assignments.find((x) => x.id === 'as-josip').items) {
      complete('pat-josip', 'as-josip', i.videoId, d, 'done', 11)
    }
  }
}
// Ana today: v-quad done this morning, rest remaining (resume state).
complete('pat-ana', 'as-ana-knee', 'v-quad', now, 'done', 1)

for (const [pid, at] of Object.entries(lastActive)) {
  batch.update(db.doc(`patients/${pid}`), { lastActiveAt: at })
}

await batch.commit()
console.log(`seeded emulator as of ${ymd(now)} — physio tomislav@tendo.hr / ana@example.com, password ${PASSWORD}`)
