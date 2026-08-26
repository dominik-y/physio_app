import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:physio_app/app/app.dart';
import 'package:physio_app/data/firebase/firestore_repositories.dart';
import 'package:physio_app/firebase/emulator_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase flavor entrypoint. The demo entrypoint (main.dart) stays the
/// default build — this one is opt-in: `flutter run -t lib/main_firebase.dart`.
///
/// Emulator-only for now (no production project exists yet): options are the
/// hand-written demo- set and USE_EMULATOR defaults to true. When the real
/// project is provisioned (day-1 wizard), flutterfire configure adds
/// firebase_options.dart and this file switches to it.
///
/// DEV BOOTSTRAP: until the real auth gate (login/redemption screens) lands,
/// this signs in a seeded emulator account directly:
///   --dart-define=DEV_LOGIN=physio  (default) → Tomislav, physio claim
///   --dart-define=DEV_LOGIN=ana               → Ana, linked patient
/// Seed the emulator first: cd firebase && npm run seed
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(options: emulatorOptions);

  const useEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: true);
  if (useEmulator) {
    const host =
        String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }

  const devLogin = String.fromEnvironment('DEV_LOGIN', defaultValue: 'physio');
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    final (email, password) = devLogin == 'ana'
        ? ('ana@example.com', 'tendo-dev-1')
        : ('tomislav@tendo.hr', 'tendo-dev-1');
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      // Emulator not seeded (or not running) — surface it loudly instead of
      // booting into a rules-denied ghost town.
      debugPrint('DEV LOGIN FAILED (${e.code}) — did you run `npm run seed` '
          'in firebase/ with the emulators up?');
      rethrow;
    }
  }

  final prefs = await SharedPreferences.getInstance();
  runApp(PhysioApp(
    prefs: prefs,
    repositories: firestoreRepositoryBundle(
      FirebaseFirestore.instance,
      forPhysio: devLogin != 'ana',
    ),
  ));
}
