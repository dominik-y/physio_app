// Block C — physio scope: the role claim grants full clinical CRUD including
// the three cross-document batch side effects; no-claim users get nothing.
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest'
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing'
import {
  Timestamp,
  collection,
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  increment,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore'
import { UIDS, contexts, createEnv, firestores, future, seed } from './helpers.js'

let env, ctx, dbs

beforeAll(async () => {
  env = await createEnv('physio-scope')
  ctx = contexts(env)
  dbs = firestores(ctx)
})
afterAll(async () => {
  await env.cleanup()
})
beforeEach(async () => {
  await env.clearFirestore()
  await seed(env)
})

describe('Block C — physio CRUD', () => {
  it('C1 physio reads and writes every clinical collection', async () => {
    const db = dbs.physio
    await assertSucceeds(getDocs(collection(db, 'patients')))
    await assertSucceeds(getDocs(collection(db, 'videos')))
    await assertSucceeds(getDocs(collection(db, 'templates')))
    await assertSucceeds(getDocs(collection(db, 'assignments')))
    await assertSucceeds(getDocs(collection(db, 'completions')))
    await assertSucceeds(getDoc(doc(db, 'patientNotes/pat-ana')))
    await assertSucceeds(
      updateDoc(doc(db, 'patientNotes/pat-ana'), { notes: 'Ažurirano.' }),
    )
    await assertSucceeds(
      updateDoc(doc(db, 'videos/v-1'), { title: 'Klizanje petom — v2' }),
    )
    await assertSucceeds(
      updateDoc(doc(db, 'templates/t-1'), { name: 'Oporavak meniskusa v2' }),
    )
  })

  it('C2 watchAllByPatient path is a plain collection listen; collection-group stays sealed for everyone', async () => {
    // Flat collections by design: the physio dashboard listens on the
    // top-level completions collection. No rule matches collection-group
    // scope, so that query shape is dead even for physios — keep it that way.
    await assertSucceeds(getDocs(collection(dbs.physio, 'completions')))
    await assertFails(getDocs(collectionGroup(dbs.physio, 'completions')))
  })

  it('C3 addPatient batch: patient doc + invite doc', async () => {
    const db = dbs.physio
    const batch = writeBatch(db)
    batch.set(doc(db, 'patients/pat-new'), {
      name: 'Iva Šarić',
      email: 'iva@example.com',
      uid: null,
      primaryBodyPart: null,
      lastActiveAt: null,
      inviteCode: 'NEWC0DE',
      inviteExpiresAt: future(),
      createdAt: Timestamp.now(),
    })
    batch.set(doc(db, 'invites/NEWC0DE'), {
      patientId: 'pat-new',
      expiresAt: future(),
      createdAt: Timestamp.now(),
      createdBy: UIDS.physio,
      redeemed: false,
      redeemedBy: null,
      redeemedAt: null,
    })
    await assertSucceeds(batch.commit())
  })

  it('C4 regenerateInvite batch: new invite + delete old + patient denorm update', async () => {
    const db = dbs.physio
    const batch = writeBatch(db)
    batch.set(doc(db, 'invites/RGNC0DE'), {
      patientId: 'pat-luka',
      expiresAt: future(),
      createdAt: Timestamp.now(),
      createdBy: UIDS.physio,
      redeemed: false,
      redeemedBy: null,
      redeemedAt: null,
    })
    batch.delete(doc(db, 'invites/LK73FQ9'))
    batch.update(doc(db, 'patients/pat-luka'), {
      inviteCode: 'RGNC0DE',
      inviteExpiresAt: future(),
    })
    await assertSucceeds(batch.commit())
  })

  it('C5 assignment-create batch with usageCount increments', async () => {
    const db = dbs.physio
    const batch = writeBatch(db)
    batch.set(doc(db, 'assignments/as-new'), {
      patientId: 'pat-ana',
      type: 'single',
      name: 'Izdržaj',
      sourceTemplateId: null,
      bodyParts: ['Knee'],
      daysOfWeek: [2, 4],
      items: [
        {
          videoId: 'v-1',
          order: 0,
          sets: 2,
          reps: 10,
          holdSec: 20,
          overridden: false,
          title: 'Izdržaj',
          durationSec: 30,
          bodyPart: 'Knee',
          mediaUrl: 'https://example.com/v-1.mp4',
        },
      ],
      active: true,
      seenByPatient: false,
      createdAt: Timestamp.now(),
    })
    batch.update(doc(db, 'videos/v-1'), { usageCount: increment(1) })
    await assertSucceeds(batch.commit())
  })

  it('C6 deletePatient cascade batch', async () => {
    const db = dbs.physio
    const batch = writeBatch(db)
    batch.delete(doc(db, 'completions/2026-08-25_as-ana_v-1'))
    batch.delete(doc(db, 'assignments/as-ana'))
    batch.delete(doc(db, 'patientNotes/pat-ana'))
    batch.delete(doc(db, 'patients/pat-ana'))
    await assertSucceeds(batch.commit())
  })

  it('C7 physios collection is read-only even for physios', async () => {
    const db = dbs.physio
    await assertSucceeds(getDoc(doc(db, 'physios/physio-uid')))
    await assertFails(
      setDoc(doc(db, 'physios/other'), {
        name: 'x',
        email: 'x@x.hr',
        createdAt: Timestamp.now(),
      }),
    )
    await assertFails(
      updateDoc(doc(db, 'physios/physio-uid'), { name: 'renamed' }),
    )
  })
})

describe('Block C — no-claim users are shut out', () => {
  it('C8 an authenticated unlinked user reaches nothing clinical', async () => {
    const db = dbs.fresh
    await assertFails(getDocs(collection(db, 'patients')))
    await assertFails(getDoc(doc(db, 'patients/pat-ana')))
    await assertFails(getDocs(collection(db, 'videos')))
    await assertFails(getDocs(collection(db, 'templates')))
    await assertFails(getDocs(collection(db, 'assignments')))
    await assertFails(getDocs(collection(db, 'completions')))
    await assertFails(getDoc(doc(db, 'patientNotes/pat-ana')))
    await assertFails(deleteDoc(doc(db, 'assignments/as-ana')))
  })

  it('C9 anonymous users reach nothing at all', async () => {
    const db = dbs.anon
    await assertFails(getDoc(doc(db, 'patients/pat-ana')))
    await assertFails(getDocs(collection(db, 'assignments')))
    await assertFails(getDoc(doc(db, 'videos/v-1')))
  })
})
