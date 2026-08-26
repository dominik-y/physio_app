import { test, expect } from '@playwright/test';
import {
  bootApp, expectVisibleLabel, tapLabel, assertNoConsoleErrors, settle,
} from './helpers.mjs';

const shot = (page, name) =>
  page.screenshot({ path: `screenshots/${test.info().project.name}/${name}.png` });

test('role gate renders and app boots without console errors', async ({ page }) => {
  const errors = await bootApp(page);
  await expectVisibleLabel(page, 'Uđi kao fizioterapeut');
  await expectVisibleLabel(page, 'Uđi kao pacijent');
  await settle(page);
  await shot(page, '01-role-gate');
  assertNoConsoleErrors(errors);
});

test('language toggle switches HR ↔ EN and back', async ({ page }) => {
  const errors = await bootApp(page);
  // Tap by the toggle's semantic label — short "HR"/"EN" text collides with
  // substrings of other labels ("ENter as physio") in case-insensitive match.
  await expectVisibleLabel(page, 'Uđi kao fizioterapeut');
  await tapLabel(page, 'Promijeni jezik');
  await settle(page, 800);
  await expectVisibleLabel(page, 'Enter as physio');
  await tapLabel(page, 'Change language');
  await settle(page, 800);
  await expectVisibleLabel(page, 'Uđi kao pacijent');
  assertNoConsoleErrors(errors);
});

test('physio: upload sheet shows video import tile', async ({ page }) => {
  const errors = await bootApp(page);
  await tapLabel(page, 'Uđi kao fizioterapeut');
  await settle(page);
  await tapLabel(page, 'Videoteka');
  await settle(page);
  await tapLabel(page, 'Snimi ili učitaj video');
  await settle(page, 900);
  await expectVisibleLabel(page, 'Odaberi ili snimi video');
  await expectVisibleLabel(page, 'Iz galerije');
  assertNoConsoleErrors(errors);
});

test('physio: patients list triage signals', async ({ page }) => {
  const errors = await bootApp(page);
  await tapLabel(page, 'Uđi kao fizioterapeut');
  await settle(page);
  await expectVisibleLabel(page, 'Josip Novak');
  await expectVisibleLabel(page, '9 dana bez aktivnosti');
  await expectVisibleLabel(page, 'pozvan');
  await shot(page, '02-patients-list');
  assertNoConsoleErrors(errors);
});

test('physio: patient detail shows adherence and protocols', async ({ page }) => {
  const errors = await bootApp(page);
  await tapLabel(page, 'Uđi kao fizioterapeut');
  await settle(page);
  await tapLabel(page, 'Ana Kovačević');
  await settle(page);
  await expectVisibleLabel(page, 'Oporavak meniskusa');
  await expectVisibleLabel(page, 'Stabilnost trupa');
  await expectVisibleLabel(page, 'Zadaj vježbe');
  await shot(page, '03-patient-detail');
  assertNoConsoleErrors(errors);
});

test('physio: assign fork and dosage editor open', async ({ page }) => {
  const errors = await bootApp(page);
  await tapLabel(page, 'Uđi kao fizioterapeut');
  await settle(page);
  await tapLabel(page, 'Ana Kovačević');
  await settle(page);
  await tapLabel(page, 'Zadaj vježbe');
  await settle(page);
  await expectVisibleLabel(page, 'Iz predloška');
  await expectVisibleLabel(page, 'Pošalji jedan video');
  await shot(page, '04-assign-fork');
  await tapLabel(page, 'Rotatorna manšeta');
  await settle(page);
  await expectVisibleLabel(page, 'Pendularne kretnje');
  await shot(page, '05-dosage-editor');
  assertNoConsoleErrors(errors);
});

test('physio: library and templates render grouped content', async ({ page }) => {
  const errors = await bootApp(page);
  await tapLabel(page, 'Uđi kao fizioterapeut');
  await settle(page);
  await tapLabel(page, 'Videoteka');
  await settle(page);
  await expectVisibleLabel(page, 'Ekstenzija koljena u sjedu');
  await shot(page, '06-library');
  await tapLabel(page, 'Predlošci');
  await settle(page);
  await expectVisibleLabel(page, 'Oporavak meniskusa');
  await shot(page, '07-templates');
  assertNoConsoleErrors(errors);
});

test('patient: home hero, session player, complete loop', async ({ page }) => {
  const errors = await bootApp(page);
  await tapLabel(page, 'Uđi kao pacijent');
  await settle(page);
  await expectVisibleLabel(page, 'još ');
  await expectVisibleLabel(page, 'Dodatno zadano');
  await shot(page, '08-patient-home');

  await tapLabel(page, 'Nastavi trening');
  await settle(page, 1200);
  await expectVisibleLabel(page, 'Vježba 2 od');
  await shot(page, '09-session-player');

  // Skip one, then Done through the rest of the session.
  await tapLabel(page, 'Preskoči ovu');
  await settle(page, 400);
  for (let i = 0; i < 12; i++) {
    const done = page.locator('flt-semantics[flt-tappable]:has-text("Gotovo · sljedeća vježba")').last();
    if (!(await done.count())) break;
    try {
      await done.evaluate((e) => e.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true })));
    } catch { break; }
    await settle(page, 350);
  }
  await expectVisibleLabel(page, 'Trening odrađen');
  await shot(page, '10-session-complete');

  await tapLabel(page, 'Natrag na početnu');
  await settle(page);
  await expectVisibleLabel(page, 'Gotovo za danas');
  await shot(page, '11-home-complete');
  assertNoConsoleErrors(errors);
});
