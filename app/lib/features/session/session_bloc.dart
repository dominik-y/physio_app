import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/core/dates.dart';
import 'package:physio_app/core/session_engine.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';

sealed class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

class SessionStarted extends SessionEvent {
  const SessionStarted();
}

class DonePressed extends SessionEvent {
  const DonePressed();
}

class SkipPressed extends SessionEvent {
  const SkipPressed();
}

sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

class SessionLoading extends SessionState {
  const SessionLoading();
}

class SessionEmpty extends SessionState {
  const SessionEmpty();
}

class SessionInProgress extends SessionState {
  final List<SessionExercise> exercises;
  final int currentIndex;
  final int doneSoFar;
  final int skippedSoFar;

  const SessionInProgress({
    required this.exercises,
    required this.currentIndex,
    required this.doneSoFar,
    required this.skippedSoFar,
  });

  SessionExercise get current => exercises[currentIndex];
  int get total => exercises.length;

  @override
  List<Object?> get props => [exercises, currentIndex, doneSoFar, skippedSoFar];
}

class SessionComplete extends SessionState {
  final int doneCount;
  final int skippedCount;

  const SessionComplete({required this.doneCount, required this.skippedCount});

  @override
  List<Object?> get props => [doneCount, skippedCount];
}

/// Drives the guided session player (spec §5.2, §5.3). Works off a fixed
/// snapshot of assignments+completions taken at start — recording an outcome
/// never re-shuffles the running flow. Resume semantics: the next unrecorded
/// exercise after the current one, wrapping to pick up any earlier gaps.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final String patientId;
  final AssignmentsRepository assignmentsRepository;
  final CompletionsRepository completionsRepository;
  final NowFn now;

  List<SessionExercise> _exercises = const [];
  bool _recording = false;

  SessionBloc({
    this.patientId = DemoData.currentPatientId,
    required this.assignmentsRepository,
    required this.completionsRepository,
    this.now = DateTime.now,
  }) : super(const SessionLoading()) {
    on<SessionStarted>(_onStarted);
    on<DonePressed>((event, emit) => _record(CompletionStatus.done, emit));
    on<SkipPressed>((event, emit) => _record(CompletionStatus.skipped, emit));
  }

  Future<void> _onStarted(SessionStarted event, Emitter<SessionState> emit) async {
    final assignments = await assignmentsRepository.watchForPatient(patientId).first;
    final completions = await completionsRepository.watchForPatient(patientId).first;
    final session = buildTodaySession(assignments: assignments, completions: completions, now: now());
    _exercises = session.exercises;

    if (_exercises.isEmpty) {
      emit(const SessionEmpty());
      return;
    }

    // Amendment 5: clears the hero "New" badge for every protocol
    // contributing to today's session, not just the first one touched.
    final markedAssignmentIds = <String>{};
    for (final exercise in _exercises) {
      if (markedAssignmentIds.add(exercise.assignment.id)) {
        await assignmentsRepository.markSeen(exercise.assignment.id);
      }
    }

    final firstUnrecorded = session.firstUnrecordedIndex;
    if (firstUnrecorded == -1) {
      emit(SessionComplete(doneCount: session.doneCount, skippedCount: session.skippedCount));
      return;
    }
    emit(SessionInProgress(
      exercises: _exercises,
      currentIndex: firstUnrecorded,
      doneSoFar: session.doneCount,
      skippedSoFar: session.skippedCount,
    ));
  }

  Future<void> _record(CompletionStatus status, Emitter<SessionState> emit) async {
    final current = state;
    if (current is! SessionInProgress || _recording) return;
    _recording = true;

    final exercise = _exercises[current.currentIndex];
    final date = Dates.ymd(now());
    final completion = Completion.forDay(
      date: date,
      assignmentId: exercise.assignment.id,
      videoId: exercise.item.videoId,
      status: status,
      at: now(),
    );
    await completionsRepository.record(patientId, completion);

    _exercises = [
      for (var i = 0; i < _exercises.length; i++)
        i == current.currentIndex
            ? SessionExercise(assignment: exercise.assignment, item: exercise.item, outcome: status)
            : _exercises[i],
    ];

    final doneSoFar = _exercises.where((e) => e.outcome == CompletionStatus.done).length;
    final skippedSoFar = _exercises.where((e) => e.outcome == CompletionStatus.skipped).length;
    final next = _nextUnrecordedIndex(after: current.currentIndex);

    if (next == -1) {
      emit(SessionComplete(doneCount: doneSoFar, skippedCount: skippedSoFar));
    } else {
      emit(SessionInProgress(
        exercises: _exercises,
        currentIndex: next,
        doneSoFar: doneSoFar,
        skippedSoFar: skippedSoFar,
      ));
    }
    _recording = false;
  }

  /// Next index strictly after [after] with no outcome, wrapping around to
  /// pick up any earlier gap (spec §5.3 resume semantics). -1 when none remain.
  int _nextUnrecordedIndex({required int after}) {
    final n = _exercises.length;
    for (var offset = 1; offset <= n; offset++) {
      final idx = (after + offset) % n;
      if (_exercises[idx].outcome == null) return idx;
    }
    return -1;
  }
}
