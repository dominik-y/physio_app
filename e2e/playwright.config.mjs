import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 60_000,
  retries: 0,
  workers: 1, // one shared app origin; serial keeps flows deterministic
  reporter: [['list']],
  use: {
    baseURL: 'http://localhost:7357',
    browserName: 'chromium',
    deviceScaleFactor: 2,
    viewport: { width: 390, height: 844 },
  },
  projects: [
    { name: 'mobile', use: { viewport: { width: 390, height: 844 } } },
    { name: 'small', use: { viewport: { width: 320, height: 568 } } },
  ],
});
