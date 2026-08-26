// Block D — Storage: physio-claim writes with type checks, authenticated
// reads, and the delete rule split from create/update (request.resource is
// null on deletes — a combined `allow write` denies every delete).
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest'
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing'
import {
  deleteObject,
  getBytes,
  ref,
  uploadBytes,
} from 'firebase/storage'
import { contexts, createEnv, storages } from './helpers.js'

let env, ctx, st

const VIDEO_PATH = 'clinics/tendo/videos/v-1/video.mp4'
const POSTER_PATH = 'clinics/tendo/videos/v-1/poster.jpg'
const mp4Bytes = new Uint8Array([0, 0, 0, 24, 0x66, 0x74, 0x79, 0x70])

beforeAll(async () => {
  env = await createEnv('storage')
  ctx = contexts(env)
  st = storages(ctx)
})
afterAll(async () => {
  await env.cleanup()
})
beforeEach(async () => {
  await env.clearStorage()
  // Seed one existing object for read/delete tests.
  await env.withSecurityRulesDisabled(async (c) => {
    await uploadBytes(ref(c.storage(), VIDEO_PATH), mp4Bytes, {
      contentType: 'video/mp4',
    })
  })
})

describe('Block D — Storage', () => {
  it('D1 physio uploads video.mp4 with video contentType', async () => {
    await assertSucceeds(
      uploadBytes(
        ref(st.physio, 'clinics/tendo/videos/v-2/video.mp4'),
        mp4Bytes,
        { contentType: 'video/mp4' },
      ),
    )
  })

  it('D2 physio uploads poster.jpg with image contentType', async () => {
    await assertSucceeds(
      uploadBytes(ref(st.physio, POSTER_PATH), mp4Bytes, {
        contentType: 'image/jpeg',
      }),
    )
  })

  it('D3 patient upload is denied', async () => {
    await assertFails(
      uploadBytes(
        ref(st.ana, 'clinics/tendo/videos/v-3/video.mp4'),
        mp4Bytes,
        { contentType: 'video/mp4' },
      ),
    )
  })

  it('D4 wrong contentType per filename is denied even for physio', async () => {
    await assertFails(
      uploadBytes(
        ref(st.physio, 'clinics/tendo/videos/v-4/video.mp4'),
        mp4Bytes,
        { contentType: 'text/plain' },
      ),
    )
    await assertFails(
      uploadBytes(
        ref(st.physio, 'clinics/tendo/videos/v-4/poster.jpg'),
        mp4Bytes,
        { contentType: 'video/mp4' },
      ),
    )
  })

  it('D5 unexpected filenames inside a video folder are denied', async () => {
    await assertFails(
      uploadBytes(
        ref(st.physio, 'clinics/tendo/videos/v-5/evil.exe'),
        mp4Bytes,
        { contentType: 'video/mp4' },
      ),
    )
  })

  it('D6 writes outside clinics/tendo/videos are denied', async () => {
    await assertFails(
      uploadBytes(ref(st.physio, 'other/place/file.mp4'), mp4Bytes, {
        contentType: 'video/mp4',
      }),
    )
  })

  it('D7 authenticated users can read; anonymous cannot', async () => {
    await assertSucceeds(getBytes(ref(st.ana, VIDEO_PATH)))
    await assertFails(getBytes(ref(st.anon, VIDEO_PATH)))
  })

  it('D8 physio can delete; patient cannot (split delete rule)', async () => {
    await assertFails(deleteObject(ref(st.ana, VIDEO_PATH)))
    await assertSucceeds(deleteObject(ref(st.physio, VIDEO_PATH)))
  })
})

// NOTE: the 100 MB size cap is in the rules but not covered here — uploading
// 100+ MB through the emulator per run is not worth the wall-clock. Covered
// by rule review + the day-8 device pass.
