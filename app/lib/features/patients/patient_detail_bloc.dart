import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/core/adherence.dart';
import 'package:physio_app/core/dates.dart';
import 'package:physio_app/core/streams.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';

/// A protocol assignment paired with its computed progress (spec §6.2) and
/// its own seven-dot strip (spec §6.1, scoped to just this assignment).
class AssignmentProgress extends Equatable {
  final Assignment assignment;
  final double? adherence;
  final int doneCount;
  final int skippedCount;
  final List<DayMark> strip;

  const AssignmentProgress({
    required this.assignment,
    required this.adherence,
    required this.doneCount,
    required this.skippedCount,
    required this.strip,
  });

  @override
  List<Object?> get props => [assignment, adherence, doneCount, skippedCount, strip];
}

class PatientDetailState extends Equatable {
  final bool loading;
  final Patient? patient;
  final List<AssignmentProgress> protocols;
  final List<Assignment> singles;

  /// videoIds whose library entry is visibility == 'private'. Used to mark
  /// "Also assigned" rows — [ExerciseItem] doesn't carry visibility, it's
  /// denormalized from [VideoItem] at assign time (spec §4.7).
  final Set<String> privateVideoIds;

  /// Whole days since [Patient.lastActiveAt], computed against the bloc's
  /// `now` (never `DateTime.now()` — keeps the header deterministic in
  /// tests). Null when nothing recorded yet.
  final int? daysSinceLastActive;
  final String notes;

  /// Set after a successful [RegenerateInvitePressed]; the page snackbars it.
  final String? lastGeneratedCode;

  const PatientDetailState({
    required this.loading,
    required this.patient,
    required this.protocols,
    required this.singles,
    required this.privateVideoIds,
    required this.daysSinceLastActive,
    required this.notes,
    required this.lastGeneratedCode,
  });

  const PatientDetailState.initial()
      : loading = true,
        patient = null,
        protocols = const [],
        singles = const [],
        privateVideoIds = const {},
        daysSinceLastActive = null,
        notes = '',
        lastGeneratedCode = null;

  PatientDetailState copyWith({String? notes, String? lastGeneratedCode}) => PatientDetailState(
        loading: loading,
        patient: patient,
        protocols: protocols,
        singles: singles,
        privateVideoIds: privateVideoIds,
        daysSinceLastActive: daysSinceLastActive,
        notes: notes ?? this.notes,
        lastGeneratedCode: lastGeneratedCode ?? this.lastGeneratedCode,
      );

  @override
  List<Object?> get props => [
        loading,
        patient,
        protocols,
        singles,
        privateVideoIds,
        daysSinceLastActive,
        notes,
        lastGeneratedCode
      ];
}

sealed class PatientDetailEvent extends Equatable {
  const PatientDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Debounced 500ms before it reaches [PatientsRepository.updateNotes].
class NotesChanged extends PatientDetailEvent {
  final String text;
  const NotesChanged(this.text);

  @override
  List<Object?> get props => [text];
}

class RegenerateInvitePressed extends PatientDetailEvent {
  const RegenerateInvitePressed();
}

class _DataUpdated extends PatientDetailEvent {
  final Patient? patient;
  final List<Assignment> assignments;
  final List<Completion> completions;
  final List<VideoItem> videos;
  const _DataUpdated(this.patient, this.assignments, this.completions, this.videos);

  @override
  List<Object?> get props => [patient, assignments, completions, videos];
}

/// Debounces an event stream: only the last event in a burst survives, and
/// only after [duration] of silence. Hand-rolled — no rxdart dependency.
EventTransformer<E> _debounce<E>(Duration duration) {
  return (events, mapper) {
    final controller = StreamController<E>();
    Timer? timer;
    final sub = events.listen(
      (event) {
        timer?.cancel();
        timer = Timer(duration, () => controller.add(event));
      },
      onError: controller.addError,
      onDone: () {
        timer?.cancel();
        controller.close();
      },
    );
    controller.onCancel = () {
      timer?.cancel();
      sub.cancel();
    };
    return controller.stream.asyncExpand(mapper);
  };
}

class PatientDetailBloc extends Bloc<PatientDetailEvent, PatientDetailState> {
  final String patientId;
  final PatientsRepository patientsRepository;
  final AssignmentsRepository assignmentsRepository;
  final CompletionsRepository completionsRepository;
  final LibraryRepository libraryRepository;
  final NowFn now;

  StreamSubscription<PatientDetailEvent>? _sub;

  PatientDetailBloc({
    required this.patientId,
    required this.patientsRepository,
    required this.assignmentsRepository,
    required this.completionsRepository,
    required this.libraryRepository,
    this.now = DateTime.now,
  }) : super(const PatientDetailState.initial()) {
    on<_DataUpdated>(_onDataUpdated);
    on<NotesChanged>(_onNotesChanged, transformer: _debounce(const Duration(milliseconds: 500)));
    on<RegenerateInvitePressed>(_onRegenerate);

    _sub = combineLatest4(
      patientsRepository.watchPatient(patientId),
      assignmentsRepository.watchForPatient(patientId),
      completionsRepository.watchForPatient(patientId),
      libraryRepository.watchVideos(),
      (Patient? patient, List<Assignment> assignments, List<Completion> completions,
              List<VideoItem> videos) =>
          _DataUpdated(patient, assignments, completions, videos),
    ).listen(add);
  }

  void _onDataUpdated(_DataUpdated event, Emitter<PatientDetailState> emit) {
    final completions = event.completions;
    final protocols = event.assignments
        .where((a) => a.active && a.type == AssignmentType.protocol)
        .map((a) => AssignmentProgress(
              assignment: a,
              adherence: adherencePercent(assignment: a, completions: completions, now: now()),
              doneCount: completions
                  .where((c) => c.assignmentId == a.id && c.status == CompletionStatus.done)
                  .length,
              skippedCount: completions
                  .where((c) => c.assignmentId == a.id && c.status == CompletionStatus.skipped)
                  .length,
              strip: weekStrip(assignments: [a], completions: completions, now: now()),
            ))
        .toList()
      ..sort((a, b) => a.assignment.createdAt.compareTo(b.assignment.createdAt));

    final singles =
        event.assignments.where((a) => a.active && a.type == AssignmentType.single).toList();

    final privateVideoIds = {
      for (final v in event.videos)
        if (v.isPrivate) v.id,
    };

    final lastActive = event.patient?.lastActiveAt;
    final sinceActive =
        lastActive == null ? null : Dates.dateOnly(now()).difference(Dates.dateOnly(lastActive)).inDays;

    emit(PatientDetailState(
      loading: false,
      patient: event.patient,
      protocols: protocols,
      singles: singles,
      privateVideoIds: privateVideoIds,
      daysSinceLastActive: sinceActive,
      notes: event.patient?.notes ?? state.notes,
      lastGeneratedCode: state.lastGeneratedCode,
    ));
  }

  Future<void> _onNotesChanged(NotesChanged event, Emitter<PatientDetailState> emit) async {
    await patientsRepository.updateNotes(patientId, event.text);
    emit(state.copyWith(notes: event.text));
  }

  Future<void> _onRegenerate(
      RegenerateInvitePressed event, Emitter<PatientDetailState> emit) async {
    final result = await patientsRepository.regenerateInvite(patientId);
    result.when(
      ok: (code) => emit(state.copyWith(lastGeneratedCode: code)),
      err: (_) {},
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
