import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/core/dates.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/data/demo_repositories.dart';
import 'package:physio_app/features/assignments/assign_flow_bloc.dart';

/// Matches the app-wide demo "now" (a Tuesday, per test/widget/harness.dart).
final _testNow = DateTime(2026, 8, 25, 9, 30);

/// Lets the bloc's combineLatest4 subscription (and any async submit) settle
/// before the next assertion or event — flutter_bloc dispatches `add()`
/// through its internal event stream, so nothing lands synchronously.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 5));

AssignFlowBloc _buildBloc(DemoStore store, String patientId, {IdFn? idFn}) => AssignFlowBloc(
      patientId,
      DemoAssignmentsRepository(store),
      DemoTemplatesRepository(store),
      DemoLibraryRepository(store),
      DemoPatientsRepository(store),
      now: () => _testNow,
      idFn: idFn,
    );

void main() {
  group('AssignFlowBloc', () {
    blocTest<AssignFlowBloc, AssignFlowState>(
      'StartedFromTemplate snapshots items — editing dosage never mutates the template',
      build: () => _buildBloc(DemoStore.seed(now: () => _testNow), DemoData.adherentPatientId),
      act: (bloc) async {
        await _settle();
        final template = bloc.state.templates.firstWhere((t) => t.id == 'tpl-meniscus');
        final quadDefault = template.items.firstWhere((i) => i.videoId == 'v-quad');

        bloc.add(StartedFromTemplate(template));
        await _settle();
        bloc.add(DosageChanged('v-quad', sets: quadDefault.sets + 5));
        await _settle();
      },
      verify: (bloc) {
        final workingItem = bloc.state.items.firstWhere((i) => i.videoId == 'v-quad');
        final template = bloc.state.templates.firstWhere((t) => t.id == 'tpl-meniscus');
        final templateQuad = template.items.firstWhere((i) => i.videoId == 'v-quad');

        expect(bloc.state.step, AssignFlowStep.dosage);
        expect(workingItem.sets, templateQuad.sets + 5);
        expect(workingItem.overridden, isTrue);
        // The source template's own item is untouched by the edit above.
        expect(templateQuad.sets, bloc.state.templateDefaults['v-quad']!.sets);
      },
    );

    blocTest<AssignFlowBloc, AssignFlowState>(
      'overridden flips on and back off when the value returns to the template default',
      build: () => _buildBloc(DemoStore.seed(now: () => _testNow), DemoData.adherentPatientId),
      act: (bloc) async {
        await _settle();
        final template = bloc.state.templates.firstWhere((t) => t.id == 'tpl-meniscus');
        final quadDefault = template.items.firstWhere((i) => i.videoId == 'v-quad');

        bloc.add(StartedFromTemplate(template));
        await _settle();

        bloc.add(DosageChanged('v-quad', reps: quadDefault.reps + 4));
        await _settle();
        expect(bloc.state.items.firstWhere((i) => i.videoId == 'v-quad').overridden, isTrue);

        bloc.add(DosageChanged('v-quad', reps: quadDefault.reps));
        await _settle();
      },
      verify: (bloc) {
        final workingItem = bloc.state.items.firstWhere((i) => i.videoId == 'v-quad');
        expect(workingItem.overridden, isFalse);
      },
    );

    blocTest<AssignFlowBloc, AssignFlowState>(
      'reordering exercises reassigns contiguous order fields',
      build: () => _buildBloc(DemoStore.seed(now: () => _testNow), DemoData.adherentPatientId),
      act: (bloc) async {
        await _settle();
        final template = bloc.state.templates.firstWhere((t) => t.id == 'tpl-meniscus');
        bloc.add(StartedFromTemplate(template));
        await _settle();
        // Move the first item (v-quad) to the end.
        bloc.add(const ItemsReordered(0, 4));
        await _settle();
      },
      verify: (bloc) {
        final ids = bloc.state.items.map((i) => i.videoId).toList();
        expect(ids.first, isNot('v-quad'));
        expect(ids.last, 'v-quad');
        expect(bloc.state.items.map((i) => i.order).toList(), [0, 1, 2, 3]);
      },
    );

    blocTest<AssignFlowBloc, AssignFlowState>(
      'assigning a second protocol requires two SubmitPressed taps (§4.6 guard)',
      build: () => _buildBloc(DemoStore.seed(now: () => _testNow), DemoData.twoProtocolPatientId),
      act: (bloc) async {
        await _settle();
        // Ana already has meniscus (4) + core (3) = 7 active protocol items.
        expect(bloc.state.existingDailyTotal, 7);

        final rotator = bloc.state.templates.firstWhere((t) => t.id == 'tpl-rotator');
        bloc.add(StartedFromTemplate(rotator));
        await _settle();
        expect(bloc.state.items.length, 3);

        bloc.add(const SubmitPressed());
        await _settle();
        expect(bloc.state.confirmArmed, isTrue);
        expect(bloc.state.submitStatus, AssignSubmitStatus.idle);
        expect(bloc.state.existingDailyTotal + bloc.state.items.length, 10);

        bloc.add(const SubmitPressed());
        await _settle();
      },
      verify: (bloc) {
        expect(bloc.state.submitStatus, AssignSubmitStatus.success);
      },
    );

    blocTest<AssignFlowBloc, AssignFlowState>(
      'single-video path submits directly from the picker, skipping dosage',
      build: () => _buildBloc(DemoStore.seed(now: () => _testNow), DemoData.silentPatientId),
      act: (bloc) async {
        await _settle();
        bloc.add(const StartedSingle());
        await _settle();
        expect(bloc.state.step, AssignFlowStep.picker);

        bloc.add(const PickerSelectionToggled('v-wall'));
        await _settle();
        bloc.add(const PickerConfirmed());
        await _settle();
      },
      verify: (bloc) {
        expect(bloc.state.step, AssignFlowStep.picker); // never visited dosage
        expect(bloc.state.submitStatus, AssignSubmitStatus.success);
      },
    );

    blocTest<AssignFlowBloc, AssignFlowState>(
      'the picker refuses selecting a video already in the working set',
      build: () => _buildBloc(DemoStore.seed(now: () => _testNow), DemoData.adherentPatientId),
      act: (bloc) async {
        await _settle();
        bloc.add(const StartedCustom());
        await _settle();

        bloc.add(const PickerSelectionToggled('v-quad'));
        await _settle();
        bloc.add(const PickerConfirmed());
        await _settle();
        expect(bloc.state.step, AssignFlowStep.dosage);
        expect(bloc.state.items.map((i) => i.videoId), ['v-quad']);

        bloc.add(const BackPressed()); // dosage -> picker (custom path)
        await _settle();
        expect(bloc.state.step, AssignFlowStep.picker);

        // v-quad is already in items — must be refused, not re-added.
        bloc.add(const PickerSelectionToggled('v-quad'));
        await _settle();
      },
      verify: (bloc) {
        expect(bloc.state.selectedVideoIds, isEmpty);
        expect(bloc.state.items.map((i) => i.videoId), ['v-quad']);
      },
    );
  });
}
