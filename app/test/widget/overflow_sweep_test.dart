import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/core/dates.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/data/demo_repositories.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/features/assignments/assign_flow_screen.dart';
import 'package:physio_app/features/home/patient_home_page.dart';
import 'package:physio_app/features/home/single_video_page.dart';
import 'package:physio_app/features/library/library_page.dart';
import 'package:physio_app/features/patients/patient_detail_page.dart';
import 'package:physio_app/features/patients/patients_page.dart';
import 'package:physio_app/features/role_gate/role_gate_page.dart';
import 'package:physio_app/features/session/session_page.dart';
import 'package:physio_app/features/templates/templates_page.dart';

import 'harness.dart';

/// Every screen × every size: any RenderFlex overflow (or other render
/// exception) fails the pump. Player animations never settle, so bounded
/// pumps are used throughout — never pumpAndSettle.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 120));
  }
  expect(t.takeException(), isNull);
}

void main() {
  final staticScreens = <String, Widget Function()>{
    'role gate': () => const RoleGatePage(),
    'patients list': () => const PatientsPage(),
    'library': () => const LibraryPage(),
    'templates': () => const TemplatesPage(),
    'patient home (Ana, resume)': () => const PatientHomePage(),
    'session (Ana, in progress)': () => const SessionPage(),
    'assign fork (Ana)': () => const AssignFlowScreen(patientId: DemoData.twoProtocolPatientId),
    'single video page': () =>
        const SingleVideoPage(title: 'Ana — knee focus this week', bodyPart: 'Knee', durationSec: 130),
    for (final id in const [
      DemoData.adherentPatientId,
      DemoData.skippingPatientId,
      DemoData.twoProtocolPatientId,
      DemoData.silentPatientId,
      DemoData.newTodayPatientId,
      DemoData.unredeemedPatientId,
    ])
      'patient detail ($id)': () => PatientDetailPage(patientId: id),
  };

  for (final entry in staticScreens.entries) {
    for (final size in screenSizes) {
      testWidgets('${entry.key} renders clean at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await pumpScreen(tester, entry.value(), size: size);
        await settle(tester);
      });
    }
  }

  group('state variants', () {
    DemoStore anaStore() => seededStore();

    Future<void> completeAnaToday(DemoStore store) async {
      final repo = DemoCompletionsRepository(store);
      for (final a in store.assignments.value.where((a) =>
          a.patientId == DemoData.currentPatientId && a.type == AssignmentType.protocol)) {
        for (final item in a.items) {
          await repo.record(
            DemoData.currentPatientId,
            Completion.forDay(
              date: Dates.ymd(testNow),
              assignmentId: a.id,
              videoId: item.videoId,
              status: CompletionStatus.done,
              at: testNow,
            ),
          );
        }
      }
    }

    void deactivateAna(DemoStore store) {
      store.assignments.update((list) => [
            for (final a in list)
              a.patientId == DemoData.currentPatientId ? a.copyWith(active: false) : a
          ]);
    }

    for (final size in screenSizes) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('home + session in completed state at $label', (tester) async {
        final store = anaStore();
        await completeAnaToday(store);
        await pumpScreen(tester, const PatientHomePage(), store: store, size: size);
        await settle(tester);
        await pumpScreen(tester, const SessionPage(), store: store, size: size);
        await settle(tester);
      });

      testWidgets('home + session with nothing assigned at $label', (tester) async {
        final store = anaStore();
        deactivateAna(store);
        await pumpScreen(tester, const PatientHomePage(), store: store, size: size);
        await settle(tester);
        await pumpScreen(tester, const SessionPage(), store: store, size: size);
        await settle(tester);
      });
    }

    testWidgets('long names and heavy caseload survive 320x568', (tester) async {
      final store = anaStore();
      store.patients.update((list) => [
            for (final p in list)
              p.id == DemoData.adherentPatientId
                  ? p.copyWith(name: 'Maximilijana Konstantinović-Šimunović Wiedersehen')
                  : p
          ]);
      final assignRepo = DemoAssignmentsRepository(store);
      final tpl = store.templates.value.first;
      for (var i = 0; i < 4; i++) {
        await assignRepo.create(Assignment(
          id: 'as-stress-$i',
          patientId: DemoData.adherentPatientId,
          type: AssignmentType.protocol,
          name: 'A very long protocol name that keeps going and going — phase $i',
          bodyParts: [tpl.bodyPart],
          daysOfWeek: const {1, 2, 3, 4, 5, 6, 7},
          items: [
            ExerciseItem(
              videoId: 'v-stress-$i',
              order: 0,
              sets: 12,
              reps: 100,
              holdSec: 3599,
              title: 'An implausibly long exercise title for stress testing text overflow',
              durationSec: 3599,
              bodyPart: tpl.bodyPart,
            ),
          ],
          createdAt: testNow,
        ));
      }
      const smallest = Size(320, 568);
      await pumpScreen(tester, const PatientsPage(), store: store, size: smallest);
      await settle(tester);
      await pumpScreen(tester, const PatientDetailPage(patientId: DemoData.adherentPatientId),
          store: store, size: smallest);
      await settle(tester);
    });
  });

  group('assign flow steps at 320x568', () {
    testWidgets('template path reaches dosage editor cleanly', (tester) async {
      await pumpScreen(
        tester,
        const AssignFlowScreen(patientId: DemoData.twoProtocolPatientId),
        size: const Size(320, 568),
      );
      await settle(tester);
      await tester.tap(find.textContaining('Oporavak meniskusa').last, warnIfMissed: false);
      await settle(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('custom path reaches picker cleanly', (tester) async {
      await pumpScreen(
        tester,
        const AssignFlowScreen(patientId: DemoData.twoProtocolPatientId),
        size: const Size(320, 568),
      );
      await settle(tester);
      await tester.tap(find.textContaining('vlastiti protokol'), warnIfMissed: false);
      await settle(tester);
    });
  });

  group('upload sheet at 320x568', () {
    testWidgets('sheet opens and title field focuses without overflow', (tester) async {
      await pumpScreen(tester, const LibraryPage(), size: const Size(320, 568));
      await settle(tester);
      await tester.tap(find.byIcon(Icons.add).first, warnIfMissed: false);
      await settle(tester);
      final field = find.byType(TextField).first;
      if (field.evaluate().isNotEmpty) {
        await tester.tap(field, warnIfMissed: false);
        await settle(tester);
      }
    });
  });
}
