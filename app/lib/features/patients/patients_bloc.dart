import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/core/adherence.dart';
import 'package:physio_app/core/dates.dart';
import 'package:physio_app/core/streams.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';

/// One row on the physio's patients list: the patient plus everything
/// derived from their own assignments + completions (spec §6.1).
class PatientRow extends Equatable {
  final Patient patient;
  final List<DayMark> strip;

  /// Best (max) adherence across the patient's active protocols. Null when
  /// nothing has an elapsed occurrence yet, or the patient hasn't redeemed.
  final double? bestAdherence;

  /// Whole days since any outcome was recorded. Null when not redeemed or
  /// nothing assigned.
  final int? daysSilent;
  final bool invited;

  /// Whole days since [Patient.lastActiveAt], computed against the bloc's
  /// `now` (never `DateTime.now()` — keeps the label deterministic in
  /// tests). Null when redeemed but nothing recorded yet.
  final int? daysSinceLastActive;

  const PatientRow({
    required this.patient,
    required this.strip,
    required this.bestAdherence,
    required this.daysSilent,
    required this.invited,
    required this.daysSinceLastActive,
  });

  bool get isSilent => daysSilent != null && daysSilent! >= 7;

  @override
  List<Object?> get props =>
      [patient, strip, bestAdherence, daysSilent, invited, daysSinceLastActive];
}

class PatientsState extends Equatable {
  final bool loading;
  final List<PatientRow> rows;

  const PatientsState({required this.loading, required this.rows});

  const PatientsState.initial()
      : loading = true,
        rows = const [];

  @override
  List<Object?> get props => [loading, rows];
}

sealed class PatientsEvent extends Equatable {
  const PatientsEvent();

  @override
  List<Object?> get props => [];
}

class _RowsUpdated extends PatientsEvent {
  final List<PatientRow> rows;
  const _RowsUpdated(this.rows);

  @override
  List<Object?> get props => [rows];
}

/// Merges patients + all assignments + all completions into sorted rows
/// (spec §6.1): silent patients first, then everyone else by name, invited
/// patients last.
class PatientsBloc extends Bloc<PatientsEvent, PatientsState> {
  final PatientsRepository patientsRepository;
  final AssignmentsRepository assignmentsRepository;
  final CompletionsRepository completionsRepository;
  final NowFn now;

  StreamSubscription<List<PatientRow>>? _sub;

  PatientsBloc({
    required this.patientsRepository,
    required this.assignmentsRepository,
    required this.completionsRepository,
    this.now = DateTime.now,
  }) : super(const PatientsState.initial()) {
    on<_RowsUpdated>((event, emit) => emit(PatientsState(loading: false, rows: event.rows)));

    _sub = combineLatest3(
      patientsRepository.watchPatients(),
      assignmentsRepository.watchAll(),
      completionsRepository.watchAllByPatient(),
      _buildRows,
    ).listen((rows) => add(_RowsUpdated(rows)));
  }

  List<PatientRow> _buildRows(
    List<Patient> patients,
    List<Assignment> allAssignments,
    Map<String, List<Completion>> completionsByPatient,
  ) {
    final rows = patients.map((patient) {
      final assignments = allAssignments.where((a) => a.patientId == patient.id).toList();
      final completions = completionsByPatient[patient.id] ?? const <Completion>[];
      final invited = !patient.redeemed;

      if (invited) {
        return PatientRow(
          patient: patient,
          strip: const [],
          bestAdherence: null,
          daysSilent: null,
          invited: true,
          daysSinceLastActive: null,
        );
      }

      final strip = weekStrip(assignments: assignments, completions: completions, now: now());
      final silent = daysSilent(assignments: assignments, completions: completions, now: now());

      double? best;
      for (final a in assignments.where((a) => a.active && a.type == AssignmentType.protocol)) {
        final pct = adherencePercent(assignment: a, completions: completions, now: now());
        if (pct != null && (best == null || pct > best)) best = pct;
      }

      final lastActive = patient.lastActiveAt;
      final sinceActive =
          lastActive == null ? null : Dates.dateOnly(now()).difference(Dates.dateOnly(lastActive)).inDays;

      return PatientRow(
        patient: patient,
        strip: strip,
        bestAdherence: best,
        daysSilent: silent,
        invited: false,
        daysSinceLastActive: sinceActive,
      );
    }).toList();

    int group(PatientRow r) {
      if (r.isSilent) return 0;
      if (r.invited) return 2;
      return 1;
    }

    rows.sort((a, b) {
      final g = group(a).compareTo(group(b));
      if (g != 0) return g;
      return a.patient.name.compareTo(b.patient.name);
    });
    return rows;
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
