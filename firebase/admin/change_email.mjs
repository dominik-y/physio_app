// Fix a typo'd signup email (the accepted cost of not forcing email
// verification): point the Auth account at the right address, then send a
// reset link there. Usage: node admin/change_email.mjs old@x.com new@x.com
import { auth, fail } from './common.mjs'

const [oldEmail, newEmail] = process.argv.slice(2)
if (!oldEmail || !newEmail) fail('usage: change_email.mjs old new')

const user = await auth.getUserByEmail(oldEmail).catch(() => null)
if (!user) fail(`no account for ${oldEmail}`)
await auth.updateUser(user.uid, { email: newEmail })
console.log(`email changed: ${oldEmail} -> ${newEmail} (uid=${user.uid})`)
if (process.env.TENDO_PROJECT) {
  console.log(await auth.generatePasswordResetLink(newEmail))
}
