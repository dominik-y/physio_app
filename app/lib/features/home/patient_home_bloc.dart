import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/core/adherence.dart';
import 'package:physio_app/core/dates.dart';
import 'package:physio_app/core/session_engine.dart';
import 'package:physio_app/core/streams.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/design_system/hero_card.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';

/// A single-video "Also assigned" row (spec §5.1) — not part of the guided
/// session (§4.6 critique amendment 3).
class SingleAssignmentRow extends Equatable {
  final String assignmentId;
  final String videoId;
  final String title;
  final String bodyPart;
  final int durationSec;
  final bool seen;

  const SingleAssignmentRow({
    required this.assignmentId,
    required this.videoId,
    required this.title,
    required this.bodyPart,
    required this.durationSec,
    required this.seen,
  });

  @override
  List<Object?> get props => [assignmentId, videoId, title, bodyPart, durationSec, seen];
}

/// Remaining today's-session exercises for one body part (spec §5.1 — shown
/// only when more than one distinct body part is due today).
class BodyPartSection extends Equatable {
  final String bodyPart;
  final List<ExerciseItem> items;

  const BodyPartSection({required this.bodyPart, required this.items});

  @override
  List<Object?> get props => [bodyPart, items];
}

class PatientHomeState extends Equatable {
  final String patientName;
  final HeroState heroState;
  final int totalExercises;
  final int remaining;
  final List<String> protocolNames;
  final List<DayMark> weekMarks;
  final bool showNew;
  final List<SingleAssignmentRow> singles;
  final List<BodyPartSection> bodyPartSections;

  /// True once the patient has at least one active assignment of any kind
  /// (protocol or single) — governs the whole-page empty state.
  final bool hasAnyAssignment;

  const PatientHomeState({
    required this.patientName,
    required this.heroState,
    required this.totalExercises,
    required this.remaining,
    required this.protocolNames,
    required this.weekMarks,
    required this.showNew,
    required this.singles,
    required this.bodyPartSections,
    required this.hasAnyAssignment,
  });

  factory PatientHomeState.initial() => const PatientHomeState(
        patientName: '',
        heroState: HeroState.empty,
        totalExercises: 0,
        remaining: 0,
        protocolNames: [],
        weekMarks: [],
        showNew: false,
        singles: [],
        bodyPartSections: [],
        hasAnyAssignment: false,
      );

  @override
  List<Object?> get props => [
        patientName,
        heroState,
        totalExercises,
        remaining,
        protocolNames,
        weekMarks,
        showNew,
        singles,
        bodyPartSections,
        hasAnyAssignment,
      ];
}

sealed class PatientHomeEvent extends Equatable {
  const PatientHomeEvent();
  @override
  List<Object?> get props => [];
}

/// Fired when the patient taps a single video — clears its New badge
/// (spec §5.4; protocols clear on session init instead, see SessionBloc).
class AssignmentOpened extends PatientHomeEvent {
  final String assignmentId;
  const AssignmentOpened(this.assignmentId);
  @override
  List<Object?> get props => [assignmentId];
}

/// Internal: routes a recombined repository snapshot through `add` rather
/// than calling the visible-for-testing `emit` directly from a stream
/// listener (flutter_bloc idiom for bridging external streams into a bloc).
class _StoreUpdated extends PatientHomeEvent {
  final PatientHomeState state;
  const _StoreUpdated(this.state);
  @override
  List<Object?> get props => [state];
}

class PatientHomeBloc extends Bloc<PatientHomeEvent, PatientHomeState> {
  final String patientId;
  final AssignmentsRepository assignmentsRepository;
  final CompletionsRepository completionsRepository;
  final PatientsRepository patientsRepository;
  final NowFn now;

  StreamSubscription<PatientHomeState>? _sub;

  PatientHomeBloc({
    this.patientId = DemoData.currentPatientId,
    required this.assignmentsRepository,
    required this.completionsRepository,
    required this.patientsRepository,
    this.now = DateTime.now,
  }) : super(PatientHomeState.initial()) {
    on<AssignmentOpened>(_onAssignmentOpened);
    on<_StoreUpdated>((event, emit) => emit(event.state));
    _sub = combineLatest3(
      assignmentsRepository.watchForPatient(patientId),
      completionsRepository.watchForPatient(patientId),
      patientsRepository.watchPatient(patientId),
      _combine,
    ).listen((next) => add(_StoreUpdated(next)));
  }

  PatientHomeState _combine(
    List<Assignment> assignments,
    List<Completion> completions,
    Patient? patient,
  ) {
    final activeAssignments = assignments.where((a) => a.active).toList();
    final session = buildTodaySession(assignments: assignments, completions: completions, now: now());
    final total = session.total;
    final remaining = session.remaining;

    final heroState = total == 0
        ? HeroState.empty
        : remaining == 0
            ? HeroState.done
            : remaining < total
                ? HeroState.resume
                : HeroState.start;

    final contributingIds = session.exercises.map((e) => e.assignment.id).toSet();
    final showNew = activeAssignments.any((a) => contributingIds.contains(a.id) && !a.seenByPatient);

    final marks = weekStrip(assignments: assignments, completions: completions, now: now());

    final singles = activeAssignments
        .where((a) => a.type == AssignmentType.single)
        .map((a) {
          final it = a.items.first;
          return SingleAssignmentRow(
            assignmentId: a.id,
            videoId: it.videoId,
            title: it.title,
            bodyPart: it.bodyPart,
            durationSec: it.durationSec,
            seen: a.seenByPatient,
          );
        })
        .toList();

    // Remaining protocol exercises, grouped by body part, in merge order.
    final grouped = <String, List<ExerciseItem>>{};
    final bodyPartOrder = <String>[];
    for (final e in session.exercises) {
      if (e.outcome != null) continue;
      final bp = e.item.bodyPart;
      if (!grouped.containsKey(bp)) {
        grouped[bp] = [];
        bodyPartOrder.add(bp);
      }
      grouped[bp]!.add(e.item);
    }
    final sections = bodyPartOrder.length > 1
        ? [for (final bp in bodyPartOrder) BodyPartSection(bodyPart: bp, items: grouped[bp]!)]
        : const <BodyPartSection>[];

    return PatientHomeState(
      patientName: patient?.name ?? '',
      heroState: heroState,
      totalExercises: total,
      remaining: remaining,
      protocolNames: session.protocolNames,
      weekMarks: marks,
      showNew: showNew,
      singles: singles,
      bodyPartSections: sections,
      hasAnyAssignment: activeAssignments.isNotEmpty,
    );
  }

  Future<void> _onAssignmentOpened(AssignmentOpened event, Emitter<PatientHomeState> emit) async {
    await assignmentsRepository.markSeen(event.assignmentId);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
