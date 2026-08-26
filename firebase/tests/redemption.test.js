// Block A — invite redemption (the declared highest-risk piece).
// The redemption is a 2-doc client batch; rules enforce atomicity in both
// directions via getAfter cross-checks. These tests decide the rules-only
// vs Cloud Function go/no-go.
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest'
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing'
import {
  collection,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  writeBatch,
} from 'firebase/firestore'
import { UIDS, contexts, createEnv, firestores, seed } from './helpers.js'

let env, ctx, dbs

beforeAll(async () => {
  env = await createEnv('redemption')
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

// The client redemption batch: mark the invite redeemed + claim the patient
// doc, atomically. `uid` is who signs the batch's writes; overrides let each
// test bend one leg of it.
function redemptionBatch(
  db,
  {
    code = 'LK73FQ9',
    patientId = 'pat-luka',
    redeemedBy = UIDS.fresh,
    claimUid = UIDS.fresh,
    inviteExtra = {},
    patientExtra = {},
  } = {},
) {
  const batch = writeBatch(db)
  batch.update(doc(db, `invites/${code}`), {
    redeemed: true,
    redeemedBy,
    redeemedAt: serverTimestamp(),
    ...inviteExtra,
  })
  batch.update(doc(db, `patients/${patientId}`), {
    uid: claimUid,
    ...patientExtra,
  })
  return batch.commit()
}

describe('Block A — invite redemption', () => {
  it('A1 happy path: full batch with a valid code succeeds', async () => {
    await assertSucceeds(redemptionBatch(dbs.fresh))
  })

  it('A2 stolen-code reuse: second redeemer is rejected atomically', async () => {
    await assertSucceeds(redemptionBatch(dbs.fresh))
    await assertFails(
      redemptionBatch(dbs.thief, {
        redeemedBy: UIDS.thief,
        claimUid: UIDS.thief,
      }),
    )
  })

  it('A3 expired code is rejected', async () => {
    await assertFails(
      redemptionBatch(dbs.fresh, {
        code: 'OLDCODE',
        patientId: 'pat-old',
      }),
    )
  })

  it('A4 partial batch (patient claim without invite consumption) is rejected', async () => {
    const db = dbs.fresh
    const batch = writeBatch(db)
    batch.update(doc(db, 'patients/pat-luka'), { uid: UIDS.fresh })
    await assertFails(batch.commit())
  })

  it('A5 partial batch (invite consumption without patient claim) is rejected', async () => {
    const db = dbs.fresh
    const batch = writeBatch(db)
    batch.update(doc(db, 'invites/LK73FQ9'), {
      redeemed: true,
      redeemedBy: UIDS.fresh,
      redeemedAt: serverTimestamp(),
    })
    await assertFails(batch.commit())
  })

  it('A6a redeemedBy must be the caller', async () => {
    await assertFails(
      redemptionBatch(dbs.fresh, { redeemedBy: UIDS.thief }),
    )
  })

  it('A6b claimed patient uid must be the caller', async () => {
    await assertFails(
      redemptionBatch(dbs.fresh, { claimUid: UIDS.thief }),
    )
  })

  it('A7a extra fields smuggled onto the patient doc are rejected', async () => {
    await assertFails(
      redemptionBatch(dbs.fresh, {
        patientExtra: { name: 'Hacked Name' },
      }),
    )
  })

  it('A7b extra fields smuggled onto the invite doc are rejected', async () => {
    await assertFails(
      redemptionBatch(dbs.fresh, {
        inviteExtra: { patientId: 'pat-ana' },
      }),
    )
  })

  it('A8 a stale code (not the patient\'s current inviteCode) is rejected', async () => {
    await assertFails(
      redemptionBatch(dbs.fresh, { code: 'STALE01' }),
    )
  })

  it('A9 an already-linked patient doc cannot be re-claimed with a fresh invite', async () => {
    // Physio mistakenly regenerates an invite for an already-linked patient;
    // redeeming it must not steal the account (uid == null precondition).
    await env.withSecurityRulesDisabled(async (c) => {
      const db = c.firestore()
      const batch = writeBatch(db)
      batch.set(doc(db, 'invites/FRESHAN'), {
        patientId: 'pat-ana',
        expiresAt: new Date(Date.now() + 14 * 864e5),
        createdAt: new Date(),
        createdBy: UIDS.physio,
        redeemed: false,
        redeemedBy: null,
        redeemedAt: null,
      })
      batch.update(doc(db, 'patients/pat-ana'), { inviteCode: 'FRESHAN' })
      await batch.commit()
    })
    await assertFails(
      redemptionBatch(dbs.thief, {
        code: 'FRESHAN',
        patientId: 'pat-ana',
        redeemedBy: UIDS.thief,
        claimUid: UIDS.thief,
      }),
    )
  })
})

describe('Block A — invite read access', () => {
  it('A10 any signed-in user can get an unredeemed, unexpired invite by ID', async () => {
    await assertSucceeds(getDoc(doc(dbs.fresh, 'invites/LK73FQ9')))
  })

  it('A11 a redeemed invite is not readable by non-physios', async () => {
    await assertFails(getDoc(doc(dbs.fresh, 'invites/USEDCOD')))
  })

  it('A12 an expired invite is not readable by non-physios', async () => {
    await assertFails(getDoc(doc(dbs.fresh, 'invites/OLDCODE')))
  })

  it('A13 unauthenticated users cannot read invites at all', async () => {
    await assertFails(getDoc(doc(dbs.anon, 'invites/LK73FQ9')))
  })

  it('A14 non-physios cannot list invites', async () => {
    await assertFails(getDocs(collection(dbs.fresh, 'invites')))
  })

  it('A15 physio can list invites', async () => {
    await assertSucceeds(getDocs(collection(dbs.physio, 'invites')))
  })
})
