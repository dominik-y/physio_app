import 'package:firebase_core/firebase_core.dart';

/// Hand-written options for emulator-only development — the `demo-` project
/// prefix guarantees the SDK never talks to a real backend. Replaced by
/// flutterfire-configure output (firebase_options.dart) when the production
/// project exists; nothing else in the Firebase flavor changes at that point.
// The iOS SDK validates the GOOGLE_APP_ID shape at startup, so the fake
// values must be well-formed even though they never reach a real backend.
const emulatorOptions = FirebaseOptions(
  apiKey: 'AIzaSyDEMO-emulator-only-0000000000000',
  appId: '1:000000000000:ios:0000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'demo-tendo',
  storageBucket: 'demo-tendo.appspot.com',
);
