import { readFileSync } from 'node:fs'
import { initializeTestEnvironment } from '@firebase/rules-unit-testing'
import { doc, setDoc, Timestamp } from 'firebase/firestore'

// Unique project per test file: separate rules-unit-testing environments in
// one emulator run never share Firestore app state.
export const projectId = (suffix) => `tendo-rules-${suffix}`

// Test principals. Physio identity is the custom claim, patient identity is
// the uid written onto the patient doc by the redemption batch.
export const UIDS = {
  physio: 'physio-uid',
  ana: 'ana-uid', // linked patient (pat-ana)
  marko: 'marko-uid', // other linked patient (pat-marko)
  fresh: 'fresh-uid', // authenticated, unlinked — the redemption candidate
  thief: 'thief-uid', // second redemption candidate for reuse races
}

export const future = (days = 14) =>
  Timestamp.fromDate(new Date(Date.now() + days * 864e5))
export const past = (days = 1) =>
  Timestamp.fromDate(new Date(Date.now() - days * 864e5))

export async function createEnv(suffix) {
  return initializeTestEnvironment({
    projectId: projectId(suffix),
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
    storage: {
      rules: readFileSync(new URL('../storage.rules', import.meta.url), 'utf8'),
    },
  })
}

export function contexts(env) {
  return {
    physio: env.authenticatedContext(UIDS.physio, { role: 'physio' }),
    ana: env.authenticatedContext(UIDS.ana),
    marko: env.authenticatedContext(UIDS.marko),
    fresh: env.authenticatedContext(UIDS.fresh),
    thief: env.authenticatedContext(UIDS.thief),
    anon: env.unauthenticatedContext(),
  }
}

// context.firestore()/storage() must be called exactly ONCE per context —
// a second call throws "Firestore has already been started". Cache the
// instances up front and use these in tests, never ctx.X.firestore().
export function firestores(ctx) {
  return Object.fromEntries(
    Object.entries(ctx).map(([name, c]) => [name, c.firestore()]),
  )
}
export function storages(ctx) {
  return Object.fromEntries(
    Object.entries(ctx).map(([name, c]) => [name, c.storage()]),
  )
}

// Fixture world mirroring DemoData shapes: two linked patients, one
// unredeemed invite (Luka), one expired, one already redeemed, one stale
// (no longer the patient's current code after a regenerate).
export async function seed(env) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore()
    const now = Timestamp.now()

    await setDoc(doc(db, 'patients/pat-ana'), {
      name: 'Ana Kovačević',
      email: 'ana@example.com',
      uid: UIDS.ana,
      primaryBodyPart: 'Knee',
      lastActiveAt: now,
      inviteCode: null,
      inviteExpiresAt: null,
      createdAt: now,
    })
    await setDoc(doc(db, 'patients/pat-marko'), {
      name: 'Marko Horvat',
      email: 'marko@example.com',
      uid: UIDS.marko,
      primaryBodyPart: 'Lower back',
      lastActiveAt: now,
      inviteCode: null,
      inviteExpiresAt: null,
      createdAt: now,
    })
    await setDoc(doc(db, 'patients/pat-luka'), {
      name: 'Luka Babić',
      email: 'luka@example.com',
      uid: null,
      primaryBodyPart: null,
      lastActiveAt: null,
      inviteCode: 'LK73FQ9',
      inviteExpiresAt: future(),
      createdAt: now,
    })
    await setDoc(doc(db, 'patients/pat-old'), {
      name: 'Petra Novak',
      email: 'petra@example.com',
      uid: null,
      primaryBodyPart: null,
      lastActiveAt: null,
      inviteCode: 'OLDCODE',
      inviteExpiresAt: past(),
      createdAt: past(20),
    })

    await setDoc(doc(db, 'invites/LK73FQ9'), {
      patientId: 'pat-luka',
      expiresAt: future(),
      createdAt: now,
      createdBy: UIDS.physio,
      redeemed: false,
      redeemedBy: null,
      redeemedAt: null,
    })
    await setDoc(doc(db, 'invites/OLDCODE'), {
      patientId: 'pat-old',
      expiresAt: past(),
      createdAt: past(20),
      createdBy: UIDS.physio,
      redeemed: false,
      redeemedBy: null,
      redeemedAt: null,
    })
    await setDoc(doc(db, 'invites/USEDCOD'), {
      patientId: 'pat-ana',
      expiresAt: future(),
      createdAt: now,
      createdBy: UIDS.physio,
      redeemed: true,
      redeemedBy: UIDS.ana,
      redeemedAt: now,
    })
    // Left over from a regenerate: still unredeemed, but pat-luka's current
    // code is LK73FQ9 — redeeming this one must fail the getAfter cross-check.
    await setDoc(doc(db, 'invites/STALE01'), {
      patientId: 'pat-luka',
      expiresAt: future(),
      createdAt: past(2),
      createdBy: UIDS.physio,
      redeemed: false,
      redeemedBy: null,
      redeemedAt: null,
    })

    await setDoc(doc(db, 'physios/physio-uid'), {
      name: 'Tomislav Perić',
      email: 'tomislav@tendo.hr',
      createdAt: now,
    })

    await setDoc(doc(db, 'videos/v-1'), {
      title: 'Klizanje petom',
      bodyPart: 'Knee',
      durationSec: 60,
      visibility: 'library',
      privateToPatientId: null,
      usageCount: 1,
      createdAt: now,
      storagePath: 'clinics/tendo/videos/v-1/video.mp4',
      mediaUrl: 'https://example.com/v-1.mp4',
      status: 'ready',
    })
    await setDoc(doc(db, 'templates/t-1'), {
      name: 'Oporavak meniskusa',
      bodyPart: 'Knee',
      items: [{ videoId: 'v-1', order: 0, sets: 3, reps: 10, holdSec: 0 }],
      createdAt: now,
    })

    await setDoc(doc(db, 'assignments/as-ana'), {
      patientId: 'pat-ana',
      type: 'protocol',
      name: 'Oporavak meniskusa — faza 1',
      sourceTemplateId: 't-1',
      bodyParts: ['Knee'],
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      items: [
        {
          videoId: 'v-1',
          order: 0,
          sets: 3,
          reps: 10,
          holdSec: 0,
          overridden: false,
          title: 'Klizanje petom',
          durationSec: 60,
          bodyPart: 'Knee',
          mediaUrl: 'https://example.com/v-1.mp4',
        },
      ],
      active: true,
      seenByPatient: false,
      createdAt: now,
    })
    await setDoc(doc(db, 'assignments/as-marko'), {
      patientId: 'pat-marko',
      type: 'single',
      name: 'Most',
      sourceTemplateId: null,
      bodyParts: ['Lower back'],
      daysOfWeek: [1, 3, 5],
      items: [
        {
          videoId: 'v-1',
          order: 0,
          sets: 3,
          reps: 8,
          holdSec: 0,
          overridden: false,
          title: 'Most',
          durationSec: 45,
          bodyPart: 'Lower back',
          mediaUrl: 'https://example.com/v-1.mp4',
        },
      ],
      active: true,
      seenByPatient: true,
      createdAt: now,
    })

    await setDoc(doc(db, 'completions/2026-08-25_as-ana_v-1'), {
      patientId: 'pat-ana',
      date: '2026-08-25',
      assignmentId: 'as-ana',
      videoId: 'v-1',
      status: 'done',
      at: now,
    })
    await setDoc(doc(db, 'completions/2026-08-25_as-marko_v-1'), {
      patientId: 'pat-marko',
      date: '2026-08-25',
      assignmentId: 'as-marko',
      videoId: 'v-1',
      status: 'done',
      at: now,
    })

    // Clinical notes live in a physio-only collection (owner decision
    // 2026-08-26): patients must never read these.
    await setDoc(doc(db, 'patientNotes/pat-ana'), {
      notes: 'Oprez s desnim koljenom — ne forsirati fleksiju.',
      updatedAt: now,
    })
  })
}
