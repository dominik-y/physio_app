import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/core/dates.dart';
import 'package:physio_app/core/session_engine.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/features/session/session_page.dart';

import 'harness.dart';

void main() {
  testWidgets('Ana completes her resumed session through real Done/Skip taps', (tester) async {
    final store = seededStore();

    await pumpScreen(
      tester,
      const SessionPage(),
      store: store,
      role: UserRole.patient,
    );

    // Ana resumes mid-session: v-quad already done this morning, 6 remain.
    // Mix in one Skip among the Dones.
    const skipAt = 3;
    for (var i = 0; i < 6; i++) {
      final label = i == skipAt ? 'Skip this one' : 'Done · next exercise';
      final finder = find.text(label);
      expect(finder, findsOneWidget, reason: 'step $i should show the "$label" control');
      await tester.tap(finder);
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('Session complete'), findsOneWidget);

    final today = Dates.ymd(testNow);
    final completionsToday =
        (store.completions.value['pat-ana'] ?? const <Completion>[]).where((c) => c.date == today);
    expect(completionsToday.length, 7);

    // Recompute against the store directly — never through features/home/.
    final session = buildTodaySession(
      assignments: store.assignments.value.where((a) => a.patientId == 'pat-ana').toList(),
      completions: store.completions.value['pat-ana'] ?? const [],
      now: testNow,
    );
    expect(session.completedToday, isTrue);
    expect(session.doneCount + session.skippedCount, 7);
  });
}
