import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/core/session_engine.dart';
import 'package:physio_app/domain/models.dart';

import 'fixtures.dart';

void main() {
  // 2026-08-25 is a Tuesday (weekday 2).
  final now = DateTime(2026, 8, 25, 9, 30);

  group('buildTodaySession', () {
    test('merges two protocols ordered by createdAt then item order', () {
      final knee = protocol('a-knee',
          items: [item('v1', 0), item('v2', 1)], createdAt: DateTime(2026, 8, 10), name: 'Knee');
      final back = protocol('a-back',
          items: [item('v3', 1), item('v4', 0)], createdAt: DateTime(2026, 8, 15), name: 'Back');

      final s = buildTodaySession(assignments: [back, knee], completions: [], now: now);

      expect(s.total, 4);
      expect(s.exercises.map((e) => e.item.videoId), ['v1', 'v2', 'v4', 'v3']);
      expect(s.protocolNames, ['Knee', 'Back']);
      expect(s.remaining, 4);
      expect(s.firstUnrecordedIndex, 0);
    });

    test('excludes inactive, off-day, and single assignments', () {
      final offDay = protocol('a-off',
          items: [item('v1', 0)], daysOfWeek: {1, 3, 5}, createdAt: DateTime(2026, 8, 10));
      final inactive =
          protocol('a-in', items: [item('v2', 0)], createdAt: DateTime(2026, 8, 10), active: false);
      final loose = single('a-single', createdAt: DateTime(2026, 8, 10));

      final s = buildTodaySession(assignments: [offDay, inactive, loose], completions: [], now: now);
      expect(s.total, 0);
      expect(s.completedToday, isFalse);
      expect(s.firstUnrecordedIndex, -1);
    });

    test('resume lands on first unrecorded exercise (§5.3)', () {
      final p = protocol('a1',
          items: [item('v1', 0), item('v2', 1), item('v3', 2)], createdAt: DateTime(2026, 8, 10));
      final s = buildTodaySession(
        assignments: [p],
        completions: [
          outcome('2026-08-25', 'a1', 'v1', CompletionStatus.done),
          outcome('2026-08-25', 'a1', 'v2', CompletionStatus.skipped),
        ],
        now: now,
      );
      expect(s.remaining, 1);
      expect(s.firstUnrecordedIndex, 2);
      expect(s.doneCount, 1);
      expect(s.skippedCount, 1);
    });

    test('yesterday outcomes never carry into today (§5.3 reset)', () {
      final p = protocol('a1', items: [item('v1', 0)], createdAt: DateTime(2026, 8, 10));
      final s = buildTodaySession(
        assignments: [p],
        completions: [outcome('2026-08-24', 'a1', 'v1', CompletionStatus.done)],
        now: now,
      );
      expect(s.remaining, 1);
      expect(s.completedToday, isFalse);
    });

    test('completedToday when every exercise has an outcome', () {
      final p = protocol('a1', items: [item('v1', 0), item('v2', 1)], createdAt: DateTime(2026, 8, 10));
      final s = buildTodaySession(
        assignments: [p],
        completions: [
          outcome('2026-08-25', 'a1', 'v1', CompletionStatus.done),
          outcome('2026-08-25', 'a1', 'v2', CompletionStatus.skipped),
        ],
        now: now,
      );
      expect(s.completedToday, isTrue);
      expect(s.remaining, 0);
    });
  });
}
