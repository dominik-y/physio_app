import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/core/dates.dart';
import 'package:physio_app/core/result.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/data/demo_repositories.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/features/session/session_bloc.dart';

import '../core/fixtures.dart';

/// Wraps a real [CompletionsRepository] but lets a test hold `record()`
/// pending, so a second event can genuinely be dispatched while the first
/// is still in flight (exercises the double-fire guard deterministically).
class _GatedCompletionsRepository implements CompletionsRepository {
  final CompletionsRepository inner;
  Completer<void>? gate;

  _GatedCompletionsRepository(this.inner);

  @override
  Stream<List<Completion>> watchForPatient(String patientId) => inner.watchForPatient(patientId);

  @override
  Stream<Map<String, List<Completion>>> watchAllByPatient() => inner.watchAllByPatient();

  @override
  Future<Result<void>> record(String patientId, Completion completion) async {
    if (gate != null) await gate!.future;
    return inner.record(patientId, completion);
  }
}

void main() {
  // Matches the harness/core fixtures (a Tuesday).
  final testNow = DateTime(2026, 8, 25, 9, 30);
  final today = Dates.ymd(testNow);
  DemoStore store() => DemoStore.seed(now: () => testNow);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  SessionBloc bloc(DemoStore s, {String patientId = DemoData.currentPatientId}) => SessionBloc(
        patientId: patientId,
        assignmentsRepository: DemoAssignmentsRepository(s),
        completionsRepository: DemoCompletionsRepository(s),
        now: () => testNow,
      );

  group('SessionBloc — Ana (two protocols, resume today)', () {
    test('starts at index 1: v-quad already done this morning', () async {
      final s = store();
      final b = bloc(s);
      addTearDown(b.close);

      b.add(const SessionStarted());
      await settle();

      final state = b.state;
      expect(state, isA<SessionInProgress>());
      state as SessionInProgress;
      expect(state.total, 7); // 4 knee + 3 back
      expect(state.currentIndex, 1);
      expect(state.current.item.videoId, 'v-heel');
      expect(state.doneSoFar, 1);
      expect(state.skippedSoFar, 0);
    });

    test('DonePressed records a completion and advances to the next unrecorded exercise', () async {
      final s = store();
      final b = bloc(s);
      addTearDown(b.close);

      b.add(const SessionStarted());
      await settle();

      b.add(const DonePressed());
      await settle();

      final state = b.state as SessionInProgress;
      expect(state.currentIndex, 2);
      expect(state.current.item.videoId, 'v-bridge');
      expect(state.doneSoFar, 2);

      final recorded = s.completions.value['pat-ana']!
          .singleWhere((c) => c.id == Completion.idFor(today, 'as-ana-knee', 'v-heel'));
      expect(recorded.status, CompletionStatus.done);
    });

    test('SkipPressed records a skipped completion and advances', () async {
      final s = store();
      final b = bloc(s);
      addTearDown(b.close);

      b.add(const SessionStarted());
      await settle();
      b.add(const DonePressed()); // v-heel
      await settle();
      b.add(const SkipPressed()); // v-bridge
      await settle();

      final state = b.state as SessionInProgress;
      expect(state.currentIndex, 3);
      expect(state.current.item.videoId, 'v-step');
      expect(state.skippedSoFar, 1);

      final recorded = s.completions.value['pat-ana']!
          .singleWhere((c) => c.id == Completion.idFor(today, 'as-ana-knee', 'v-bridge'));
      expect(recorded.status, CompletionStatus.skipped);
    });

    test('finishing all 6 remaining exercises reaches SessionComplete with today\'s full counts', () async {
      final s = store();
      final b = bloc(s);
      addTearDown(b.close);

      b.add(const SessionStarted());
      await settle();

      // v-heel, v-bridge, v-step, v-cat, v-bird, v-pelvic — mix done/skip.
      b.add(const DonePressed());
      await settle();
      b.add(const SkipPressed());
      await settle();
      b.add(const DonePressed());
      await settle();
      b.add(const DonePressed());
      await settle();
      b.add(const SkipPressed());
      await settle();
      b.add(const DonePressed());
      await settle();

      final state = b.state;
      expect(state, isA<SessionComplete>());
      state as SessionComplete;
      expect(state.doneCount + state.skippedCount, 7);
      expect(state.doneCount, 5); // v-quad (seed) + 4 done taps
      expect(state.skippedCount, 2);

      final all = s.completions.value['pat-ana']!.where((c) => c.date == today);
      expect(all.length, 7);
    });

    test('double-tap Done rapidly records exactly one completion for that exercise', () async {
      final s = store();
      final gated = _GatedCompletionsRepository(DemoCompletionsRepository(s));
      final b = SessionBloc(
        patientId: DemoData.currentPatientId,
        assignmentsRepository: DemoAssignmentsRepository(s),
        completionsRepository: gated,
        now: () => testNow,
      );
      addTearDown(b.close);

      b.add(const SessionStarted());
      await settle();

      // Hold the first record() pending so the second DonePressed is
      // genuinely dispatched while the first is still in flight.
      gated.gate = Completer<void>();
      b.add(const DonePressed());
      await settle();
      b.add(const DonePressed()); // must be ignored: a record is in flight
      await settle();

      gated.gate!.complete();
      await settle();

      final matches =
          s.completions.value['pat-ana']!.where((c) => c.id == Completion.idFor(today, 'as-ana-knee', 'v-heel'));
      expect(matches.length, 1);

      // The guard means only one exercise advanced, not two.
      final state = b.state as SessionInProgress;
      expect(state.currentIndex, 2);
      expect(state.doneSoFar, 2);
    });

    test('markSeen is a no-op when assignments are already seen', () async {
      final s = store();
      final b = bloc(s);
      addTearDown(b.close);

      b.add(const SessionStarted());
      await settle();

      final seen = s.assignments.value.where((a) => a.id == 'as-ana-knee' || a.id == 'as-ana-back');
      expect(seen.every((a) => a.seenByPatient), isTrue);
    });
  });

  test('markSeen flips seenByPatient for every distinct contributing assignment (amendment 5)', () async {
    final s = store();
    final customCreatedAt = testNow.subtract(const Duration(days: 5));
    s.assignments.update((list) => [
          ...list,
          protocol('as-custom-1',
              patientId: 'p-custom',
              items: [item('v-x1', 0), item('v-x2', 1)],
              createdAt: customCreatedAt,
              seen: false),
          protocol('as-custom-2',
              patientId: 'p-custom',
              items: [item('v-x3', 0)],
              createdAt: customCreatedAt.add(const Duration(days: 2)),
              seen: false),
        ]);

    final b = bloc(s, patientId: 'p-custom');
    addTearDown(b.close);

    b.add(const SessionStarted());
    await settle();

    final updated = s.assignments.value.where((a) => a.patientId == 'p-custom');
    expect(updated.length, 2);
    expect(updated.every((a) => a.seenByPatient), isTrue);
  });

  test('SessionEmpty when the patient has no protocol due today', () async {
    final s = store();
    final b = bloc(s, patientId: 'nobody');
    addTearDown(b.close);

    b.add(const SessionStarted());
    await settle();

    expect(b.state, isA<SessionEmpty>());
  });
}
