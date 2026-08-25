# Documentation

How the app is put together and how to work on it. Assumes the repo root `~/work/physio_app`.

## Running it

```bash
cd app
flutter run -d macos            # desktop
flutter run -d chrome           # browser, dev
flutter build web --release     # then serve build/web statically for demos/tests
```

App boots to a **role gate** (demo stand-in for auth): enter as physio (Dr. Tomislav Perić) or patient (Ana Kovačević). Data is seeded in memory and resets on restart.

## Testing

```bash
cd app
flutter analyze                 # must be 0 issues
flutter test                    # 123 tests: unit + bloc + widget + overflow sweep
```

The overflow sweep (`test/widget/overflow_sweep_test.dart`) pumps **every screen at 320×568, 375×667, 430×932** plus state variants (hero start/resume/done/empty, session complete/empty, long-name stress). Any `RenderFlex` overflow fails. Keep new screens registered there.

All time-dependent tests pin `DateTime(2026, 8, 25, 9, 30)` (a Tuesday) and inject `NowFn` — never call `DateTime.now()` inside domain logic or blocs.

## Architecture (feature-first, spec §12)

```
app/lib/
  app/            router (go_router), RoleCubit, providers, RoleMenuButton
  core/           Result, Dates (DST-safe), Watchable, combineLatest2/3/4,
                  adherence.dart (adherence %, week strip, silence),
                  session_engine.dart (today's merge, resume)
  design_system/  colors, typography, tokens, components, week_strip,
                  hero_card, demo_video_player
  domain/         models.dart (entities), repositories.dart (interfaces)
  data/           demo_data.dart (seed fixture), demo_repositories.dart
  features/       patients / library / templates / assignments / home /
                  session / role_gate — each: bloc + pages, no cross-feature imports
```

**Dependency rule:** features depend on `core`, `domain`, `design_system` (and `app/role_cubit` for the avatar menu) — never on each other. Blocs take repository *interfaces*; pages `context.read<XRepository>()`.

**Reactive model:** `Watchable<T>` (in-memory value, replays current on listen) → repository streams → `combineLatestN` → bloc states. Every mutation goes through `Watchable.update`, so all open screens react — that's the whole live-sync story.

## Domain rules that must not regress

| Rule | Where enforced |
|---|---|
| Adherence = done ÷ scheduled, today excluded, skips count against | `core/adherence.dart` + tests |
| New assignment → `—`, never 0% | `adherencePercent` returns null |
| Guided session merges **protocols only**; singles live in "Also assigned" | `buildTodaySession` filters type |
| Resume at first unrecorded exercise; daily reset | `TodaySession.firstUnrecordedIndex` |
| One outcome per exercise per day (upsert) | `Completion.idFor` + repo `record` |
| No duplicate video within an assignment | `Assignment` assert + picker guard |
| Snapshot-on-assign (template edits never touch live plans) | `AssignFlowBloc` deep-copy + test |
| Session start clears New on contributing protocols | `SessionBloc` init `markSeen` |

## Firebase phase — where things plug in

- `Demo*Repository` classes in `data/` are the only demo-specific code; Firestore implementations implement the same interfaces in `domain/repositories.dart`.
- `DemoVideoPlayer` swaps for a real player behind the same constructor contract (title, bodyPart, durationSec, autoplay, onCompleted).
- Firestore document shapes are already specified in spec §9; models mirror them field-for-field.
- Build order and rules-first rationale: spec §13, §10.
