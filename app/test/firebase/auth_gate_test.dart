import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/app/app.dart';
import 'package:physio_app/data/demo_repositories.dart';
import 'package:physio_app/firebase/auth_identity.dart';
import 'package:physio_app/firebase/auth_service.dart';
import 'package:physio_app/firebase/firebase_bootstrap.dart';
import 'package:physio_app/firebase/gate/auth_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_service.dart';

/// Full-stack gate tests: TendoFirebaseApp with a fake AuthService and the
/// demo repositories standing in for Firestore. Locale defaults to hr —
/// assertions use the Croatian strings the director will see.
void main() {
  Future<void> pumpGate(WidgetTester tester, FakeAuthService service) async {
    // Phone-tall surface: the invite form must keep its submit button on
    // screen (the default 800x600 puts it below the fold and taps miss).
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(TendoFirebaseApp(
      service: service,
      prefs: prefs,
      bundleBuilder: (_) => demoRepositoryBundle(DemoStore.seed()),
    ));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('boots to splash, lands on Prijava when signed out',
      (tester) async {
    final service = FakeAuthService();
    await pumpGate(tester, service);
    expect(find.byType(GateSplash), findsOneWidget);
    service.emitUid(null);
    await settle(tester);
    expect(find.text('Prijava'), findsOneWidget);
    expect(find.text('Imam pozivni kod'), findsOneWidget);
  });

  testWidgets('wrong credentials shows the Croatian error', (tester) async {
    final service = FakeAuthService()
      ..signInResult = AuthFailure.invalidCredentials;
    await pumpGate(tester, service);
    service.emitUid(null);
    await settle(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'E-mail'), 'ana@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Lozinka'), 'wrong');
    await tester.tap(find.text('Prijavi se'));
    await settle(tester);
    expect(find.text('Pogrešna e-adresa ili lozinka.'), findsOneWidget);
    expect(find.byType(PhysioApp), findsNothing);
  });

  testWidgets('empty fields are rejected before touching the network',
      (tester) async {
    final service = FakeAuthService();
    await pumpGate(tester, service);
    service.emitUid(null);
    await settle(tester);
    await tester.tap(find.text('Prijavi se'));
    await settle(tester);
    expect(find.text('Obavezno'), findsOneWidget);
  });

  testWidgets('successful sign-in swaps in the real app', (tester) async {
    final service = FakeAuthService()..resolveResult = tomislav;
    await pumpGate(tester, service);
    service.emitUid(null);
    await settle(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'E-mail'), 'tomislav@tendo.hr');
    await tester.enterText(
        find.widgetWithText(TextField, 'Lozinka'), 'tendo-dev-1');
    await tester.tap(find.text('Prijavi se'));
    await settle(tester);
    expect(find.byType(PhysioApp), findsOneWidget);
  });

  testWidgets('invite flow: mismatched passwords stop locally', (tester) async {
    final service = FakeAuthService();
    await pumpGate(tester, service);
    service.emitUid(null);
    await settle(tester);
    await tester.tap(find.text('Imam pozivni kod'));
    await settle(tester);
    expect(find.text('Aktivirajte svoj program'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Pozivni kod'), 'LK7-3FQ9');
    await tester.enterText(
        find.widgetWithText(TextField, 'E-mail'), 'luka@example.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Lozinka'), 'lozinka1');
    await tester.enterText(
        find.widgetWithText(TextField, 'Potvrdite lozinku'), 'lozinka2');
    await tester.tap(find.text('Aktiviraj'));
    await settle(tester);
    expect(find.text('Lozinke se ne podudaraju.'), findsOneWidget);
  });

  testWidgets('invite flow: invalid code error, still on the invite screen',
      (tester) async {
    final service = FakeAuthService()..redeemResult = AuthFailure.invalidInvite;
    await pumpGate(tester, service);
    service.emitUid(null);
    await settle(tester);
    await tester.tap(find.text('Imam pozivni kod'));
    await settle(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'Pozivni kod'), 'XXX-0000');
    await tester.enterText(
        find.widgetWithText(TextField, 'E-mail'), 'luka@example.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Lozinka'), 'lozinka1');
    await tester.enterText(
        find.widgetWithText(TextField, 'Potvrdite lozinku'), 'lozinka1');
    await tester.tap(find.text('Aktiviraj'));
    await settle(tester);
    expect(
        find.text(
            'Pozivni kod nije važeći. Provjerite ga sa svojim fizioterapeutom.'),
        findsOneWidget);
    expect(find.byType(PhysioApp), findsNothing);
  });

  testWidgets(
      'invite flow: success lands in the patient app — no notLinked '
      'flash despite the mid-flow auth event', (tester) async {
    // Identity uid must match the account the fake creates ('uid-new') —
    // the cubit discards resolutions whose uid disagrees with the session.
    const luka = AuthIdentity(
        uid: 'uid-new',
        isPhysio: false,
        patientId: 'pat-luka',
        displayName: 'Luka Babić');
    final service = FakeAuthService()..resolveResult = luka;
    await pumpGate(tester, service);
    service.emitUid(null);
    await settle(tester);
    await tester.tap(find.text('Imam pozivni kod'));
    await settle(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'Pozivni kod'), 'LK7-3FQ9');
    await tester.enterText(
        find.widgetWithText(TextField, 'E-mail'), 'ana@example.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Lozinka'), 'lozinka1');
    await tester.enterText(
        find.widgetWithText(TextField, 'Potvrdite lozinku'), 'lozinka1');
    await tester.tap(find.text('Aktiviraj'));
    await settle(tester);
    expect(find.byType(PhysioApp), findsOneWidget);
    expect(find.text('Još samo korak'), findsNothing);
  });

  Future<void> signInAsAna(WidgetTester tester, FakeAuthService service) async {
    service.resolveResult = ana;
    service.signInUid = 'uid-ana';
    await pumpGate(tester, service);
    service.emitUid(null);
    await settle(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'E-mail'), 'ana@example.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Lozinka'), 'lozinka1');
    await tester.tap(find.text('Prijavi se'));
    await settle(tester);
    expect(find.byType(PhysioApp), findsOneWidget);
  }

  Future<void> openDeleteDialog(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Profil'));
    await settle(tester);
    await tester.tap(find.text('Izbriši račun'));
    await settle(tester);
    expect(find.text('Izbrisati račun?'), findsOneWidget);
  }

  testWidgets('delete account: wrong password shows the error in the dialog',
      (tester) async {
    final service = FakeAuthService()
      ..deleteResult = AuthFailure.invalidCredentials;
    await signInAsAna(tester, service);
    await openDeleteDialog(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'Lozinka'), 'kriva-lozinka');
    await tester.tap(find.text('Izbriši'));
    await settle(tester);
    expect(find.text('Pogrešna e-adresa ili lozinka.'), findsOneWidget);
    expect(find.byType(PhysioApp), findsOneWidget,
        reason: 'a failed deletion must leave the session running');
  });

  testWidgets('delete account: success lands back on the gate', (tester) async {
    final service = FakeAuthService();
    await signInAsAna(tester, service);
    await openDeleteDialog(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'Lozinka'), 'lozinka1');
    await tester.tap(find.text('Izbriši'));
    await settle(tester);
    expect(find.byType(PhysioApp), findsNothing);
    expect(find.text('Prijava'), findsOneWidget);
  });

  testWidgets('resolve error screen: retry recovers, and Odjava is an escape',
      (tester) async {
    final service = FakeAuthService()..resolveFailure = AuthFailure.network;
    await pumpGate(tester, service);
    service.emitUid('uid-physio');
    await settle(tester);
    expect(
        find.text('Nema veze s internetom. Provjerite vezu i pokušajte '
            'ponovno.'),
        findsOneWidget);
    // Network comes back → retry succeeds into the app.
    service
      ..resolveFailure = null
      ..resolveResult = tomislav;
    await tester.tap(find.text('Pokušaj ponovno'));
    await settle(tester);
    expect(find.byType(PhysioApp), findsOneWidget);
  });

  testWidgets('resolve error screen: Odjava returns to the login gate',
      (tester) async {
    final service = FakeAuthService()..resolveFailure = AuthFailure.unknown;
    await pumpGate(tester, service);
    service.emitUid('uid-physio');
    await settle(tester);
    await tester.tap(find.text('Odjava'));
    await settle(tester);
    expect(find.text('Prijava'), findsOneWidget);
  });

  testWidgets('notLinked resolution shows the recovery invite screen',
      (tester) async {
    final service = FakeAuthService()..resolveFailure = AuthFailure.notLinked;
    await pumpGate(tester, service);
    service.emitUid('uid-orphan');
    await settle(tester);
    expect(find.text('Još samo korak'), findsOneWidget);
    // Recovery variant asks only for the code — no email/password fields.
    expect(find.widgetWithText(TextField, 'E-mail'), findsNothing);
    expect(find.text('Odjava'), findsOneWidget);
  });
}
