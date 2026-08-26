import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:physio_app/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The app is portrait; only the fullscreen video stage rotates (YouTube
  // pattern — FullscreenVideoPage flips this while open).
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  runApp(PhysioApp(prefs: prefs));
}
