import { chromium } from '@playwright/test';

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
await page.goto('http://localhost:7357', { waitUntil: 'networkidle' });
const ph = page.locator('flt-semantics-placeholder');
await ph.waitFor({ state: 'attached' });
await ph.evaluate((el) => el.click());
await page.waitForTimeout(1500);

async function tap(label) {
  const t = page.locator(`flt-semantics[flt-tappable]:has-text("${label}")`).last();
  await t.evaluate((e) => e.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true })));
  await page.waitForTimeout(1200);
}
async function dump(tag) {
  const leaves = await page.evaluate(() =>
    [...document.querySelectorAll('flt-semantics')]
      .filter((e) => !e.querySelector('flt-semantics'))
      .map((e) => e.textContent.trim().replace(/\s+/g, ' ').slice(0, 70))
      .filter(Boolean));
  console.log(`--- ${tag} ---`);
  console.log(JSON.stringify(leaves, null, 0));
}

const mode = process.argv[2] ?? 'patient';
if (mode === 'patient') {
  await tap('Enter as patient');
  await dump('patient home');
} else {
  await tap('Enter as physio');
  await page.waitForTimeout(800);
  await tap('Ana Kovačević');
  await dump('detail');
  await tap('Assign something');
  await page.waitForTimeout(1000);
  await dump('after Assign tap');
  console.log('url:', page.url());
}
await browser.close();
