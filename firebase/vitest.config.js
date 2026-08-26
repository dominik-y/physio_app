import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    include: ['tests/**/*.test.js'],
    testTimeout: 20000,
    hookTimeout: 30000,
    // Emulator state is shared; files run sequentially to keep seeds
    // isolated, each in a fresh fork so Firebase app state never leaks
    // across files.
    fileParallelism: false,
    pool: 'forks',
    isolate: true,
  },
})
