// Shared bootstrap for the admin toolkit. Two modes:
//  - Emulator (default): FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST
//    are set here if absent; no credentials needed. Project 'demo-tendo'.
//  - Production: run with GOOGLE_APPLICATION_CREDENTIALS pointing at the
//    service-account key (Dominik's machine only, never committed) and
//    TENDO_PROJECT=<real project id>.
import { initializeApp } from 'firebase-admin/app'
import { getAuth } from 'firebase-admin/auth'
import { getFirestore } from 'firebase-admin/firestore'

const production = !!process.env.TENDO_PROJECT

if (!production) {
  process.env.FIRESTORE_EMULATOR_HOST ??= 'localhost:8080'
  process.env.FIREBASE_AUTH_EMULATOR_HOST ??= 'localhost:9099'
  process.env.FIREBASE_STORAGE_EMULATOR_HOST ??= 'localhost:9199'
}

export const projectId = process.env.TENDO_PROJECT ?? 'demo-tendo'
export const app = initializeApp({ projectId })
export const auth = getAuth(app)
export const db = getFirestore(app)

export function fail(msg) {
  console.error(msg)
  process.exit(1)
}

if (production) {
  console.log(`⚠ PRODUCTION project: ${projectId}`)
} else {
  console.log(`emulator mode (${projectId})`)
}
