# Feature Goals

What each feature is *for* — the yardstick for any redesign or refactor. If a change makes a screen prettier but weaker against its goal, it's a regression.

## Patient side

### Home (hero)
**Goal: zero decisions before starting.** One dark card, one number, one button. A patient in pain shouldn't parse a dashboard. Success = time-to-session-start measured in seconds.
- Hero merges all due protocols invisibly (§4.6) — protocol boundaries are the physio's concern, not the patient's.
- Week strip = gentle self-accountability, not gamification. No streak-shaming.
- New badge tells them their physio did something — the only "notification" the MVP has.

### Session player
**Goal: completion as a side effect of doing the work.** One exercise at a time; Done advances; no checklist ceremony.
- **Skip is an honest exit, not a failure state.** It must stay one tap, never guilt-styled — a skipped exercise recorded is clinically worth more than an abandoned session.
- Dark because it's mostly video; controls reachable one-handed at the bottom.

## Physio side

### Patients list
**Goal: triage in five seconds.** The one question it answers: *who needs me?* Silence sorts first and renders red; everything else is secondary.

### Patient detail
**Goal: the clinical picture on one screen.** Adherence with skips counted against, private notes as the clinical memory, invite management until redemption. `—` (not 0%) for fresh assignments — never show a patient as failing work they haven't been given time to do.

### Assign flow
**Goal: prescription in under a minute.** Template → two taps → adjust → done. Overridden pills outlined so bespoke vs. standard reads at a glance. The §4.6 total-exercise warning is a guard rail, not a gate — his judgment wins, but never by accident.

### Library
**Goal: film once, assign forever.** Upload lives inside the assign flow too, because "let me film this for you right now" with the patient standing there is the app's founding moment.

## Design direction (Warm Recovery, spec §7)

Neither hospital nor gym. Deep pine on warm off-white; healing, not performance. Much of the roster is post-surgical or sixty — legibility beats density, calm beats punch. Base type one step larger than default. Light mode only; dark only where it earns its keep (video).

## Post-MVP goals, in order

1. **Push notifications** — the daily-habit engine the MVP intentionally lacks.
2. **Pain scores on completions** — turns adherence data into clinical signal; schema is ready.
3. **Multi-clinic** — data model is ready; Storage rule tightening (custom claims) is the actual work.
4. In-app messaging: **explicitly never**, unless the WhatsApp status quo demonstrably breaks.
