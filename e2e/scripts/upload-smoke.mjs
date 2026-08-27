// Upload-pipeline smoke vs the emulator suite: a physio uploads a real mp4
// through the sheet (web path: no compression, straight to the Storage
// emulator), the doc lands 'ready' with a download URL, the clip is
// assignable, and the patient can actually play it. Run manually:
//   node scripts/upload-smoke.mjs
// Requires: emulators up + freshly seeded, web_firebase served on :7358.
import { chromium } from '@playwright/test'
import { fileURLToPath } from 'node:url'
import path from 'node:path'

const here = path.dirname(fileURLToPath(import.meta.url))
const CLIP = path.resolve(here, '../../app/assets/videos/tendo_reel8.mp4')
const TITLE = 'Smoke čučanj'

const outDir = `${process.env.CLAUDE_JOB_DIR ?? '/tmp'}/tmp`
const shot = (p, name) => p.screenshot({ path: `${outDir}/${name}.png` })
let failures = 0
const check = (ok, label) => {
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${label}`)
  if (!ok) failures++
}

async function tapLabel(page, label, align = 'center') {
  const sel =
    `flt-semantics[flt-tappable]:has-text("${label}"), ` +
    `flt-semantics[flt-tappable][aria-label*="${label}" i]`
  await page.locator(sel).last().waitFor({ state: 'attached', timeout: 15000 })
  const all = await page.locator(sel).all()
  for (const n of all.reverse()) {
    const box = await n.boundingBox()
    if (box && box.width > 0 && box.y >= 0 && box.y < 932) {
      const x = align === 'right' ? box.x + box.width - 22 : box.x + box.width / 2
      await page.mouse.click(x, box.y + box.height / 2)
      return
    }
  }
  await page.locator(sel).last().evaluate((e) => {
    e.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }))
  })
}

// Fill the last attached input (the sheet's title field sits above the
// page's own fields in DOM order); verify-and-retry like auth-smoke.
async function fillLastField(page, value) {
  const fields = page.locator('flt-semantics input, flt-semantics textarea')
  await fields.last().waitFor({ state: 'attached', timeout: 15000 })
  const field = fields.last()
  for (let attempt = 0; attempt < 4; attempt++) {
    await field.click({ force: true })
    await field.fill(value)
    await page.waitForTimeout(300)
    if ((await field.inputValue().catch(() => '')) === value) return
  }
  throw new Error('fillLastField never took value')
}

async function fillField(page, index, value) {
  const field = page.locator('flt-semantics input, flt-semantics textarea').nth(index)
  await field.waitFor({ state: 'attached', timeout: 15000 })
  for (let attempt = 0; attempt < 4; attempt++) {
    await field.click({ force: true })
    await field.fill(value)
    await page.waitForTimeout(300)
    if ((await field.inputValue().catch(() => '')) === value) return
  }
  throw new Error(`fillField(${index}) never took value`)
}

const hasLabel = (page, label, timeout = 20000) =>
  page
    .locator(`flt-semantics:has-text("${label}")`)
    .last()
    .waitFor({ state: 'attached', timeout })
    .then(() => true)
    .catch(() => false)

const fs = (p) =>
  fetch(`http://localhost:8080/v1/projects/demo-tendo/databases/(default)/documents/${p}`, {
    headers: { Authorization: 'Bearer owner' },
  }).then((r) => r.json())

async function signIn(page, email, password) {
  await fillField(page, 0, email)
  await fillField(page, 1, password)
  await tapLabel(page, 'Prijavi se')
  await page.waitForTimeout(4000)
}

async function signOut(page) {
  await tapLabel(page, 'Profil', 'right')
  await page.waitForTimeout(1000)
  await tapLabel(page, 'Odjava')
  await page.waitForTimeout(2500)
}

const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 430, height: 932 } })
const errors = []
page.on('console', (m) => {
  if (m.type() === 'error') errors.push(m.text())
})

await page.goto('http://localhost:7358/', { waitUntil: 'networkidle' })
const placeholder = page.locator('flt-semantics-placeholder')
await placeholder.waitFor({ state: 'attached', timeout: 20000 })
await placeholder.evaluate((el) => el.click())
await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout: 20000 })
await page.waitForTimeout(1500)

// ---- 1. physio signs in, opens the upload sheet
await signIn(page, 'tomislav@tendo.hr', 'tendo1')
check(await hasLabel(page, 'Ana Kovačević'), 'physio lands on patients list')
await tapLabel(page, 'Videoteka')
await page.waitForTimeout(1500)
await tapLabel(page, 'Snimi ili učitaj video')
await page.waitForTimeout(1200)
await shot(page, 'up-1-sheet')

// ---- 2. attach a real mp4 through the picker (web file input)
const chooserPromise = page.waitForEvent('filechooser', { timeout: 15000 })
await tapLabel(page, 'Iz galerije')
const chooser = await chooserPromise
await chooser.setFiles(CLIP)
check(await hasLabel(page, 'Video dodan'), 'clip attaches (duration probed)')
await shot(page, 'up-2-attached')

// ---- 3. title + submit → real upload against the Storage emulator
await fillLastField(page, TITLE)
await tapLabel(page, 'Komprimiraj i učitaj')
check(await hasLabel(page, 'Dodano u videoteku', 45000), 'upload completes')
await page.waitForTimeout(1500) // sheet auto-closes
check(await hasLabel(page, TITLE), 'new video appears in the library')
await shot(page, 'up-3-library')

// ---- 4. backend truth: doc is ready with URLs, bytes are in Storage
const docs = await fs('videos')
const doc = (docs.documents ?? []).find(
  (d) => d.fields?.title?.stringValue === TITLE,
)
const f = doc?.fields ?? {}
check(!!doc, 'video doc exists in Firestore')
check(f.status?.stringValue === 'ready', "doc status is 'ready'")
check(!!f.mediaUrl?.stringValue, 'doc has a mediaUrl')
const storagePath = f.storagePath?.stringValue ?? ''
check(/^clinics\/tendo\/videos\/.+\/video\.mp4$/.test(storagePath), `storagePath shape (${storagePath})`)
const meta = await fetch(
  `http://localhost:9199/v0/b/demo-tendo.appspot.com/o/${encodeURIComponent(storagePath)}`,
  { headers: { Authorization: 'Bearer owner' } },
).then((r) => r.json())
check(Number(meta.size) > 1000000, `bytes landed in Storage (${meta.size ?? 'missing'})`)

// ---- 5. the clip plays for the physio (real <video> element, no demo fake)
await tapLabel(page, TITLE)
await page.waitForTimeout(3000)
const physioVideo = await page.locator('video').count()
check(physioVideo > 0, 'physio playback uses a real <video> element')
check(!(await hasLabel(page, 'Video je trenutačno nedostupan', 1500)), 'no unavailable fallback')
await shot(page, 'up-4-physio-playback')
await tapLabel(page, 'Zatvori')
await page.waitForTimeout(1000)

// ---- 6. assign it to Ana as a single video (snapshot carries the URL)
await tapLabel(page, 'Pacijenti')
await page.waitForTimeout(1200)
await tapLabel(page, 'Ana Kovačević')
await page.waitForTimeout(1200)
await tapLabel(page, 'Zadaj vježbe')
await page.waitForTimeout(1200)
await tapLabel(page, 'Pošalji jedan video')
await page.waitForTimeout(1200)
await tapLabel(page, TITLE)
await page.waitForTimeout(600)
await tapLabel(page, 'Pošalji: Ana')
await page.waitForTimeout(2500)
const assignments = await fs('assignments')
const assigned = (assignments.documents ?? []).find(
  (d) => d.fields?.name?.stringValue === TITLE,
)
const item0 = assigned?.fields?.items?.arrayValue?.values?.[0]?.mapValue?.fields ?? {}
check(!!assigned, 'assignment doc created')
check(!!item0.mediaUrl?.stringValue, 'assignment item snapshots the mediaUrl')
await shot(page, 'up-5-assigned')

// ---- 7. Ana sees it and it actually plays
// The assign flow lands on Ana's detail page (no avatar there) — reload to
// the root. Emulator quirk: on reload the JS SDK's session restore races
// useAuthEmulator and validates against prod endpoints with the fake API
// key, so the session may be dropped (doesn't happen with real config) —
// handle landing on either the gate or the patients list.
await page.goto('http://localhost:7358/', { waitUntil: 'networkidle' })
const ph = page.locator('flt-semantics-placeholder')
await ph.waitFor({ state: 'attached', timeout: 20000 })
await ph.evaluate((el) => el.click())
await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout: 20000 })
await page.waitForTimeout(3500)
await shot(page, 'up-5b-after-reload')
if (!(await hasLabel(page, 'Prijava', 4000))) await signOut(page)
await signIn(page, 'ana@example.com', 'tendo1')
check(await hasLabel(page, TITLE), "new video shows on Ana's home")
await shot(page, 'up-6-ana-home')
await tapLabel(page, TITLE)
await page.waitForTimeout(3000)
const patientVideo = await page.locator('video').count()
check(patientVideo > 0, 'patient playback uses a real <video> element')
check(!(await hasLabel(page, 'Video je trenutačno nedostupan', 1500)), 'no unavailable fallback for Ana')
await shot(page, 'up-7-ana-playback')

const relevant = errors.filter((e) => !e.includes('favicon') && !e.includes('DevTools'))
console.log(relevant.length ? `console errors (${relevant.length}):` : 'no console errors')
relevant.slice(0, 5).forEach((e) => console.log('  ', e.slice(0, 200)))
await browser.close()
process.exit(failures ? 1 : 0)
