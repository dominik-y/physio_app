// One-off smoke drive of the FIREBASE flavor (web, :7358) against the local
// emulator suite. Not part of the regular suite — run manually:
//   node scripts/firebase-smoke.mjs
// Requires: emulators up + seeded, web_firebase served on :7358.
import { chromium } from '@playwright/test'

const outDir = `${process.env.CLAUDE_JOB_DIR ?? '/tmp'}/tmp`
const shot = (p, name) => p.screenshot({ path: `${outDir}/${name}.png` })

async function tapLabel(page, label) {
  const tappable = page
    .locator(
      `flt-semantics[flt-tappable]:has-text("${label}"), ` +
        `flt-semantics[flt-tappable][aria-label*="${label}" i]`,
    )
    .last()
  await tappable.waitFor({ state: 'attached', timeout: 15000 })
  await tappable.evaluate((e) => {
    e.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }))
  })
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

await tapLabel(page, 'fizioterapeut')
await page.waitForTimeout(4000)
await shot(page, 'fb-web-patients')

const html = await page.content()
for (const name of ['Ana Kovačević', 'Josip Novak', 'Luka Babić']) {
  console.log(`${html.includes(name) ? 'OK ' : 'MISS'} ${name}`)
}

await tapLabel(page, 'Ana Kovačević')
await page.waitForTimeout(3000)
await shot(page, 'fb-web-ana-detail')
const detail = await page.content()
console.log(
  `${detail.includes('Oprez s desnim koljenom') ? 'OK ' : 'MISS'} clinical notes (patientNotes merge)`,
)
console.log(
  `${detail.includes('Oporavak meniskusa') ? 'OK ' : 'MISS'} assignments stream`,
)

const relevant = errors.filter((e) => !e.includes('favicon') && !e.includes('DevTools'))
console.log(relevant.length ? `console errors (${relevant.length}):` : 'no console errors')
relevant.slice(0, 5).forEach((e) => console.log('  ', e.slice(0, 200)))
await browser.close()
