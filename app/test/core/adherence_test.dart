import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/core/adherence.dart';
import 'package:physio_app/domain/models.dart';

import 'fixtures.dart';

void main() {
  // 2026-08-25 is a Tuesday.
  final now = DateTime(2026, 8, 25, 9, 30);

  group('adherencePercent', () {
    test('perfect adherence is 1.0', () {
      final a = protocol('a1', items: [item('v1', 0)], createdAt: DateTime(2026, 8, 22));
      // Scheduled: 22, 23, 24 (today excluded).
      final c = [
        outcome('2026-08-22', 'a1', 'v1', CompletionStatus.done),
        outcome('2026-08-23', 'a1', 'v1', CompletionStatus.done),
        outcome('2026-08-24', 'a1', 'v1', CompletionStatus.done),
      ];
      expect(adherencePercent(assignment: a, completions: c, now: now), 1.0);
    });

    test('skips count against adherence (§6.2)', () {
      final a = protocol('a1', items: [item('v1', 0), item('v2', 1)], createdAt: DateTime(2026, 8, 23));
      // Scheduled: 23, 24 -> 4 occurrences.
      final c = [
        outcome('2026-08-23', 'a1', 'v1', CompletionStatus.done),
        outcome('2026-08-23', 'a1', 'v2', CompletionStatus.skipped),
        outcome('2026-08-24', 'a1', 'v1', CompletionStatus.done),
        // v2 on 24th: nothing recorded.
      ];
      expect(adherencePercent(assignment: a, completions: c, now: now), 0.5);
    });

    test('today is excluded from the denominator (§6.2)', () {
      final a = protocol('a1', items: [item('v1', 0)], createdAt: DateTime(2026, 8, 24));
      // Only the 24th counts; today's undone work does not lower the number.
      final c = [outcome('2026-08-24', 'a1', 'v1', CompletionStatus.done)];
      expect(adherencePercent(assignment: a, completions: c, now: now), 1.0);
    });

    test('assigned today -> null, never 0%', () {
      final a = protocol('a1', items: [item('v1', 0)], createdAt: DateTime(2026, 8, 25, 8));
      expect(adherencePercent(assignment: a, completions: const [], now: now), isNull);
    });

    test('respects daysOfWeek subsets', () {
      // Mon/Wed/Fri protocol created Mon 17th; through Mon 24th inclusive:
      // 17, 19, 21, 24 -> 4 dates x 1 item.
      final a = protocol('a1',
          items: [item('v1', 0)], daysOfWeek: {1, 3, 5}, createdAt: DateTime(2026, 8, 17));
      final c = [
        outcome('2026-08-17', 'a1', 'v1', CompletionStatus.done),
        outcome('2026-08-19', 'a1', 'v1', CompletionStatus.done),
        // 21st missed entirely, 24th done. Off-day completion must not count:
        outcome('2026-08-18', 'a1', 'v1', CompletionStatus.done),
        outcome('2026-08-24', 'a1', 'v1', CompletionStatus.done),
      ];
      expect(adherencePercent(assignment: a, completions: c, now: now), 0.75);
    });

    test('another assignment\'s completions are ignored', () {
      final a = protocol('a1', items: [item('v1', 0)], createdAt: DateTime(2026, 8, 24));
      final c = [outcome('2026-08-24', 'other', 'v1', CompletionStatus.done)];
      expect(adherencePercent(assignment: a, completions: c, now: now), 0.0);
    });
  });

  group('weekStrip', () {
    test('marks done, skipped, empty; index 6 is today', () {
      final a = protocol('a1', items: [item('v1', 0)], createdAt: DateTime(2026, 8, 1));
      final c = [
        outcome('2026-08-24', 'a1', 'v1', CompletionStatus.done), // yesterday
        outcome('2026-08-22', 'a1', 'v1', CompletionStatus.skipped),
      ];
      final strip = weekStrip(assignments: [a], completions: c, now: now);
      expect(strip.length, 7);
      expect(strip[5], DayMark.done); // 24th
      expect(strip[3], DayMark.skipped); // 22nd
      expect(strip[6], DayMark.empty); // today, nothing yet
      expect(strip[0], DayMark.empty); // 19th
    });

    test('skip beats done on a mixed day', () {
      final a = protocol('a1', items: [item('v1', 0), item('v2', 1)], createdAt: DateTime(2026, 8, 1));
      final c = [
        outcome('2026-08-24', 'a1', 'v1', CompletionStatus.done),
        outcome('2026-08-24', 'a1', 'v2', CompletionStatus.skipped),
      ];
      expect(weekStrip(assignments: [a], completions: c, now: now)[5], DayMark.skipped);
    });

    test('partial done day without skips stays empty', () {
      final a = protocol('a1', items: [item('v1', 0), item('v2', 1)], createdAt: DateTime(2026, 8, 1));
      final c = [outcome('2026-08-24', 'a1', 'v1', CompletionStatus.done)];
      expect(weekStrip(assignments: [a], completions: c, now: now)[5], DayMark.empty);
    });

    test('days before assignment creation are empty even with full week schedule', () {
      final a = protocol('a1', items: [item('v1', 0)], createdAt: DateTime(2026, 8, 24));
      final c = [outcome('2026-08-24', 'a1', 'v1', CompletionStatus.done)];
      final strip = weekStrip(assignments: [a], completions: c, now: now);
      expect(strip[5], DayMark.done);
      expect(strip.sublist(0, 5), everyElement(DayMark.empty));
    });
  });

  group('daysSilent', () {
    test('nine silent days', () {
      final a = protocol('a1', items: [item('v1', 0)], createdAt: DateTime(2026, 8, 1));
      final c = [outcome('2026-08-16', 'a1', 'v1', CompletionStatus.done)];
      expect(daysSilent(assignments: [a], completions: c, now: now), 9);
    });

    test('active today -> 0', () {
      final a = protocol('a1', items: [item('v1', 0)], createdAt: DateTime(2026, 8, 1));
      final c = [outcome('2026-08-25', 'a1', 'v1', CompletionStatus.skipped)];
      expect(daysSilent(assignments: [a], completions: c, now: now), 0);
    });

    test('never recorded -> since earliest assignment', () {
      final a = protocol('a1', items: [item('v1', 0)], createdAt: DateTime(2026, 8, 20));
      expect(daysSilent(assignments: [a], completions: const [], now: now), 5);
    });

    test('no active assignments -> null', () {
      expect(daysSilent(assignments: const [], completions: const [], now: now), isNull);
    });
  });
}
