// Generate a password-reset link for any account (physio or patient).
// Usage: node admin/reset_password.mjs email@example.com
import { auth, fail } from './common.mjs'

const [email] = process.argv.slice(2)
if (!email) fail('usage: reset_password.mjs email')

try {
  const link = await auth.generatePasswordResetLink(email)
  console.log(link)
} catch (e) {
  fail(`no reset link: ${e.message}`)
}
