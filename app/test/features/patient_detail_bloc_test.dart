import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/data/demo_repositories.dart';
import 'package:physio_app/features/patients/patient_detail_bloc.dart';

final _testNow = DateTime(2026, 8, 25, 9, 30);

PatientDetailBloc _bloc(DemoStore store, String patientId) => PatientDetailBloc(
      patientId: patientId,
      patientsRepository: DemoPatientsRepository(store),
      assignmentsRepository: DemoAssignmentsRepository(store),
      completionsRepository: DemoCompletionsRepository(store),
      libraryRepository: DemoLibraryRepository(store),
      now: () => _testNow,
    );

void main() {
  group('PatientDetailBloc', () {
    blocTest<PatientDetailBloc, PatientDetailState>(
      'loads Ana: two protocols with progress, one private single, notes',
      build: () => _bloc(DemoStore.seed(now: () => _testNow), 'pat-ana'),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final state = bloc.state;
        expect(state.loading, isFalse);
        expect(state.patient?.id, 'pat-ana');
        expect(state.protocols.length, 2);
        for (final p in state.protocols) {
          expect(p.doneCount, greaterThan(0));
          expect(p.assignment.items, isNotEmpty);
        }
        expect(state.singles.length, 1);
        final singleItem = state.singles.single.items.single;
        expect(state.privateVideoIds.contains(singleItem.videoId), isTrue);
        expect(state.notes, contains('ACL'));
      },
    );

    blocTest<PatientDetailBloc, PatientDetailState>(
      'debounces NotesChanged 500ms before saving',
      build: () => _bloc(DemoStore.seed(now: () => _testNow), 'pat-ivana'),
      act: (bloc) {
        bloc.add(const NotesChanged('Fi'));
        bloc.add(const NotesChanged('Fir'));
        bloc.add(const NotesChanged('Final note'));
      },
      wait: const Duration(milliseconds: 600),
      verify: (bloc) {
        expect(bloc.state.notes, 'Final note');
      },
    );

    test('RegenerateInvitePressed issues a new code and exposes it in state', () async {
      final store = DemoStore.seed(now: () => _testNow);
      final bloc = _bloc(store, 'pat-luka');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final originalCode = store.patients.value.firstWhere((p) => p.id == 'pat-luka').inviteCode;

      bloc.add(const RegenerateInvitePressed());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.lastGeneratedCode, isNotNull);
      final updated = store.patients.value.firstWhere((p) => p.id == 'pat-luka');
      expect(updated.inviteCode, bloc.state.lastGeneratedCode);
      expect(updated.inviteCode, isNot(originalCode));

      await bloc.close();
    });
  });
}
