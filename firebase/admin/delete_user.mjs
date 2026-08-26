// Free an email after an in-app patient delete (the client cannot delete
// other Auth users). Usage: node admin/delete_user.mjs email@example.com
import { auth, fail } from './common.mjs'

const [email] = process.argv.slice(2)
if (!email) fail('usage: delete_user.mjs email')

const user = await auth.getUserByEmail(email).catch(() => null)
if (!user) fail(`no account for ${email}`)
await auth.deleteUser(user.uid)
console.log(`deleted auth account ${email} (uid=${user.uid})`)
