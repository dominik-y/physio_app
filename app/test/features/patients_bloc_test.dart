import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/data/demo_repositories.dart';
import 'package:physio_app/features/patients/patients_bloc.dart';

final _testNow = DateTime(2026, 8, 25, 9, 30);

void main() {
  group('PatientsBloc', () {
    blocTest<PatientsBloc, PatientsState>(
      'builds 6 sorted rows from the seeded fixture',
      build: () {
        final store = DemoStore.seed(now: () => _testNow);
        return PatientsBloc(
          patientsRepository: DemoPatientsRepository(store),
          assignmentsRepository: DemoAssignmentsRepository(store),
          completionsRepository: DemoCompletionsRepository(store),
          now: () => _testNow,
        );
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final rows = bloc.state.rows;
        expect(bloc.state.loading, isFalse);
        expect(rows.length, 6);

        final josip = rows.firstWhere((r) => r.patient.id == 'pat-josip');
        expect(josip.daysSilent, 9);
        expect(josip.isSilent, isTrue);

        final luka = rows.firstWhere((r) => r.patient.id == 'pat-luka');
        expect(luka.invited, isTrue);
        expect(luka.strip, isEmpty);

        // Silent-first, invited-last ordering.
        expect(rows.first.patient.id, 'pat-josip');
        expect(rows.last.patient.id, 'pat-luka');
      },
    );

    blocTest<PatientsBloc, PatientsState>(
      'non-silent, non-invited rows are sorted by name',
      build: () {
        final store = DemoStore.seed(now: () => _testNow);
        return PatientsBloc(
          patientsRepository: DemoPatientsRepository(store),
          assignmentsRepository: DemoAssignmentsRepository(store),
          completionsRepository: DemoCompletionsRepository(store),
          now: () => _testNow,
        );
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final middle = bloc.state.rows.sublist(1, 5).map((r) => r.patient.name).toList();
        final sorted = [...middle]..sort();
        expect(middle, sorted);
      },
    );
  });
}
