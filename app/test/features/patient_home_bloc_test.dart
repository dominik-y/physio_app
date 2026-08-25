import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/data/demo_repositories.dart';
import 'package:physio_app/design_system/hero_card.dart';
import 'package:physio_app/features/home/patient_home_bloc.dart';

void main() {
  // Matches the harness/core fixtures (a Tuesday).
  final testNow = DateTime(2026, 8, 25, 9, 30);
  DemoStore store() => DemoStore.seed(now: () => testNow);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  PatientHomeBloc bloc(DemoStore s, String patientId) => PatientHomeBloc(
        patientId: patientId,
        assignmentsRepository: DemoAssignmentsRepository(s),
        completionsRepository: DemoCompletionsRepository(s),
        patientsRepository: DemoPatientsRepository(s),
        now: () => testNow,
      );

  group('PatientHomeBloc — Ana (two protocols, resumable)', () {
    test('resume state, 7 total / 6 remaining, two protocol names', () async {
      final s = store();
      final b = bloc(s, DemoData.currentPatientId);
      addTearDown(b.close);
      await settle();

      expect(b.state.heroState, HeroState.resume);
      expect(b.state.totalExercises, 7);
      expect(b.state.remaining, 6);
      expect(b.state.protocolNames.length, 2);
    });

    test('singles list contains the private video with a New badge, clears on open', () async {
      final s = store();
      final b = bloc(s, DemoData.currentPatientId);
      addTearDown(b.close);
      await settle();

      final single = b.state.singles.singleWhere((row) => row.assignmentId == 'as-ana-single');
      expect(single.title, 'Ana — knee focus this week');
      expect(single.seen, isFalse);

      b.add(const AssignmentOpened('as-ana-single'));
      await settle();

      final updated = b.state.singles.singleWhere((row) => row.assignmentId == 'as-ana-single');
      expect(updated.seen, isTrue);
    });
  });

  group('PatientHomeBloc — Petra (assigned today, unopened)', () {
    test('showNew true, heroState start', () async {
      final s = store();
      final b = bloc(s, DemoData.newTodayPatientId);
      addTearDown(b.close);
      await settle();

      expect(b.state.showNew, isTrue);
      expect(b.state.heroState, HeroState.start);
    });
  });
}
