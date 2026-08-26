// "Start over" for a patient: delete their Auth account and null the uid on
// the patient doc so the physio can regenerate an invite. Clinical history
// stays. Usage: node admin/unlink_patient.mjs <patientId>
import { auth, db, fail } from './common.mjs'

const [patientId] = process.argv.slice(2)
if (!patientId) fail('usage: unlink_patient.mjs patientId')

const snap = await db.collection('patients').doc(patientId).get()
if (!snap.exists) fail(`no patient doc ${patientId}`)
const uid = snap.data().uid
if (uid) {
  await auth.deleteUser(uid).catch((e) => console.warn(`auth delete: ${e.message}`))
}
await db.collection('patients').doc(patientId).update({ uid: null })
console.log(`unlinked ${patientId}${uid ? ` (deleted auth user ${uid})` : ''} — regenerate an invite in the app`)
