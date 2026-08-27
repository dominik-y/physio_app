import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/app/session_scope.dart';
import 'package:physio_app/design_system/demo_video_player.dart';
import 'package:physio_app/design_system/real_video_player.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

/// Player fallbacks for the Firebase flavor (plan §3.7): no URL in a signed
/// -in session and failed loads must both read as "video unavailable" — never
/// a fake demo animation or an eternal spinner. Croatian, like the gate tests.
void main() {
  Widget host(Widget child, {AppSession? session}) => MaterialApp(
        locale: const Locale('hr'),
        supportedLocales: const [Locale('hr'), Locale('en')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: SessionScope(
          session: session,
          child: Scaffold(body: child),
        ),
      );

  final session = AppSession(
    displayName: 'Ana Kovačević',
    patientId: 'pat-ana',
    signOut: () async {},
  );

  testWidgets('session mode + no mediaUrl: unavailable stage, no fake player',
      (tester) async {
    await tester.pumpWidget(host(
      const DemoVideoPlayer(
          title: 'Čučanj', bodyPart: 'Knee', durationSec: 60),
      session: session,
    ));
    await tester.pump();
    expect(find.text('Video je trenutačno nedostupan.'), findsOneWidget);
    // No retry — there is no URL to retry against.
    expect(find.text('Pokušaj ponovno'), findsNothing);
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsNothing);
  });

  testWidgets('demo mode keeps the animated placeholder untouched',
      (tester) async {
    await tester.pumpWidget(host(
      const DemoVideoPlayer(
          title: 'Čučanj', bodyPart: 'Knee', durationSec: 60),
    ));
    await tester.pump();
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    expect(find.text('Video je trenutačno nedostupan.'), findsNothing);
  });

  testWidgets('failed load shows unavailable + retry instead of a spinner',
      (tester) async {
    // No video_player platform in widget tests: initialize() rejects, which
    // is exactly the failed-load path.
    await tester.pumpWidget(host(
      const RealVideoPlayer(url: 'https://storage.example/dead.mp4'),
      session: session,
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text('Video je trenutačno nedostupan.'), findsOneWidget);
    expect(find.text('Pokušaj ponovno'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Retry re-enters the loading path (and fails again here — still no
    // spinner deadlock, the retry stays available).
    await tester.tap(find.text('Pokušaj ponovno'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Pokušaj ponovno'), findsOneWidget);
  });

  testWidgets('session mode with a real mediaUrl routes to the real player',
      (tester) async {
    await tester.pumpWidget(host(
      const DemoVideoPlayer(
        title: 'Čučanj',
        bodyPart: 'Knee',
        durationSec: 60,
        mediaUrl: 'https://storage.example/v.mp4',
      ),
      session: session,
    ));
    await tester.pump();
    expect(find.byType(RealVideoPlayer), findsOneWidget);
  });
}
