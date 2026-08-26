// Create a physio account: Auth user + role:'physio' custom claim +
// physios/{uid} profile doc. Prints a password-reset link so no password
// ever travels by chat (emulator mode prints the temp password instead).
// Usage: node admin/provision_physio.mjs "Ime Prezime" email@tendo.hr
import { auth, db, fail } from './common.mjs'

const [name, email] = process.argv.slice(2)
if (!name || !email) fail('usage: provision_physio.mjs "Name" email')

const tempPassword = `tendo-${Math.random().toString(36).slice(2, 10)}`

let user
try {
  user = await auth.createUser({ email, password: tempPassword, displayName: name })
} catch (e) {
  fail(`createUser failed: ${e.message}`)
}
await auth.setCustomUserClaims(user.uid, { role: 'physio' })
await db.collection('physios').doc(user.uid).set({
  name,
  email,
  createdAt: new Date(),
})

console.log(`physio provisioned: ${name} <${email}> uid=${user.uid}`)
if (process.env.TENDO_PROJECT) {
  const link = await auth.generatePasswordResetLink(email)
  console.log(`send them this reset link (sets their real password):\n${link}`)
} else {
  console.log(`emulator temp password: ${tempPassword}`)
}
