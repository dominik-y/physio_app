import { expect } from '@playwright/test';

/**
 * Boot the Flutter web app with semantics enabled. On Flutter 3.24 web the
 * semantics tree renders labels as <span> text inside flt-semantics nodes
 * (tappables carry the flt-tappable attribute) — NOT aria-labels.
 * Arms a console-error collector; call `assertNoConsoleErrors` at the end.
 */
export async function bootApp(page) {
  const errors = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') errors.push(msg.text());
  });
  page.on('pageerror', (err) => errors.push(String(err)));

  await page.goto('/', { waitUntil: 'networkidle' });
  const placeholder = page.locator('flt-semantics-placeholder');
  await placeholder.waitFor({ state: 'attached', timeout: 20_000 });
  await placeholder.evaluate((el) => el.click());
  await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout: 20_000 });
  await page.waitForTimeout(600);
  return errors;
}

/**
 * Innermost semantics node carrying the label. Flutter web exposes labels
 * either as <span> text inside flt-semantics or as an aria-label attribute
 * (varies by role) — match both.
 */
export function node(page, label) {
  return page
    .locator(`flt-semantics:has-text("${label}"), flt-semantics[aria-label*="${label}" i]`)
    .last();
}

export async function expectVisibleLabel(page, label, timeout = 15_000) {
  await expect(node(page, label)).toBeAttached({ timeout });
}

/** Click the innermost TAPPABLE semantics node carrying the label. */
export async function tapLabel(page, label) {
  const tappable = page
    .locator(
      `flt-semantics[flt-tappable]:has-text("${label}"), ` +
      `flt-semantics[flt-tappable][aria-label*="${label}" i]`,
    )
    .last();
  await tappable.waitFor({ state: 'attached', timeout: 15_000 });
  await tappable.evaluate((e) => {
    e.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
  });
}

export function assertNoConsoleErrors(errors) {
  const relevant = errors.filter(
    (e) => !e.includes('favicon') && !e.includes('DevTools'),
  );
  expect(relevant, `console errors:\n${relevant.join('\n')}`).toHaveLength(0);
}

export async function settle(page, ms = 1100) {
  await page.waitForTimeout(ms);
}
