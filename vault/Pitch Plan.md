# Pitch & Rollout Plan — Poliklinika Tendo

Outcome of the grilling session 2026-08-25. Confirmed by Dominik; this is the agreed plan. See [[TODO]] for the live task breakdown.

## Positioning

A **home-training reference and workout tracker**: patients follow their physio's assigned exercise videos at home (when they can't come in) and the physio sees adherence. Not remote treatment, no medical claims. Privacy/GDPR stays out of the pitch entirely (Dominik's call) — but Firebase gets pinned to an EU region anyway as silent engineering hygiene.

## Business model

- Dominik retains ownership and resale rights — he may resell adapted versions to other clinics. He is the maintainer and pays all infrastructure (Firebase, Apple Developer €99/yr).
- **Price: €1,800 one-time setup + €170/month.** Director-facing math: less than one patient visit per month.
- Promise in the room: **"we start in 2 weeks"** from a yes — whole app live via TestFlight, physios uploading videos, real patients redeeming invites. Both platforms promised casually; iOS ships first, Android follows (~3 months, unstressed).

## The pitch meeting (≤1 week away)

- Informal in-person walkthrough with the **director**; no script, no deck, no time limit.
- Demo device: **Dominik's iPhone, native build** (Xcode 26.4 verified ready); MacBook web build in Chrome as backup. Mobile-first.
- Demo runs on **demo mode** (the seeded fixtures tell a better story than an empty live backend).
- Leave-behind: **one A4 in Croatian** — what it is, pricing, contact. No privacy section.
- Suggested arc (informal, not binding): the "Josip 9 days silent" triage moment → assign a protocol in 30 s → switch roles → patient guided session → live video import moment.

## Pitch-week build list

1. **Croatian localization** — full l10n, Croatian default, 🇭🇷/🇬🇧 switcher top-right on role gate + in role menu, persisted. Claude drafts all strings; Dominik reviews clinical terminology.
2. **15-second video import (demo-grade)** — camera/gallery on iPhone, drag-and-drop on web; held in memory, deliberately unscalable. The live "film it, it's in the library" moment.
3. **Native iOS build** on Dominik's iPhone (free provisioning; re-sign the day before the pitch — 7-day cert).
4. **Real Tendo footage** seeded in the library. Source: their own Instagram (@poliklinika_tendo, 1,543 followers). Confirmed pick: **reel #8, "PRESEASON MODE ON"** (footwork/ball drill in the clinic gym). Facebook page also has a facility video ("Full house u Poliklinici Tendo") as a fallback. Beware the unrelated surgical "Poliklinika Tendo" in Banjole, Istria — verify Zagreb origin before grabbing anything.
5. **One-pager draft** (Croatian) for Dominik's review.

## Production build (2 weeks, after signature)

- **Single Firebase project** for Tendo, EU region (europe-west3), Blaze on Dominik's card. Architecture keeps multi-tenant / per-clinic reuse open; "ideally multi-tenant later, single now."
- **Auth**: physio accounts hand-provisioned by Dominik (email + password, no self-registration). Patients: **invite code + email/password**, account self-created at redemption. Patient demographic is sporty, not elderly — no SMS auth needed.
- **Uploads**: physios only. Caps: 90 s / 100 MB per video (configurable later — "raise caps in a config, never in a renegotiation").
- **Distribution**: TestFlight at ~day 10 → App Store listing after → Google Play inside the first term. Apple Developer account opened at signature, not before.
