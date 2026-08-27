import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/core/dates.dart';
import 'package:physio_app/core/result.dart';
import 'package:physio_app/core/streams.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';

enum AssignFlowStep { fork, picker, dosage }

enum AssignSubmitStatus { idle, submitting, success, failure }

/// The fork → picker → dosage flow, single bloc state (spec §4.5, §4.4, §4.6).
class AssignFlowState extends Equatable {
  final AssignFlowStep step;
  final AssignmentType type;

  /// Non-null only for the from-template path — provenance for the "back to
  /// fork" shortcut, never mutated (snapshot semantics, spec §4.4).
  final ProtocolTemplate? sourceTemplate;
  final String name;
  final Set<int> daysOfWeek;
  final List<ExerciseItem> items;

  /// By videoId — used to compute the `overridden` flag (spec §6.3). Empty
  /// for the custom-build path, so nothing there is ever "overridden".
  final Map<String, TemplateItem> templateDefaults;

  /// Picker working selection, in tap order (order = selection order).
  final List<String> selectedVideoIds;
  final bool saveAsTemplate;
  final AssignSubmitStatus submitStatus;

  /// The §4.6 two-tap guard: true once the first SubmitPressed has shown the
  /// total-exercise warning.
  final bool confirmArmed;

  /// Flat sum of items.length over the patient's other active protocols.
  final int existingDailyTotal;
  final String patientName;
  final List<ProtocolTemplate> templates;

  /// Library videos visible to this flow: public + private-to-this-patient.
  final List<VideoItem> videos;
  final bool dataLoaded;
  final String? failureMessage;

  const AssignFlowState({
    required this.step,
    required this.type,
    required this.sourceTemplate,
    required this.name,
    required this.daysOfWeek,
    required this.items,
    required this.templateDefaults,
    required this.selectedVideoIds,
    required this.saveAsTemplate,
    required this.submitStatus,
    required this.confirmArmed,
    required this.existingDailyTotal,
    required this.patientName,
    required this.templates,
    required this.videos,
    required this.dataLoaded,
    required this.failureMessage,
  });

  factory AssignFlowState.initial() => const AssignFlowState(
        step: AssignFlowStep.fork,
        type: AssignmentType.protocol,
        sourceTemplate: null,
        name: '',
        daysOfWeek: {1, 2, 3, 4, 5, 6, 7},
        items: [],
        templateDefaults: {},
        selectedVideoIds: [],
        saveAsTemplate: false,
        submitStatus: AssignSubmitStatus.idle,
        confirmArmed: false,
        existingDailyTotal: 0,
        patientName: '',
        templates: [],
        videos: [],
        dataLoaded: false,
        failureMessage: null,
      );

  static const _unset = Object();

  AssignFlowState copyWith({
    AssignFlowStep? step,
    AssignmentType? type,
    Object? sourceTemplate = _unset,
    String? name,
    Set<int>? daysOfWeek,
    List<ExerciseItem>? items,
    Map<String, TemplateItem>? templateDefaults,
    List<String>? selectedVideoIds,
    bool? saveAsTemplate,
    AssignSubmitStatus? submitStatus,
    bool? confirmArmed,
    int? existingDailyTotal,
    String? patientName,
    List<ProtocolTemplate>? templates,
    List<VideoItem>? videos,
    bool? dataLoaded,
    Object? failureMessage = _unset,
  }) =>
      AssignFlowState(
        step: step ?? this.step,
        type: type ?? this.type,
        sourceTemplate:
            identical(sourceTemplate, _unset) ? this.sourceTemplate : sourceTemplate as ProtocolTemplate?,
        name: name ?? this.name,
        daysOfWeek: daysOfWeek ?? this.daysOfWeek,
        items: items ?? this.items,
        templateDefaults: templateDefaults ?? this.templateDefaults,
        selectedVideoIds: selectedVideoIds ?? this.selectedVideoIds,
        saveAsTemplate: saveAsTemplate ?? this.saveAsTemplate,
        submitStatus: submitStatus ?? this.submitStatus,
        confirmArmed: confirmArmed ?? this.confirmArmed,
        existingDailyTotal: existingDailyTotal ?? this.existingDailyTotal,
        patientName: patientName ?? this.patientName,
        templates: templates ?? this.templates,
        videos: videos ?? this.videos,
        dataLoaded: dataLoaded ?? this.dataLoaded,
        failureMessage: identical(failureMessage, _unset) ? this.failureMessage : failureMessage as String?,
      );

  @override
  List<Object?> get props => [
        step,
        type,
        sourceTemplate,
        name,
        daysOfWeek,
        items,
        templateDefaults,
        selectedVideoIds,
        saveAsTemplate,
        submitStatus,
        confirmArmed,
        existingDailyTotal,
        patientName,
        templates,
        videos,
        dataLoaded,
        failureMessage,
      ];
}

sealed class AssignFlowEvent extends Equatable {
  const AssignFlowEvent();
  @override
  List<Object?> get props => [];
}

class StartedFromTemplate extends AssignFlowEvent {
  final ProtocolTemplate template;
  const StartedFromTemplate(this.template);
  @override
  List<Object?> get props => [template];
}

class StartedCustom extends AssignFlowEvent {
  const StartedCustom();
}

class StartedSingle extends AssignFlowEvent {
  const StartedSingle();
}

class PickerSelectionToggled extends AssignFlowEvent {
  final String videoId;
  const PickerSelectionToggled(this.videoId);
  @override
  List<Object?> get props => [videoId];
}

class PickerConfirmed extends AssignFlowEvent {
  const PickerConfirmed();
}

class DosageChanged extends AssignFlowEvent {
  final String videoId;
  final int? sets;
  final int? reps;
  final int? holdSec;
  const DosageChanged(this.videoId, {this.sets, this.reps, this.holdSec});
  @override
  List<Object?> get props => [videoId, sets, reps, holdSec];
}

class ItemsReordered extends AssignFlowEvent {
  final int oldIndex;
  final int newIndex;
  const ItemsReordered(this.oldIndex, this.newIndex);
  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class ItemRemoved extends AssignFlowEvent {
  final String videoId;
  const ItemRemoved(this.videoId);
  @override
  List<Object?> get props => [videoId];
}

class DaysToggled extends AssignFlowEvent {
  final int day;
  const DaysToggled(this.day);
  @override
  List<Object?> get props => [day];
}

class NameChanged extends AssignFlowEvent {
  final String name;
  const NameChanged(this.name);
  @override
  List<Object?> get props => [name];
}

class SaveAsTemplateToggled extends AssignFlowEvent {
  const SaveAsTemplateToggled();
}

class BackPressed extends AssignFlowEvent {
  const BackPressed();
}

class SubmitPressed extends AssignFlowEvent {
  const SubmitPressed();
}

class _DataUpdated extends AssignFlowEvent {
  final List<ProtocolTemplate> templates;
  final List<VideoItem> videos;
  final String patientName;
  final int existingDailyTotal;
  const _DataUpdated(this.templates, this.videos, this.patientName, this.existingDailyTotal);
}

class AssignFlowBloc extends Bloc<AssignFlowEvent, AssignFlowState> {
  final String patientId;
  final AssignmentsRepository assignmentsRepository;
  final TemplatesRepository templatesRepository;
  final LibraryRepository libraryRepository;
  final PatientsRepository patientsRepository;
  final NowFn now;
  final IdFn idFn;
  late final StreamSubscription<_DataUpdated> _sub;

  AssignFlowBloc(
    this.patientId,
    this.assignmentsRepository,
    this.templatesRepository,
    this.libraryRepository,
    this.patientsRepository, {
    this.now = DateTime.now,
    IdFn? idFn,
  })  : idFn = idFn ?? (() => 'as-${DateTime.now().microsecondsSinceEpoch}'),
        super(AssignFlowState.initial()) {
    on<_DataUpdated>(_onDataUpdated);
    on<StartedFromTemplate>(_onStartedFromTemplate);
    on<StartedCustom>(_onStartedCustom);
    on<StartedSingle>(_onStartedSingle);
    on<PickerSelectionToggled>(_onPickerSelectionToggled);
    on<PickerConfirmed>(_onPickerConfirmed);
    on<DosageChanged>(_onDosageChanged);
    on<ItemsReordered>(_onItemsReordered);
    on<ItemRemoved>(_onItemRemoved);
    on<DaysToggled>(_onDaysToggled);
    on<NameChanged>((event, emit) => emit(state.copyWith(name: event.name)));
    on<SaveAsTemplateToggled>((event, emit) => emit(state.copyWith(saveAsTemplate: !state.saveAsTemplate)));
    on<BackPressed>(_onBackPressed);
    on<SubmitPressed>(_onSubmitPressed);

    _sub = combineLatest4(
      templatesRepository.watchTemplates(),
      libraryRepository.watchVideos(),
      patientsRepository.watchPatient(patientId),
      assignmentsRepository.watchForPatient(patientId),
      (List<ProtocolTemplate> templates, List<VideoItem> videos, Patient? patient, List<Assignment> assignments) {
        // isReady: a non-ready video has no mediaUrl yet — offering it would
        // snapshot a null URL into the assignment forever (plan §3.7). Demo
        // videos are always 'ready'.
        final visible = videos
            .where((v) =>
                (v.visibility == 'library' || v.privateToPatientId == patientId) &&
                v.isReady)
            .toList();
        final total = assignments
            .where((a) => a.active && a.type == AssignmentType.protocol)
            .fold<int>(0, (sum, a) => sum + a.items.length);
        return _DataUpdated(templates, visible, patient?.name ?? '', total);
      },
    ).listen(add);
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }

  void _onDataUpdated(_DataUpdated event, Emitter<AssignFlowState> emit) {
    emit(state.copyWith(
      templates: event.templates,
      videos: event.videos,
      patientName: event.patientName,
      existingDailyTotal: event.existingDailyTotal,
      dataLoaded: true,
    ));
  }

  VideoItem? _findVideo(String videoId) {
    for (final v in state.videos) {
      if (v.id == videoId) return v;
    }
    return null;
  }

  ExerciseItem _buildItem(VideoItem video, {required int order, int sets = 3, int reps = 10, int holdSec = 0}) =>
      ExerciseItem(
        videoId: video.id,
        order: order,
        sets: sets,
        reps: reps,
        holdSec: holdSec,
        overridden: false,
        title: video.title,
        durationSec: video.durationSec,
        bodyPart: video.bodyPart,
        // Patients never read `videos` — the snapshot is their only URL.
        mediaUrl: video.mediaUrl,
        posterUrl: video.posterUrl,
      );

  void _onStartedFromTemplate(StartedFromTemplate event, Emitter<AssignFlowState> emit) {
    final template = event.template;
    // SNAPSHOT (spec §4.4): a brand-new ExerciseItem list, never a reference
    // back into `template.items` — later edits must never touch the template.
    final items = <ExerciseItem>[];
    final defaults = <String, TemplateItem>{};
    for (final templateItem in template.items) {
      final video = _findVideo(templateItem.videoId);
      items.add(ExerciseItem(
        videoId: templateItem.videoId,
        order: templateItem.order,
        sets: templateItem.sets,
        reps: templateItem.reps,
        holdSec: templateItem.holdSec,
        overridden: false,
        title: video?.title ?? templateItem.videoId,
        durationSec: video?.durationSec ?? 0,
        bodyPart: video?.bodyPart ?? '',
        mediaUrl: video?.mediaUrl,
        posterUrl: video?.posterUrl,
      ));
      defaults[templateItem.videoId] = templateItem;
    }
    emit(state.copyWith(
      type: AssignmentType.protocol,
      sourceTemplate: template,
      name: template.name,
      items: items,
      templateDefaults: defaults,
      daysOfWeek: const {1, 2, 3, 4, 5, 6, 7},
      selectedVideoIds: const [],
      step: AssignFlowStep.dosage,
      confirmArmed: false,
      submitStatus: AssignSubmitStatus.idle,
    ));
  }

  void _onStartedCustom(StartedCustom event, Emitter<AssignFlowState> emit) {
    emit(state.copyWith(
      type: AssignmentType.protocol,
      sourceTemplate: null,
      name: '',
      items: const [],
      templateDefaults: const {},
      daysOfWeek: const {1, 2, 3, 4, 5, 6, 7},
      selectedVideoIds: const [],
      step: AssignFlowStep.picker,
      confirmArmed: false,
      submitStatus: AssignSubmitStatus.idle,
    ));
  }

  void _onStartedSingle(StartedSingle event, Emitter<AssignFlowState> emit) {
    emit(state.copyWith(
      type: AssignmentType.single,
      sourceTemplate: null,
      name: '',
      items: const [],
      templateDefaults: const {},
      daysOfWeek: const {1, 2, 3, 4, 5, 6, 7},
      selectedVideoIds: const [],
      step: AssignFlowStep.picker,
      confirmArmed: false,
      submitStatus: AssignSubmitStatus.idle,
    ));
  }

  void _onPickerSelectionToggled(PickerSelectionToggled event, Emitter<AssignFlowState> emit) {
    // Amendment 6: a video already in the working set can't be re-added.
    if (state.items.any((i) => i.videoId == event.videoId)) return;
    final selected = List<String>.of(state.selectedVideoIds);
    if (selected.contains(event.videoId)) {
      selected.remove(event.videoId);
    } else {
      if (state.type == AssignmentType.single) selected.clear();
      selected.add(event.videoId);
    }
    emit(state.copyWith(selectedVideoIds: selected));
  }

  Future<void> _onPickerConfirmed(PickerConfirmed event, Emitter<AssignFlowState> emit) async {
    if (state.type == AssignmentType.single) {
      // Amendment 8: single video submits directly, no dosage ceremony.
      if (state.selectedVideoIds.length != 1) return;
      final video = _findVideo(state.selectedVideoIds.first);
      if (video == null) return;
      final item = _buildItem(video, order: 0, sets: 1, reps: 1, holdSec: 0);
      final assignment = Assignment(
        id: idFn(),
        patientId: patientId,
        type: AssignmentType.single,
        name: video.title,
        bodyParts: [video.bodyPart],
        daysOfWeek: const {1, 2, 3, 4, 5, 6, 7},
        items: [item],
        createdAt: now(),
      );
      emit(state.copyWith(name: video.title, items: [item], selectedVideoIds: const []));
      await _submit(emit, assignment);
      return;
    }
    final base = state.items.length;
    final newItems = <ExerciseItem>[];
    for (var i = 0; i < state.selectedVideoIds.length; i++) {
      final video = _findVideo(state.selectedVideoIds[i]);
      if (video == null) continue;
      newItems.add(_buildItem(video, order: base + i));
    }
    emit(state.copyWith(
      items: [...state.items, ...newItems],
      selectedVideoIds: const [],
      step: AssignFlowStep.dosage,
    ));
  }

  void _onDosageChanged(DosageChanged event, Emitter<AssignFlowState> emit) {
    final items = state.items.map((item) {
      if (item.videoId != event.videoId) return item;
      final sets = event.sets ?? item.sets;
      final reps = event.reps ?? item.reps;
      final holdSec = event.holdSec ?? item.holdSec;
      final defaultItem = state.templateDefaults[event.videoId];
      // Custom-built items have no template default -> never "overridden".
      final overridden = defaultItem == null
          ? false
          : !(sets == defaultItem.sets && reps == defaultItem.reps && holdSec == defaultItem.holdSec);
      return item.copyWith(sets: sets, reps: reps, holdSec: holdSec, overridden: overridden);
    }).toList();
    emit(state.copyWith(items: items));
  }

  void _onItemsReordered(ItemsReordered event, Emitter<AssignFlowState> emit) {
    final items = List<ExerciseItem>.of(state.items);
    var newIndex = event.newIndex;
    if (newIndex > event.oldIndex) newIndex -= 1;
    final moved = items.removeAt(event.oldIndex);
    items.insert(newIndex, moved);
    emit(state.copyWith(items: [for (var i = 0; i < items.length; i++) items[i].copyWith(order: i)]));
  }

  void _onItemRemoved(ItemRemoved event, Emitter<AssignFlowState> emit) {
    final items = state.items.where((i) => i.videoId != event.videoId).toList();
    emit(state.copyWith(items: [for (var i = 0; i < items.length; i++) items[i].copyWith(order: i)]));
  }

  void _onDaysToggled(DaysToggled event, Emitter<AssignFlowState> emit) {
    final days = Set<int>.of(state.daysOfWeek);
    if (days.contains(event.day)) {
      if (days.length == 1) return; // never allow an empty schedule
      days.remove(event.day);
    } else {
      days.add(event.day);
    }
    emit(state.copyWith(daysOfWeek: days));
  }

  void _onBackPressed(BackPressed event, Emitter<AssignFlowState> emit) {
    switch (state.step) {
      case AssignFlowStep.dosage:
        emit(state.copyWith(
          step: state.sourceTemplate != null ? AssignFlowStep.fork : AssignFlowStep.picker,
          confirmArmed: false,
        ));
      case AssignFlowStep.picker:
        emit(state.copyWith(step: AssignFlowStep.fork, selectedVideoIds: const [], confirmArmed: false));
      case AssignFlowStep.fork:
        break; // the screen pops the route instead
    }
  }

  Future<void> _onSubmitPressed(SubmitPressed event, Emitter<AssignFlowState> emit) async {
    // Spec §4.6 had a two-tap daily-workload guard here; removed on owner
    // call 2026-08-25 — submit goes through directly.
    final assignment = Assignment(
      id: idFn(),
      patientId: patientId,
      type: state.type,
      name: state.name,
      sourceTemplateId: state.sourceTemplate?.id,
      bodyParts: <String>{for (final i in state.items) i.bodyPart}.toList(),
      daysOfWeek: state.daysOfWeek,
      items: state.items,
      createdAt: now(),
    );
    await _submit(emit, assignment);
  }

  Future<void> _submit(Emitter<AssignFlowState> emit, Assignment assignment) async {
    emit(state.copyWith(submitStatus: AssignSubmitStatus.submitting));
    final result = await assignmentsRepository.create(assignment);
    if (result is Ok<Assignment>) {
      if (state.type == AssignmentType.protocol && state.saveAsTemplate) {
        final template = ProtocolTemplate(
          id: idFn(),
          name: state.name,
          bodyPart: assignment.bodyParts.isNotEmpty ? assignment.bodyParts.first : '',
          items: [
            for (final i in state.items)
              TemplateItem(videoId: i.videoId, order: i.order, sets: i.sets, reps: i.reps, holdSec: i.holdSec),
          ],
          createdAt: now(),
        );
        await templatesRepository.saveTemplate(template);
      }
      emit(state.copyWith(submitStatus: AssignSubmitStatus.success, failureMessage: null));
    } else if (result is Err<Assignment>) {
      emit(state.copyWith(submitStatus: AssignSubmitStatus.failure, failureMessage: result.message));
    }
  }
}
