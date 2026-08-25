import 'package:physio_app/core/dates.dart';
import 'package:physio_app/domain/models.dart';

/// Spec §6.2: done outcomes ÷ scheduled occurrences, counted from the
/// assignment's creation date through *yesterday* (today is excluded until the
/// day ends). Skips count against adherence by contributing to the denominator
/// and never the numerator. Returns null when no occurrences have elapsed yet
/// (e.g. assigned today) — render as '—', never as 0%.
double? adherencePercent({
  required Assignment assignment,
  required List<Completion> completions,
  required DateTime now,
}) {
  final dates = Dates.scheduledDatesBetween(
    daysOfWeek: assignment.daysOfWeek,
    from: assignment.createdAt,
    toExclusive: now, // dateOnly(now) is exclusive -> yesterday is the last day
  );
  final scheduled = dates.length * assignment.items.length;
  if (scheduled == 0) return null;

  final dateKeys = dates.map(Dates.ymd).toSet();
  final done = completions
      .where((c) =>
          c.assignmentId == assignment.id &&
          c.status == CompletionStatus.done &&
          dateKeys.contains(c.date))
      .length;
  return done / scheduled;
}

enum DayMark { empty, done, skipped }

/// Spec §6.1: seven dots, oldest first, index 6 = today.
/// done = every item scheduled that day recorded done; skipped = at least one
/// skip that day; empty = otherwise (including unscheduled days and partial
/// days with no skips). Only counts an assignment on days on/after its
/// creation date.
List<DayMark> weekStrip({
  required List<Assignment> assignments,
  required List<Completion> completions,
  required DateTime now,
}) {
  final active = assignments.where((a) => a.active).toList();
  final byDate = <String, List<Completion>>{};
  for (final c in completions) {
    (byDate[c.date] ??= []).add(c);
  }

  final marks = <DayMark>[];
  for (var i = 6; i >= 0; i--) {
    final day = DateTime(now.year, now.month, now.day - i);
    final key = Dates.ymd(day);
    var scheduled = 0;
    final dueIds = <String>{};
    for (final a in active) {
      if (a.daysOfWeek.contains(day.weekday) && !Dates.dateOnly(a.createdAt).isAfter(day)) {
        scheduled += a.items.length;
        dueIds.add(a.id);
      }
    }
    final dayCompletions =
        (byDate[key] ?? const []).where((c) => dueIds.contains(c.assignmentId)).toList();
    final skips = dayCompletions.where((c) => c.status == CompletionStatus.skipped).length;
    final done = dayCompletions.where((c) => c.status == CompletionStatus.done).length;

    if (skips > 0) {
      marks.add(DayMark.skipped);
    } else if (scheduled > 0 && done >= scheduled) {
      marks.add(DayMark.done);
    } else {
      marks.add(DayMark.empty);
    }
  }
  return marks;
}

/// Spec §6.1 red state: whole days since the patient last recorded any
/// outcome. Falls back to days since the earliest active assignment if the
/// patient never recorded anything. Null when there is nothing assigned (or
/// the patient hasn't redeemed their invite — caller's check).
int? daysSilent({
  required List<Assignment> assignments,
  required List<Completion> completions,
  required DateTime now,
}) {
  final active = assignments.where((a) => a.active).toList();
  if (active.isEmpty) return null;

  DateTime? last;
  for (final c in completions) {
    if (last == null || c.at.isAfter(last)) last = c.at;
  }
  last ??= active.map((a) => a.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);
  return Dates.dateOnly(now).difference(Dates.dateOnly(last)).inDays;
}
