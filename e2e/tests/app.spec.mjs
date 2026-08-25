import { test, expect } from '@playwright/test';
import {
  bootApp, expectVisibleLabel, tapLabel, assertNoConsoleErrors, settle,
} from './helpers.mjs';

const shot = (page, name) =>
  page.screenshot({ path: `screenshots/${test.info().project.name}/${name}.png` });

test('role gate renders and app boots without console errors', async ({ page }) => {
  const errors = await bootApp(page);
  await expectVisibleLabel(page, 'Enter as physio');
  await expectVisibleLabel(page, 'Enter as patient');
  await settle(page);
  await shot(page, '01-role-gate');
  assertNoConsoleErrors(errors);
});

test('physio: patients list triage signals', async ({ page }) => {
  const errors = await bootApp(page);
  await tapLabel(page, 'Enter as physio');
  await settle(page);
  await expectVisibleLabel(page, 'Josip Novak');
  await expectVisibleLabel(page, '9 days silent');
  await expectVisibleLabel(page, 'invited');
  await shot(page, '02-patients-list');
  assertNoConsoleErrors(errors);
});

test('physio: patient detail shows adherence and protocols', async ({ page }) => {
  const errors = await bootApp(page);
  await tapLabel(page, 'Enter as physio');
  await settle(page);
  await tapLabel(page, 'Ana Kovačević');
  await settle(page);
  await expectVisibleLabel(page, 'Meniscus Recovery');
  await expectVisibleLabel(page, 'Core Stability');
  await expectVisibleLabel(page, 'Assign something');
  await shot(page, '03-patient-detail');
  assertNoConsoleErrors(errors);
});

test('physio: assign fork and dosage editor open', async ({ page }) => {
  const errors = await bootApp(page);
  await tapLabel(page, 'Enter as physio');
  await settle(page);
  await tapLabel(page, 'Ana Kovačević');
  await settle(page);
  await tapLabel(page, 'Assign something');
  await settle(page);
  await expectVisibleLabel(page, 'From a template');
  await expectVisibleLabel(page, 'Send a single video');
  await shot(page, '04-assign-fork');
  await tapLabel(page, 'Rotator Cuff');
  await settle(page);
  await expectVisibleLabel(page, 'Pendulum swings');
  await shot(page, '05-dosage-editor');
  assertNoConsoleErrors(errors);
});

test('physio: library and templates render grouped content', async ({ page }) => {
  const errors = await bootApp(page);
  await tapLabel(page, 'Enter as physio');
  await settle(page);
  await tapLabel(page, 'Library');
  await settle(page);
  await expectVisibleLabel(page, 'Seated quad extension');
  await shot(page, '06-library');
  await tapLabel(page, 'Templates');
  await settle(page);
  await expectVisibleLabel(page, 'Meniscus Recovery');
  await shot(page, '07-templates');
  assertNoConsoleErrors(errors);
});

test('patient: home hero, session player, complete loop', async ({ page }) => {
  const errors = await bootApp(page);
  await tapLabel(page, 'Enter as patient');
  await settle(page);
  await expectVisibleLabel(page, 'remaining');
  await expectVisibleLabel(page, 'Also assigned');
  await shot(page, '08-patient-home');

  await tapLabel(page, 'Resume session');
  await settle(page, 1200);
  await expectVisibleLabel(page, 'Exercise 2 of');
  await shot(page, '09-session-player');

  // Skip one, then Done through the rest of the session.
  await tapLabel(page, 'Skip this one');
  await settle(page, 400);
  for (let i = 0; i < 12; i++) {
    const done = page.locator('flt-semantics[flt-tappable]:has-text("Done · next exercise")').last();
    if (!(await done.count())) break;
    try {
      await done.evaluate((e) => e.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true })));
    } catch { break; }
    await settle(page, 350);
  }
  await expectVisibleLabel(page, 'Session complete');
  await shot(page, '10-session-complete');

  await tapLabel(page, 'Back to home');
  await settle(page);
  await expectVisibleLabel(page, 'Done for today');
  await shot(page, '11-home-complete');
  assertNoConsoleErrors(errors);
});
