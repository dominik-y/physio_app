// Auth-gate smoke vs the emulator suite: real login, sign-out, and a full
// invite redemption (LK7-3FQ9 → Luka), driven through the built web
// Firebase flavor. Not part of the regular suite — run manually:
//   node scripts/auth-smoke.mjs
// Requires: emulators up + freshly seeded, web_firebase served on :7358.
import { chromium } from '@playwright/test'

const outDir = `${process.env.CLAUDE_JOB_DIR ?? '/tmp'}/tmp`
const shot = (p, name) => p.screenshot({ path: `${outDir}/${name}.png` })
let failures = 0
const check = (ok, label) => {
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${label}`)
  if (!ok) failures++
}

async function tapLabel(page, label, align = 'center') {
  const tappable = page
    .locator(
      `flt-semantics[flt-tappable]:has-text("${label}"), ` +
        `flt-semantics[flt-tappable][aria-label*="${label}" i]`,
    )
    .last()
  await tappable.waitFor({ state: 'attached', timeout: 15000 })
  // Real coordinate click through the glass pane: the synthetic MouseEvent
  // dispatch stops registering once a semantic <input> has been focused.
  // Old screens can leave detached/off-screen semantics twins behind, so
  // click the innermost match that actually has an on-screen box.
  const all = await page
    .locator(
      `flt-semantics[flt-tappable]:has-text("${label}"), ` +
        `flt-semantics[flt-tappable][aria-label*="${label}" i]`,
    )
    .all()
  for (const n of all.reverse()) {
    const box = await n.boundingBox()
    if (box && box.width > 0 && box.y >= 0 && box.y < 932) {
      const x = align === 'right' ? box.x + box.width - 22 : box.x + box.width / 2
      await page.mouse.click(x, box.y + box.height / 2)
      return
    }
  }
  await tappable.evaluate((e) => {
    e.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }))
  })
}

// Semantic text fields render as real <input>/<textarea> elements inside
// flt-semantics. Fill by DOM order within the current screen.
async function fillField(page, index, value) {
  const field = page.locator('flt-semantics input, flt-semantics textarea').nth(index)
  await field.waitFor({ state: 'attached', timeout: 15000 })
  // Fills race Flutter's editing-state sync and occasionally no-op — verify
  // the value actually landed and retry.
  for (let attempt = 0; attempt < 4; attempt++) {
    await field.click({ force: true })
    await field.fill(value)
    await page.waitForTimeout(300)
    if ((await field.inputValue().catch(() => '')) === value) return
  }
  throw new Error(`fillField(${index}) never took value`)
}

const hasLabel = (page, label) =>
  page
    .locator(`flt-semantics:has-text("${label}")`)
    .last()
    .waitFor({ state: 'attached', timeout: 20000 })
    .then(() => true)
    .catch(() => false)

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

// ---- 1. gate shows, physio signs in
check(await hasLabel(page, 'Prijava'), 'gate shows Prijava')
await shot(page, 'auth-1-gate')
await fillField(page, 0, 'tomislav@tendo.hr')
await fillField(page, 1, 'tendo-dev-1')
await tapLabel(page, 'Prijavi se')
await page.waitForTimeout(4000)
check(await hasLabel(page, 'Ana Kovačević'), 'physio lands on patients list')
await shot(page, 'auth-2-physio-home')

// ---- 2. sign out from the avatar menu
await tapLabel(page, 'Profil', 'right')
await page.waitForTimeout(800)
await tapLabel(page, 'Odjava')
await page.waitForTimeout(2500)
check(await hasLabel(page, 'Prijava'), 'sign-out returns to the gate')
await shot(page, 'auth-3-signed-out')

// ---- 3. wrong password rejected in Croatian
await fillField(page, 0, 'tomislav@tendo.hr')
await fillField(page, 1, 'wrong-password')
await tapLabel(page, 'Prijavi se')
await page.waitForTimeout(2500)
check(
  await hasLabel(page, 'Pogrešna e-adresa ili lozinka'),
  'wrong password shows Croatian error',
)

// ---- 4. invite redemption: Luka activates his program
await tapLabel(page, 'Imam pozivni kod')
await page.waitForTimeout(1000)
check(await hasLabel(page, 'Aktivirajte svoj program'), 'invite screen shows')
await shot(page, 'auth-4-invite')
await fillField(page, 0, 'lk7 3fq9') // sloppy on purpose — normalization
await fillField(page, 1, 'luka@example.com')
await fillField(page, 2, 'lozinka-luka-1')
await fillField(page, 3, 'lozinka-luka-1')
await tapLabel(page, 'Aktiviraj')
await page.waitForTimeout(5000)
check(await hasLabel(page, 'Luka Babić'), 'Luka lands on his patient home')
await shot(page, 'auth-5-luka-home')

// ---- 5. reused code is dead: sign out, try to redeem again fresh
if (process.env.SMOKE_DEBUG) {
  const dump = await page.locator('flt-semantics[flt-tappable]').evaluateAll((els) =>
    els.map((e) => {
      const r = e.getBoundingClientRect()
      return `${Math.round(r.x)},${Math.round(r.y)} ${Math.round(r.width)}x${Math.round(r.height)} :: ${(e.getAttribute('aria-label') || e.textContent || '').slice(0, 60)}`
    }),
  )
  console.log('TAPPABLES on patient home:\n  ' + dump.join('\n  '))
}
await tapLabel(page, 'Profil', 'right')
await page.waitForTimeout(1500)
await shot(page, 'auth-5b-menu')
await tapLabel(page, 'Odjava')
await page.waitForTimeout(2500)
await tapLabel(page, 'Imam pozivni kod')
await page.waitForTimeout(1000)
await fillField(page, 0, 'LK7-3FQ9')
await fillField(page, 1, 'mallory@example.com')
await fillField(page, 2, 'napadac123')
await fillField(page, 3, 'napadac123')
await tapLabel(page, 'Aktiviraj')
await page.waitForTimeout(4000)
check(
  await hasLabel(page, 'Pozivni kod nije važeći'),
  'redeemed code rejected for a second account',
)
await shot(page, 'auth-6-reuse-rejected')

// ---- 6. Luka signs back in with his new credentials
await tapLabel(page, 'Natrag na prijavu')
await page.waitForTimeout(1000)
await fillField(page, 0, 'luka@example.com')
await fillField(page, 1, 'lozinka-luka-1')
await tapLabel(page, 'Prijavi se')
await page.waitForTimeout(4000)
check(await hasLabel(page, 'Luka Babić'), 'Luka signs back in')
await shot(page, 'auth-7-luka-relogin')

const relevant = errors.filter((e) => !e.includes('favicon') && !e.includes('DevTools'))
console.log(relevant.length ? `console errors (${relevant.length}):` : 'no console errors')
relevant.slice(0, 5).forEach((e) => console.log('  ', e.slice(0, 200)))
await browser.close()
process.exit(failures ? 1 : 0)
