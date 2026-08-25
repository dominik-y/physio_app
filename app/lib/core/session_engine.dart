import 'package:equatable/equatable.dart';
import 'package:physio_app/core/dates.dart';
import 'package:physio_app/domain/models.dart';

/// One exercise occurrence in today's merged session, with its recorded
/// outcome for today (null = not yet done or skipped).
class SessionExercise extends Equatable {
  final Assignment assignment;
  final ExerciseItem item;
  final CompletionStatus? outcome;

  const SessionExercise({required this.assignment, required this.item, this.outcome});

  @override
  List<Object?> get props => [assignment.id, item, outcome];
}

/// Today's guided session, merged across active protocols (spec §4.6).
/// Single-video assignments are browsed from "Also assigned", not merged here.
class TodaySession extends Equatable {
  final List<SessionExercise> exercises;
  final List<String> protocolNames;

  const TodaySession({required this.exercises, required this.protocolNames});

  int get total => exercises.length;
  int get remaining => exercises.where((e) => e.outcome == null).length;
  int get doneCount => exercises.where((e) => e.outcome == CompletionStatus.done).length;
  int get skippedCount => exercises.where((e) => e.outcome == CompletionStatus.skipped).length;

  /// Resume point (spec §5.3). -1 when nothing remains.
  int get firstUnrecordedIndex => exercises.indexWhere((e) => e.outcome == null);

  bool get completedToday => total > 0 && remaining == 0;

  @override
  List<Object?> get props => [exercises, protocolNames];
}

/// Merges every active protocol due today into one ordered session.
/// Order: assignment createdAt, then item order (knee protocol first, then
/// back — spec §4.6). Outcomes are looked up by deterministic completion ID
/// for today's local date only — yesterday's outcomes never carry over
/// (spec §5.3 daily reset).
TodaySession buildTodaySession({
  required List<Assignment> assignments,
  required List<Completion> completions,
  required DateTime now,
}) {
  final today = Dates.ymd(now);
  final weekday = now.weekday;

  final due = assignments
      .where((a) => a.active && a.type == AssignmentType.protocol && a.daysOfWeek.contains(weekday))
      .toList()
    ..sort((a, b) {
      final byDate = a.createdAt.compareTo(b.createdAt);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });

  final outcomeById = <String, CompletionStatus>{
    for (final c in completions.where((c) => c.date == today)) c.id: c.status,
  };

  final exercises = <SessionExercise>[];
  for (final a in due) {
    final items = List.of(a.items)..sort((x, y) => x.order.compareTo(y.order));
    for (final item in items) {
      exercises.add(SessionExercise(
        assignment: a,
        item: item,
        outcome: outcomeById[Completion.idFor(today, a.id, item.videoId)],
      ));
    }
  }

  return TodaySession(
    exercises: exercises,
    protocolNames: due.map((a) => a.name).toList(),
  );
}
