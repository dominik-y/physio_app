// Offboard a physio: disable the account and strip the role claim. Their
// uploads/templates stay (clinic property). Live sessions lose access on
// token expiry (≤1 h). Usage: node admin/disable_physio.mjs email@tendo.hr
import { auth, fail } from './common.mjs'

const [email] = process.argv.slice(2)
if (!email) fail('usage: disable_physio.mjs email')

const user = await auth.getUserByEmail(email).catch(() => null)
if (!user) fail(`no account for ${email}`)
await auth.updateUser(user.uid, { disabled: true })
await auth.setCustomUserClaims(user.uid, {})
await auth.revokeRefreshTokens(user.uid)
console.log(`physio disabled: ${email} (claim stripped, refresh tokens revoked)`)
