// Block B — patient isolation: a linked patient can reach exactly their own
// world and nothing else; completions are shape-validated at the rule level.
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest'
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing'
import {
  Timestamp,
  collection,
  collectionGroup,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore'
import { UIDS, contexts, createEnv, firestores, seed } from './helpers.js'

let env, ctx, dbs

beforeAll(async () => {
  env = await createEnv('patient-isolation')
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

const completion = (over = {}) => ({
  patientId: 'pat-ana',
  date: '2026-08-26',
  assignmentId: 'as-ana',
  videoId: 'v-1',
  status: 'done',
  at: Timestamp.now(),
  ...over,
})
const completionId = (c) => `${c.date}_${c.assignmentId}_${c.videoId}`

describe('Block B — own data', () => {
  it('B1 patient reads own patient doc; not another\'s', async () => {
    const db = dbs.ana
    await assertSucceeds(getDoc(doc(db, 'patients/pat-ana')))
    await assertFails(getDoc(doc(db, 'patients/pat-marko')))
  })

  it('B2 patient queries patients only with own-uid filter', async () => {
    const db = dbs.ana
    await assertSucceeds(
      getDocs(query(collection(db, 'patients'), where('uid', '==', UIDS.ana))),
    )
    await assertFails(getDocs(collection(db, 'patients')))
  })

  it('B3 patient lists own assignments; not another\'s; never unfiltered', async () => {
    const db = dbs.ana
    await assertSucceeds(
      getDocs(
        query(
          collection(db, 'assignments'),
          where('patientId', '==', 'pat-ana'),
        ),
      ),
    )
    await assertFails(
      getDocs(
        query(
          collection(db, 'assignments'),
          where('patientId', '==', 'pat-marko'),
        ),
      ),
    )
    await assertFails(getDocs(collection(db, 'assignments')))
  })

  it('B4 patient may only flip seenByPatient to true on own assignment', async () => {
    const db = dbs.ana
    await assertSucceeds(
      updateDoc(doc(db, 'assignments/as-ana'), { seenByPatient: true }),
    )
    await assertFails(
      updateDoc(doc(db, 'assignments/as-ana'), { seenByPatient: false }),
    )
    await assertFails(
      updateDoc(doc(db, 'assignments/as-ana'), { active: false }),
    )
    await assertFails(
      updateDoc(doc(db, 'assignments/as-marko'), { seenByPatient: true }),
    )
  })

  it('B5 completion create with correct deterministic ID succeeds; upsert overwrite succeeds', async () => {
    const db = dbs.ana
    const c = completion()
    await assertSucceeds(setDoc(doc(db, `completions/${completionId(c)}`), c))
    await assertSucceeds(
      setDoc(doc(db, `completions/${completionId(c)}`), {
        ...c,
        status: 'skipped',
      }),
    )
  })

  it('B6 completion with mismatched doc ID is rejected', async () => {
    const db = dbs.ana
    await assertFails(
      setDoc(doc(db, 'completions/some-random-id'), completion()),
    )
  })

  it('B7 completion with invalid status or malformed date is rejected', async () => {
    const db = dbs.ana
    const bad = completion({ status: 'maybe' })
    await assertFails(setDoc(doc(db, `completions/${completionId(bad)}`), bad))
    const badDate = completion({ date: '26-08-2026' })
    await assertFails(
      setDoc(doc(db, `completions/${completionId(badDate)}`), badDate),
    )
  })

  it('B8 completion for another patient or another patient\'s assignment is rejected', async () => {
    const db = dbs.ana
    const forMarko = completion({ patientId: 'pat-marko', assignmentId: 'as-marko' })
    await assertFails(
      setDoc(doc(db, `completions/${completionId(forMarko)}`), forMarko),
    )
    // Own patientId but an assignment that belongs to Marko.
    const crossed = completion({ assignmentId: 'as-marko' })
    await assertFails(
      setDoc(doc(db, `completions/${completionId(crossed)}`), crossed),
    )
  })

  it('B9 completion with smuggled extra fields is rejected', async () => {
    const db = dbs.ana
    const c = completion({ adminOverride: true })
    await assertFails(setDoc(doc(db, `completions/${completionId(c)}`), c))
  })

  it('B10 record batch: completion + lastActiveAt-only patient update succeeds', async () => {
    const db = dbs.ana
    const c = completion()
    const batch = writeBatch(db)
    batch.set(doc(db, `completions/${completionId(c)}`), c)
    batch.update(doc(db, 'patients/pat-ana'), { lastActiveAt: Timestamp.now() })
    await assertSucceeds(batch.commit())
  })

  it('B11 patient cannot touch other patient-doc fields, and lastActiveAt must be a timestamp', async () => {
    const db = dbs.ana
    await assertFails(
      updateDoc(doc(db, 'patients/pat-ana'), { name: 'Ana Renamed' }),
    )
    await assertFails(
      updateDoc(doc(db, 'patients/pat-ana'), { lastActiveAt: 'now' }),
    )
  })

  it('B12 patient reads own completions with filter; not Marko\'s; never unfiltered', async () => {
    const db = dbs.ana
    await assertSucceeds(
      getDocs(
        query(
          collection(db, 'completions'),
          where('patientId', '==', 'pat-ana'),
        ),
      ),
    )
    await assertFails(
      getDocs(
        query(
          collection(db, 'completions'),
          where('patientId', '==', 'pat-marko'),
        ),
      ),
    )
    await assertFails(getDocs(collection(db, 'completions')))
  })

  it('B13 collection-group completions query is denied for patients', async () => {
    await assertFails(getDocs(collectionGroup(dbs.ana, 'completions')))
  })
})

describe('Block B — denormalization contract', () => {
  it('B14 patient cannot read videos, templates, physios, or patientNotes', async () => {
    const db = dbs.ana
    await assertFails(getDoc(doc(db, 'videos/v-1')))
    await assertFails(getDocs(collection(db, 'videos')))
    await assertFails(getDoc(doc(db, 'templates/t-1')))
    await assertFails(getDoc(doc(db, 'physios/physio-uid')))
    await assertFails(getDoc(doc(db, 'patientNotes/pat-ana')))
  })

  it('B15 patient cannot write videos or templates', async () => {
    const db = dbs.ana
    await assertFails(
      setDoc(doc(db, 'videos/v-evil'), { title: 'x', bodyPart: 'Knee' }),
    )
    await assertFails(
      updateDoc(doc(db, 'templates/t-1'), { name: 'hijacked' }),
    )
  })
})
