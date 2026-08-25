import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/core/adherence.dart';
import 'package:physio_app/core/session_engine.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/data/demo_repositories.dart';
import 'package:physio_app/domain/models.dart';

void main() {
  final now = DateTime(2026, 8, 25, 10, 0);
  DemoStore store() => DemoStore.seed(now: () => now);

  group('DemoData fixture invariants', () {
    final data = DemoData.seed(now);
    List<Completion> completionsOf(String id) => data.completionsByPatient[id] ?? const [];
    List<Assignment> assignmentsOf(String id) =>
        data.assignments.where((a) => a.patientId == id).toList();

    test('six patients, one un-redeemed', () {
      expect(data.patients.length, 6);
      expect(data.patients.where((p) => !p.redeemed).map((p) => p.name), ['Luka Jurić']);
    });

    test('Ana has two active protocols and a resumable session today', () {
      final session = buildTodaySession(
        assignments: assignmentsOf('pat-ana'),
        completions: completionsOf('pat-ana'),
        now: now,
      );
      expect(session.protocolNames.length, 2);
      expect(session.total, 7); // 4 knee + 3 back
      expect(session.doneCount, 1); // v-quad done this morning
      expect(session.firstUnrecordedIndex, 1);
    });

    test('Josip is 9 days silent', () {
      expect(
        daysSilent(
            assignments: assignmentsOf('pat-josip'),
            completions: completionsOf('pat-josip'),
            now: now),
        9,
      );
    });

    test('Ivana adheres above 90%', () {
      final a = assignmentsOf('pat-ivana').single;
      final pct = adherencePercent(assignment: a, completions: completionsOf('pat-ivana'), now: now)!;
      expect(pct, greaterThan(0.9));
      expect(pct, lessThan(1.0)); // she does skip sometimes
    });

    test('Marko skipped pendulum swings every day this week', () {
      final skips = completionsOf('pat-marko')
          .where((c) => c.videoId == 'v-pend' && c.status == CompletionStatus.skipped);
      expect(skips.length, greaterThanOrEqualTo(6));
    });

    test('Petra assigned today: unseen, adherence null', () {
      final a = assignmentsOf('pat-petra').single;
      expect(a.seenByPatient, isFalse);
      expect(adherencePercent(assignment: a, completions: const [], now: now), isNull);
    });

    test('seeded usage counts match assignments', () {
      final quad = data.videos.firstWhere((v) => v.id == 'v-quad');
      // meniscus template assigned to Ivana, Ana, Josip.
      expect(quad.usageCount, 3);
    });
  });

  group('Demo repositories', () {
    test('record upserts by deterministic id (double-tap safe)', () async {
      final s = store();
      final repo = DemoCompletionsRepository(s);
      final done = Completion.forDay(
          date: '2026-08-25',
          assignmentId: 'as-ana-knee',
          videoId: 'v-heel',
          status: CompletionStatus.done,
          at: now);
      final before = s.completions.value['pat-ana']!.length;
      await repo.record('pat-ana', done);
      await repo.record('pat-ana', done); // double tap
      expect(s.completions.value['pat-ana']!.length, before + 1);

      final skipped = Completion.forDay(
          date: '2026-08-25',
          assignmentId: 'as-ana-knee',
          videoId: 'v-heel',
          status: CompletionStatus.skipped,
          at: now);
      await repo.record('pat-ana', skipped);
      final stored = s.completions.value['pat-ana']!.where((c) => c.id == done.id).toList();
      expect(stored.length, 1);
      expect(stored.single.status, CompletionStatus.skipped);
    });

    test('create bumps usage counts and notifies watchers', () async {
      final s = store();
      final repo = DemoAssignmentsRepository(s);
      final quadBefore =
          s.videos.value.firstWhere((v) => v.id == 'v-quad').usageCount;
      final a = Assignment(
        id: 'as-new',
        patientId: 'pat-luka',
        type: AssignmentType.single,
        name: 'Test',
        bodyParts: const ['Knee'],
        daysOfWeek: const {1, 2, 3, 4, 5, 6, 7},
        items: const [
          ExerciseItem(
              videoId: 'v-quad',
              order: 0,
              sets: 3,
              reps: 10,
              title: 'Seated quad extension',
              durationSec: 105,
              bodyPart: 'Knee'),
        ],
        createdAt: now,
      );
      await repo.create(a);
      expect(s.videos.value.firstWhere((v) => v.id == 'v-quad').usageCount, quadBefore + 1);
      expect(await repo.watchForPatient('pat-luka').first, [a]);
    });

    test('markSeen flips the flag once', () async {
      final s = store();
      final repo = DemoAssignmentsRepository(s);
      await repo.markSeen('as-ana-single');
      expect(
          s.assignments.value.firstWhere((a) => a.id == 'as-ana-single').seenByPatient, isTrue);
    });

    test('regenerateInvite issues a fresh code with future expiry', () async {
      final s = store();
      final repo = DemoPatientsRepository(s);
      final result = await repo.regenerateInvite('pat-luka');
      final code = result.valueOrNull!;
      expect(code, matches(RegExp(r'^[A-Z2-9]{3}-[A-Z2-9]{4}$')));
      final luka = s.patients.value.firstWhere((p) => p.id == 'pat-luka');
      expect(luka.inviteCode, code);
      expect(luka.inviteExpiresAt!.isAfter(now), isTrue);
    });

    test('recording marks the patient active', () async {
      final s = store();
      await DemoCompletionsRepository(s).record(
        'pat-petra',
        Completion.forDay(
            date: '2026-08-25',
            assignmentId: 'as-petra-back',
            videoId: 'v-cat',
            status: CompletionStatus.done,
            at: now),
      );
      expect(s.patients.value.firstWhere((p) => p.id == 'pat-petra').lastActiveAt, now);
    });
  });
}
