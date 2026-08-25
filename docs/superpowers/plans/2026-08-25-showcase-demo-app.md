# Physio App Showcase (Demo Mode) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A fully navigable, tested, overflow-free Flutter app implementing the entire physio-and-patient experience from the spec (§1–§7, §15) against seeded in-memory repositories — runnable today on macOS/Chrome with zero backend.

**Architecture:** Feature-first (spec §12). BloCs consume repository *interfaces*; this phase ships `Demo*Repository` in-memory implementations seeded from one `DemoData` fixture. All domain math (session merge, resume, adherence, week strips) is pure functions in `core/`, unit-tested exhaustively. Every screen gets an overflow sweep widget test at three device sizes.

**Tech Stack:** Flutter 3.24.3 / Dart 3.5.3 · flutter_bloc ^8.1.6 · go_router ^14.2.7 · equatable ^2.0.5 · intl ^0.19.0 · bloc_test + flutter_lints (dev). **No other packages** — no get_it (use RepositoryProvider), no rxdart (use `Stream.multi`), no video_player (DemoVideoPlayer per spec §15.1).

**Spec:** `docs/superpowers/specs/2026-08-25-physio-app-mvp-design.md` — sections referenced as §N throughout.
**HTML mockups (visual reference, match these):** `.superpowers/brainstorm/51675-1787643500/content/` — `design-system.html`, `patient-home-hero.html`, `physio-flow.html`, `patient-navigation-v2.html`, `waiting-2.html`.

**Conventions (all tasks):**
- Project root: `/Users/dominikmaric/work/physio_app/app` (Flutter project lives in `app/`, docs stay at repo root).
- Package name: `physio_app`. Import style: `package:physio_app/...` always, never relative across features.
- Every entity is `Equatable` with `const` constructors and `copyWith`.
- Dates as `DateTime` in models; day keys as `'YYYY-MM-DD'` strings via `Dates.ymd`. ISO weekday 1=Mon..7=Sun (`DateTime.weekday` already matches).
- **No `DateTime.now()` inside domain functions or BloC logic** — `now` is always a parameter or injected `NowFn` (`typedef NowFn = DateTime Function();`). Widgets/blocs default it to `DateTime.now`.
- Tests: `flutter test` from `app/`. NO git commits at any step (owner commits manually).

---

## Critique Amendments (binding — override anything contradictory below)

A 4-lens multi-agent critique (2026-08-25) produced 25 findings. These resolutions are contractual:

1. **Calendar stepping:** `Dates.scheduledDatesBetween` advances via `DateTime(d.year, d.month, d.day + 1)` — never `add(Duration(days: 1))` (DST). DST-crossing tests exist in `dates_test.dart`.
2. **Stream combination:** `lib/core/streams.dart` provides `combineLatest2/3/4` (emit once all sources have values; cancel propagates). ALL blocs merging repository streams MUST use these — never hand-rolled subscription merging.
3. **Singles are NOT part of the guided session.** `buildTodaySession` filters to `type == protocol`. Singles surface only in "Also assigned" (tap → full-screen `DemoVideoPlayer` + `markSeen`). Hero counts protocols only.
4. **Merge order tiebreaker:** assignments sort by `(createdAt, id)`, then items by `order`.
5. **New-badge clearing for protocols:** `SessionBloc` on init calls `markSeen` for every distinct assignment contributing to today's session. Singles clear via `AssignmentOpened` on home. bloc_test asserts both.
6. **Duplicate videos:** an `Assignment` asserts distinct `videoId`s across items (completion-ID collision guard). The video picker must prevent selecting a video already in the working set.
7. **Router:** `GoRouterRefreshStream` is a locally-authored `ChangeNotifier` in `app/router.dart` (go_router does not export one). The assign flow is ONE route (`/physio/patients/:id/assign`) hosting `BlocProvider<AssignFlowBloc>` with internal step navigation (fork → picker → dosage as widgets switched by bloc state, back handled internally) — no bloc-scoping across go_router sub-routes.
8. **Single-video assign path:** picker in single-select mode shows a bottom confirm bar ("Send to <name>") and submits directly — the dosage editor is never visited (spec §4.5 "no dosage ceremony").
9. **`existingDailyTotal`** = flat sum of `items.length` across the patient's OTHER active protocol assignments (daysOfWeek overlap deliberately ignored).
10. **Dosage editor structure:** `Column[ header fields, Expanded(ReorderableListView(children keyed by ValueKey(videoId))), footer with summary + confirm ]`. Exercise card = two rows: (drag handle · title Expanded/ellipsis · remove icon) / (three DosagePills in Expanded flex).
11. **Row ellipsis rule:** every row-style widget wraps its title column in `Expanded` with `maxLines: 1, overflow: TextOverflow.ellipsis`. Hero protocol-names line: joined with ' · ', maxLines 1, ellipsis.
12. **Upload sheet:** `showModalBottomSheet(isScrollControlled: true)`, body in `SingleChildScrollView` padded by `MediaQuery.viewInsetsOf(context).bottom`. Failure state has visible error text + Retry. Exact export: `Future<void> showUploadSheet(BuildContext context, {String? preselectPrivatePatientId})` in `features/library/upload_sheet.dart`.
13. **DemoVideoPlayer** disposes its `AnimationController` in `dispose()`.
14. **Test harness** `test/widget/harness.dart` is foundation (available before feature agents run). Session widget test asserts repo state + core-function recomputation — it never imports feature `home/` files.
15. **Fixture IDs:** `DemoData` exposes `adherentPatientId, skippingPatientId, twoProtocolPatientId, silentPatientId, newTodayPatientId, unredeemedPatientId`.
16. **Overflow sweep additions:** hero in fresh/complete/New states, SessionPage in complete and empty states, upload sheet progress + failure states (all × 3 sizes).

## File Map

```
app/
  pubspec.yaml
  analysis_options.yaml
  lib/
    main.dart
    app/app.dart                    // MaterialApp.router, providers
    app/router.dart                 // go_router config + role redirect
    app/role_cubit.dart             // demo role selection (spec §15.1)
    core/result.dart
    core/dates.dart
    core/watchable.dart             // in-memory reactive store
    core/adherence.dart             // adherence %, week strip, silence
    core/session_engine.dart        // today's merge + resume (§4.6, §5.3)
    design_system/tokens.dart
    design_system/components.dart   // buttons, cards, pills, chips, avatar
    design_system/week_strip.dart
    design_system/hero_card.dart
    design_system/demo_video_player.dart
    domain/models.dart              // all entities (small app: one file)
    domain/repositories.dart        // all interfaces
    data/demo_data.dart             // seed fixture
    data/demo_repositories.dart     // in-memory impls
    features/role_gate/role_gate_page.dart
    features/patients/patients_bloc.dart
    features/patients/patients_page.dart
    features/patients/patient_detail_bloc.dart
    features/patients/patient_detail_page.dart
    features/library/library_bloc.dart
    features/library/library_page.dart
    features/library/upload_cubit.dart
    features/library/upload_sheet.dart
    features/templates/templates_bloc.dart
    features/templates/templates_page.dart
    features/assignments/assign_flow_bloc.dart
    features/assignments/assign_fork_page.dart
    features/assignments/video_picker_page.dart
    features/assignments/dosage_editor_page.dart
    features/home/patient_home_bloc.dart
    features/home/patient_home_page.dart
    features/session/session_bloc.dart
    features/session/session_page.dart
  test/
    core/dates_test.dart
    core/watchable_test.dart
    core/adherence_test.dart
    core/session_engine_test.dart
    data/demo_repositories_test.dart
    features/patients_bloc_test.dart
    features/patient_detail_bloc_test.dart
    features/assign_flow_bloc_test.dart
    features/patient_home_bloc_test.dart
    features/session_bloc_test.dart
    features/upload_cubit_test.dart
    widget/harness.dart             // pumpScreen helper + size sweep
    widget/overflow_sweep_test.dart // every screen × 3 sizes
    widget/session_flow_test.dart   // done/skip/resume through real widgets
```

Feature-boundary rule for parallel agents: an agent implementing a feature may create/modify ONLY files under its `features/<name>/` directory plus its own test files. `core/`, `domain/`, `data/`, `design_system/`, `app/` are owned by the foundation task and are read-only for feature agents.

---

## Task 1: Scaffold

**Files:** Create `app/` via `flutter create`, then `pubspec.yaml`, `analysis_options.yaml`.

- [ ] `cd /Users/dominikmaric/work/physio_app && git init` (no commit)
- [ ] `flutter create app --org hr.physio --project-name physio_app --platforms macos,web`
- [ ] Replace `pubspec.yaml` dependencies:

```yaml
environment:
  sdk: ^3.5.3
dependencies:
  flutter: {sdk: flutter}
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  go_router: ^14.2.7
  intl: ^0.19.0
dev_dependencies:
  flutter_test: {sdk: flutter}
  bloc_test: ^9.1.7
  flutter_lints: ^4.0.0
```

- [ ] `flutter pub get` — expect success. Delete the counter test `test/widget_test.dart`.
- [ ] Add `.gitignore` at repo root containing `.superpowers/` (plus standard Flutter ignores live in `app/.gitignore` from create).

## Task 2: Core primitives

**Files:** `lib/core/result.dart`, `lib/core/dates.dart`, `lib/core/watchable.dart` + tests.

- [ ] `result.dart`:

```dart
sealed class Result<T> {
  const Result();
  R when<R>({required R Function(T) ok, required R Function(String) err}) =>
      switch (this) { Ok(:final value) => ok(value), Err(:final message) => err(message) };
}
class Ok<T> extends Result<T> { final T value; const Ok(this.value); }
class Err<T> extends Result<T> { final String message; const Err(this.message); }
```

- [ ] `dates.dart` — write failing tests first (`test/core/dates_test.dart`): `ymd(DateTime(2026,8,25)) == '2026-08-25'`; `dateOnly` strips time; `scheduledDatesBetween(days: {1,3,5}, from: 2026-08-17, toExclusive: 2026-08-24)` returns Mon 17, Wed 19, Fri 21. Then implement:

```dart
class Dates {
  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static List<DateTime> scheduledDatesBetween(
      {required Set<int> daysOfWeek, required DateTime from, required DateTime toExclusive}) {
    final out = <DateTime>[];
    for (var d = dateOnly(from); d.isBefore(dateOnly(toExclusive)); d = d.add(const Duration(days: 1))) {
      if (daysOfWeek.contains(d.weekday)) out.add(d);
    }
    return out;
  }
}
```

(Note: `add(Duration(days:1))` across DST is safe here because macOS/Chrome demo runs in local time and `dateOnly` renormalizes each step — keep the renormalize: use `d = dateOnly(DateTime(d.year, d.month, d.day + 1))`.)

- [ ] `watchable.dart` — reactive in-memory value; test first: new listener immediately receives current value; `update` notifies all listeners; listeners after update get latest.

```dart
class Watchable<T> {
  T _value;
  final _controllers = <MultiStreamController<T>>[];
  Watchable(this._value);
  T get value => _value;
  Stream<T> watch() => Stream.multi((c) {
        c.add(_value);
        _controllers.add(c);
        c.onCancel = () => _controllers.remove(c);
      });
  void update(T Function(T) fn) {
    _value = fn(_value);
    for (final c in List.of(_controllers)) c.add(_value);
  }
}
```

- [ ] `flutter test test/core/` — PASS.

## Task 3: Domain models + repository interfaces

**Files:** `lib/domain/models.dart`, `lib/domain/repositories.dart`.

- [ ] `models.dart` — all Equatable, const, copyWith. Exact shapes (mirror spec §9):

```dart
enum UserRole { physio, patient }
enum AssignmentType { protocol, single }
enum CompletionStatus { done, skipped }

class Patient { // id,name,email,uid?,notes,primaryBodyPart?,lastActiveAt?,createdAt, inviteCode?, inviteExpiresAt?
  bool get redeemed => uid != null; }
class VideoItem { // id,title,bodyPart,durationSec,visibility('library'|'private'),privateToPatientId?,usageCount,createdAt
}
class TemplateItem { // videoId,order,sets,reps,holdSec
}
class ProtocolTemplate { // id,name,bodyPart,items,createdAt
}
class ExerciseItem { // videoId,order,sets,reps,holdSec,overridden, title,durationSec  (denormalized §4.7)
}
class Assignment { // id,patientId,type,name,sourceTemplateId?,bodyParts,daysOfWeek(Set<int>),items,active,seenByPatient,createdAt
}
class Completion {
  // id = '${date}_${assignmentId}_${videoId}' (deterministic, §9)
  // date 'YYYY-MM-DD', assignmentId, videoId, status, at
  static String idFor(String date, String assignmentId, String videoId) => '${date}_${assignmentId}_$videoId';
}
```

Write the full classes (fields, ==, copyWith) — no shortcuts. `daysOfWeek` is `Set<int>`, validated 1..7 in an `assert`.

- [ ] `repositories.dart`:

```dart
abstract class PatientsRepository {
  Stream<List<Patient>> watchPatients();
  Stream<Patient?> watchPatient(String id);
  Future<Result<Patient>> addPatient({required String name, required String email});
  Future<Result<void>> updateNotes(String patientId, String notes);
  Future<Result<String>> regenerateInvite(String patientId); // returns new code
}
abstract class LibraryRepository {
  Stream<List<VideoItem>> watchVideos();
  Future<Result<VideoItem>> addVideo({required String title, required String bodyPart,
      required int durationSec, String? privateToPatientId});
}
abstract class TemplatesRepository {
  Stream<List<ProtocolTemplate>> watchTemplates();
  Future<Result<ProtocolTemplate>> saveTemplate(ProtocolTemplate template);
}
abstract class AssignmentsRepository {
  Stream<List<Assignment>> watchForPatient(String patientId);
  Stream<List<Assignment>> watchAll();
  Future<Result<Assignment>> create(Assignment assignment); // increments video usageCounts
  Future<Result<void>> markSeen(String assignmentId);
}
abstract class CompletionsRepository {
  Stream<List<Completion>> watchForPatient(String patientId);
  Stream<Map<String, List<Completion>>> watchAllByPatient();
  Future<Result<void>> record(String patientId, Completion completion); // UPSERT by id (§9)
}
```

## Task 4: Domain engines (the no-bugs core) — TDD, exhaustive

**Files:** `lib/core/session_engine.dart`, `lib/core/adherence.dart` + tests.

- [ ] `session_engine.dart` types:

```dart
class SessionExercise { final Assignment assignment; final ExerciseItem item; final CompletionStatus? outcome; }
class TodaySession {
  final List<SessionExercise> exercises; // merged, ordered
  final List<String> protocolNames;      // contributing protocol names, deduped
  int get total => exercises.length;
  int get remaining => exercises.where((e) => e.outcome == null).length;
  int get firstUnrecordedIndex; // -1 when none remain
  bool get completedToday => total > 0 && remaining == 0;
}
TodaySession buildTodaySession({required List<Assignment> assignments,
    required List<Completion> completions, required DateTime now}) { ... }
```

Rules (test each, failing test first): only `active` assignments whose `daysOfWeek` contains `now.weekday`; order by assignment `createdAt` then `item.order`; outcome looked up by deterministic id for `Dates.ymd(now)`; resume = first null outcome (§5.3); yesterday's completions do NOT count today (§5.3 reset); empty schedule → total 0. Include the two-protocol merge test (knee then back, §4.6) and a single-video assignment in the merge.

- [ ] `adherence.dart`:

```dart
/// §6.2: done ÷ scheduled occurrences, from assignment creation to yesterday inclusive.
/// Returns null when no occurrences have elapsed (assignment created today / nothing scheduled yet).
double? adherencePercent({required Assignment assignment, required List<Completion> completions, required DateTime now});

enum DayMark { empty, done, skipped }
/// §6.1: last 7 days ending yesterday? NO — ending today (today may already have outcomes).
/// done: every scheduled item that day recorded done; skipped: ≥1 skip that day;
/// empty: otherwise (incl. unscheduled days).
List<DayMark> weekStrip({required List<Assignment> assignments, required List<Completion> completions, required DateTime now}); // length 7, index 6 = today

/// §6.1 red state: days since last completion of any kind across assignments;
/// null if patient has no active assignments or is un-redeemed.
int? daysSilent({required List<Assignment> assignments, required List<Completion> completions, required DateTime now});
```

Tests (failing first): perfect adherence = 1.0; skips lower it (skip counts in denominator only — a skipped occurrence is a scheduled occurrence without a done); today excluded (do 0 of 3 today, created yesterday with all done yesterday → still 1.0); created today → null; multi-item assignments count items×dates; weekStrip amber-beats-done on mixed day; daysSilent 9 for the silent fixture patient.

- [ ] `flutter test test/core/` — PASS.

## Task 5: Demo data + demo repositories

**Files:** `lib/data/demo_data.dart`, `lib/data/demo_repositories.dart` + `test/data/demo_repositories_test.dart`.

- [ ] `demo_data.dart` — a `DemoData.seed(DateTime now)` factory producing the §15.1 fixture. Patients (Croatian names, it's a Croatian practice): 1. **Ivana Horvat** — knee, adherent (~93%, all done last 3 weeks, occasional skip); 2. **Marko Babić** — shoulder, skips heel-slide-analog every day this week (amber pattern §5.2); 3. **Ana Kovačević** — TWO protocols (knee + lower back, §4.6), partial today (1 of N done → resume demo §5.3); 4. **Josip Novak** — silent 9 days (red row §6.1); 5. **Petra Marić** — assigned yesterday, hasn't opened → New badge demo (§5.4), adherence null; 6. **Luka Jurić** — un-redeemed invite (`invited` chip, code + expiry set). Library: ~10 videos across knee/shoulder/lower-back/neck, one private to Ana. Templates: "Meniscus Recovery — Phase 1" (knee, 4 items), "Rotator Cuff — Early" (shoulder, 3), "Core Stability" (lower back, 3). All completion history generated by looping `Dates.scheduledDatesBetween` — never hand-written date strings. **The demo patient identity is Ana** (`DemoData.currentPatientId`), so patient-side shows the two-protocol merge and resume.
- [ ] `demo_repositories.dart` — each repo wraps `Watchable<List<T>>` (or map). `create` on assignments also bumps `usageCount` in the library store and stamps `overridden` flags as given. `record` upserts by `completion.id` (replace if exists — test the double-tap: record done twice → one completion; record done then skipped → status skipped, still one doc). `markSeen` flips `seenByPatient`. Mutations must go through `Watchable.update` so every open screen reacts.
- [ ] Tests: seeded counts sane; upsert semantics; usageCount increment; watch emits on mutation.
- [ ] `flutter test` — PASS.

## Task 6: Design system

**Files:** `lib/design_system/tokens.dart`, `components.dart`, `week_strip.dart`, `hero_card.dart`, `demo_video_player.dart`. Reference `design-system.html` + spec §7 token table.

- [ ] `tokens.dart`: `abstract final class AppColors` with the §7 hex values exactly (`bg 0xFFFAF7F2`, `surface 0xFFFFFDFA`, `border 0xFFECE5DA`, `text 0xFF2B2620`, `textMuted 0xFF857B6E`, `accent 0xFF2C7A63`, `accentDeep 0xFF1F5A4C`, `accentSoft 0xFFA7D9C8`, `onAccent 0xFFFDFBF7`, `warning 0xFFB45309`, `danger 0xFFB3261E`). `heroGradient` = LinearGradient accentDeep→accent at 150°. `AppRadii` (card 13, chip 9, button 12). `buildTheme()` → `ThemeData` (Material 3, light only, scaffoldBackground bg, system fonts, base text size +1 step per §7 — bodyMedium 15, bodyLarge 17).
- [ ] `components.dart`: `AppCard` (surface, border hairline, radius 13, optional onTap), `PrimaryButton` (accent bg, onAccent text, full-width variant), `SecondaryButton` (outlined accent), `DosagePill` (label+value; `overridden` variant renders outlined accent border per §6.3), `StatusChip` (invited/private/new variants — `NewBadge` is StatusChip.new_ with accentSoft bg), `InitialsAvatar` (two-letter initials on accentSoft/accent), `SectionHeader`, `EmptyState` (icon+line of copy).
- [ ] `week_strip.dart`: `WeekStrip(marks: List<DayMark>, dotSize)` — filled accent = done, warning amber = skipped, border-only = empty. Row of 7, 4–6px gaps, never overflows (wrap in FittedBox when constrained).
- [ ] `hero_card.dart`: dark pine gradient card per `patient-home-hero.html`: eyebrow (`accentSoft`, letterspaced caps "TODAY'S SESSION"), headline (`8 exercises` / `1 remaining` / `Session complete ✓`), protocol names line (textMuted-on-dark = onAccent at 70%), embedded `WeekStrip`, full-width onAccent CTA (`Start today's session` / `Resume session` / disabled `Done for today`), optional `New` chip.
- [ ] `demo_video_player.dart` (§15.1): 16:9 dark container, exercise-name overlay, centered play/pause icon-button, thin progress bar animated over `durationSec` via `AnimationController` (pausable), body-part-seeded gradient poster. Exposes `onCompleted` callback. No real media.

## Task 7: App shell — role gate, router, providers

**Files:** `lib/main.dart`, `lib/app/app.dart`, `lib/app/router.dart`, `lib/app/role_cubit.dart`, `lib/features/role_gate/role_gate_page.dart`.

- [ ] `role_cubit.dart`: `class RoleCubit extends Cubit<UserRole?> { RoleCubit(): super(null); void enterAs(UserRole r); void signOut(); }`
- [ ] `role_gate_page.dart`: app wordmark, "Showcase build — pick a side" copy, two AppCards: **Enter as physio** (Dr. Tomislav Perić) / **Enter as patient** (Ana Kovačević). Small footnote that data resets on restart.
- [ ] `router.dart`: go_router with `refreshListenable` on RoleCubit (wrap in `GoRouterRefreshStream` helper or `BlocListener`-driven `ChangeNotifier`). Redirect: null role → `/`, physio → default `/physio/patients`, patient → `/patient/home`; role mismatch on branch → redirect to own home. Physio: `StatefulShellRoute.indexedStack` with 3 branches — Patients / Library / Templates (NavigationBar, accent indicator). Sub-routes: `/physio/patients/:id`, `/physio/patients/:id/assign` (+ `/picker`, `/dosage` as sub-pages of assign flow), `/patient/session`. Full-screen dialog route for upload sheet handled via showModalBottomSheet instead (no route).
- [ ] `app.dart`: `MultiRepositoryProvider` (5 repos, constructed once from a single `DemoData.seed(DateTime.now())`) → `BlocProvider<RoleCubit>` → `MaterialApp.router(theme: buildTheme())`. AppBar avatar menu on both shells: "Switch role" → `signOut()` (spec §15.2 live-mutation demo). `main.dart` = `runApp(const PhysioApp())`.
- [ ] `flutter run -d macos` boots to role gate; both shells reachable with placeholder tab bodies where features aren't merged yet — commit placeholders as plain `EmptyState` pages so the shell compiles standalone.

## Task 8 (feature agent): Physio — patients list + patient detail

**Files (only these):** `features/patients/*` + `test/features/patients_bloc_test.dart`, `test/features/patient_detail_bloc_test.dart`.

- [ ] `patients_bloc.dart`: input streams patients + all assignments + all completions; state `PatientsState(loading|loaded(rows))`, `PatientRow(patient, strip: List<DayMark>, adherenceLabel, daysSilent, invited)`. Rows sorted: silent-red first, then by name. bloc_test with seeded fakes: 6 rows, Josip flagged `daysSilent >= 7`, Luka `invited`.
- [ ] `patients_page.dart` per `physio-flow.html`: ListView of AppCards — InitialsAvatar, name, `primaryBodyPart · last active X`, right side WeekStrip or `invited` StatusChip; silent patients: danger-tinted subtitle "9 days silent". Tap → detail. FAB "Add patient" → simple dialog (name+email) calling `addPatient`.
- [ ] `patient_detail_bloc.dart`: one patient; state exposes active assignments each with `adherencePercent` + done/skip counts, single videos (type single), notes, invite state. Events: `NotesChanged` (debounced save), `RegenerateInvite`.
- [ ] `patient_detail_page.dart`: header (avatar, name, body part, last active); **Active protocols** cards (name, `X done · Y skipped`, adherence % or `—`, per-item count); **Also assigned** singles (private marked); **Private notes** (TextField, surface card, autosaves); primary `Assign something` → `/physio/patients/:id/assign`; un-redeemed: invite card with code, expiry, `Regenerate code` button.
- [ ] Tests pass; both screens added to overflow sweep list (Task 13 collects them).

## Task 9 (feature agent): Physio — library + simulated upload

**Files (only these):** `features/library/*` + `test/features/upload_cubit_test.dart`.

- [ ] `library_bloc.dart`: watches videos, groups by bodyPart (fixed order: Knee, Shoulder, Lower back, Neck, then others alpha); state has `Map<String, List<VideoItem>>`.
- [ ] `library_page.dart`: SectionHeaders per body part; rows: gradient thumb placeholder (seeded by bodyPart), title, `1:45 · used by 9`, `private` StatusChip when applicable. AppBar ＋ opens `upload_sheet.dart`.
- [ ] `upload_cubit.dart`: states `UploadIdle → UploadCompressing(progress) → UploadUploading(progress) → UploadDone(video)` / `UploadFailed(message, retryable)`. Simulation: injectable `TickerFn`/`Duration` so tests run at zero delay (constructor takes `stepDelay = const Duration(milliseconds: 60)`); compression 0→1 in ~2s, upload 0→1 in ~1.5s, then calls `LibraryRepository.addVideo`. `retry()` re-runs from compressing without re-entering form (§12 error handling).
- [ ] `upload_sheet.dart` (modal bottom sheet): title field, bodyPart choice chips, duration stepper (`0:30`–`5:00`), optional "Private to patient" dropdown (patients from repo — read via `context.read<PatientsRepository>()`; allowed, it's an interface), progress UI for the two stages, success state auto-closes. Used from Library ＋ AND embeddable in the assign-flow picker (§6.4) — export `showUploadSheet(BuildContext, {String? preselectPatientId})`.
- [ ] bloc_test: full happy path emits ordered states; failure + retry path.

## Task 10 (feature agent): Physio — templates + assign flow

**Files (only these):** `features/templates/*`, `features/assignments/*` + `test/features/assign_flow_bloc_test.dart`.

- [ ] `templates_bloc.dart` + `templates_page.dart`: list of template cards (name, bodyPart, `4 exercises`, total est. duration). Read-only list is enough — template *creation* happens via assign-flow "save as template" (§4.5.2).
- [ ] `assign_flow_bloc.dart` — the heart (§4.5, §4.4, §4.6). State machine:

```dart
class AssignFlowState { // fork | building
  final AssignmentType type; final ProtocolTemplate? sourceTemplate;
  final String name; final Set<int> daysOfWeek; // default {1..7}
  final List<ExerciseItem> items;               // live-editable copy
  final Map<String, TemplateItem> templateDefaults; // by videoId, for `overridden`
  final int existingDailyTotal;                 // other active assignments' items due daily (§4.6 guard)
  final bool saveAsTemplate; final AssignSubmitStatus status;
}
```

Events: `StartedFromTemplate(t)` (deep-copies items — SNAPSHOT §4.4, stamps denormalized title/duration from library), `StartedCustom`, `StartedSingle(video)`, `ItemDosageChanged(videoId, sets/reps/holdSec)` (recomputes `overridden` by comparing to `templateDefaults`), `ItemsReordered(from,to)`, `ItemRemoved`, `VideoAdded(video)`, `DaysChanged`, `NameChanged`, `SaveAsTemplateToggled`, `Submitted` → builds `Assignment` (id from a `IdFn` injectable), calls `create`, optionally `saveTemplate`. bloc_test: template copy is deep (mutating flow state never touches the template object); overridden flag flips on and back off when value returns to default; submit produces correct denormalized items; single-video path skips dosage.
- [ ] `assign_fork_page.dart`: three AppCards (From template / Build custom / Send one video) with recent templates listed under the first (§6.3); template tap → dosage editor directly.
- [ ] `video_picker_page.dart`: library grouped like Task 9, checkmark multi-select (single-select in single mode), private-to-this-patient videos included, inline "Film new" button → `showUploadSheet(preselectPatientId:)`; on sheet success the new video appears selected.
- [ ] `dosage_editor_page.dart` per §6.3: ReorderableListView of exercise cards — drag handle, title, duration, three DosagePills (sets/reps/hold) with stepper on tap, `overridden` pills outlined; remove via trailing icon; days-of-week toggle row (Mon–Sun chips); name field; "Save as template" switch (hidden for single); footer summary + **confirm**: when `existingDailyTotal > 0` show the §4.6 guard line — `Ana will have 11 exercises daily` — styled warning, requiring the same button pressed once more (`Confirm anyway`). On success pop to patient detail (snackbar `Assigned ✓`).

## Task 11 (feature agent): Patient — home

**Files (only these):** `features/home/*` + `test/features/patient_home_bloc_test.dart`.

- [ ] `patient_home_bloc.dart`: for `DemoData.currentPatientId`, combines assignments + completions → `buildTodaySession` for hero (count/remaining/completed states, protocol names, `New` if any contributing assignment unseen), 7-day `weekStrip`, "Also assigned" singles (with New badges), body-part sections of remaining protocol content (only when >1 category, §5.1). Event `AssignmentOpened(id)` → `markSeen`.
- [ ] `patient_home_page.dart` per `patient-home-hero.html` + §5.1: header (greeting `Good morning, Ana` by time-of-day, InitialsAvatar menu → Switch role); HeroCard (Start/Resume/Done states wired to `/patient/session`); Also-assigned rows (thumb, title, duration, New badge, tap → full-screen DemoVideoPlayer page-sheet + markSeen); body-part sections. Empty state (no assignments): friendly `EmptyState` — "Nothing assigned yet. Your physio will set you up."
- [ ] bloc_test with Ana fixture: hero says remaining (resume state), New badge present for Petra fixture when bloc pointed at her id, seen clears on open.

## Task 12 (feature agent): Patient — session player

**Files (only these):** `features/session/*` + `test/features/session_bloc_test.dart`, `test/widget/session_flow_test.dart`.

- [ ] `session_bloc.dart` (§5.2, §5.3): init loads `buildTodaySession(now)`, `currentIndex = firstUnrecordedIndex`. Events `DonePressed` / `SkipPressed` → `CompletionsRepository.record` with deterministic id, advance to next *unrecorded* index (skipping already-recorded ones), emit `SessionComplete` when none remain. State: `SessionInProgress(exercises, currentIndex, position 'Exercise 2 of 3')` / `SessionComplete(doneCount, skippedCount)` / `SessionEmpty`.
- [ ] `session_page.dart`: dark scaffold regardless of theme (§5.2); DemoVideoPlayer top; position line + exercise name; DosagePill row (sets/reps/hold — hold hidden when 0); big **Done · next exercise** PrimaryButton (onAccent-on-accent), **Skip this one** text button (warning color); close (X) top-left pops (progress already persisted — §5.3); completion screen: check icon, `Session complete`, done/skipped counts, `Back to home`.
- [ ] bloc_test: done→advance; skip records `skipped`; resume skips recorded; double-record upsert (tap done twice fast → one completion); completing last → SessionComplete.
- [ ] `session_flow_test.dart` widget test: pump real page with demo repos (Ana), tap through Done/Skip to completion, assert completions in repo and hero state change on home.

## Task 13: Overflow sweep + integration polish

**Files:** `test/widget/harness.dart`, `test/widget/overflow_sweep_test.dart`, plus router wiring of all feature pages (replacing Task 7 placeholders).

- [ ] `harness.dart`: `Future<void> pumpScreen(WidgetTester t, Widget page, {Size size, UserRole role})` — sets `t.view.physicalSize`/`devicePixelRatio=1` (addTearDown reset), wraps in repos + RoleCubit + MaterialApp(theme). Overflow errors surface as test failures by default — do not swallow FlutterErrors.
- [ ] `overflow_sweep_test.dart`: for each of [RoleGate, PatientsPage, PatientDetailPage(each of the 6 patients — invited and silent variants included), LibraryPage, TemplatesPage, AssignForkPage, VideoPickerPage, DosageEditorPage, PatientHomePage(Ana + empty-state patient), SessionPage, upload sheet] × sizes [320×568, 375×667, 430×932] pump + `pumpAndSettle` + `expect(tester.takeException(), isNull)`. Long-content guards: patient with a 40-char name and 6 protocols added to DemoData specifically for this sweep? — No: construct the stress patient inside the test via repositories to keep the showcase fixture clean.
- [ ] Wire real pages into router; delete placeholders. `flutter analyze` → 0 issues. `flutter test` → all pass.

## Task 14: Run + showcase

- [ ] `flutter run -d macos` (background) — walk both roles; fix anything visual against the mockups.
- [ ] `flutter run -d chrome` and capture screenshots of: role gate, physio patients list, Ana detail, dosage editor with overridden pills, patient home hero (resume state), session player, completion screen.
- [ ] Present to owner with run instructions. NO commit (owner commits explicitly).

---

## Self-Review Notes

- Spec coverage: §4.4 snapshot (T10), §4.5 three paths (T10), §4.6 merge+guard (T4/T10/T11), §4.7 denormalized items (T3/T10), §5.1 home (T11), §5.2 player+skip (T12), §5.3 resume (T4/T12), §5.4 New badge (T3 seenByPatient/T11), §6.1 strips+silence (T4/T8), §6.2 adherence (T4/T8), §6.3 overridden pills (T10), §6.4 inline upload (T9/T10), §7 tokens (T6), §15 all. Auth/§10 rules intentionally out (spec §15.4).
- Type consistency: `DayMark`, `ExerciseItem`, `Completion.idFor`, repo signatures are defined once in T2–T4 and referenced verbatim later.
