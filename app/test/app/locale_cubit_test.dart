import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:physio_app/app/locale_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to Croatian with no saved preference', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cubit = LocaleCubit(prefs: prefs);
    expect(cubit.state, const Locale('hr'));
    expect(Intl.defaultLocale, 'hr');
    await cubit.close();
  });

  test('restores a saved language', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    final prefs = await SharedPreferences.getInstance();
    final cubit = LocaleCubit(prefs: prefs);
    expect(cubit.state, const Locale('en'));
    await cubit.close();
  });

  test('toggle flips hr ↔ en and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cubit = LocaleCubit(prefs: prefs);

    cubit.toggle();
    expect(cubit.state, const Locale('en'));
    expect(prefs.getString('app_locale'), 'en');
    expect(Intl.defaultLocale, 'en');

    cubit.toggle();
    expect(cubit.state, const Locale('hr'));
    expect(prefs.getString('app_locale'), 'hr');
    await cubit.close();
  });

  test('unknown saved value falls back to Croatian', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'de'});
    final prefs = await SharedPreferences.getInstance();
    final cubit = LocaleCubit(prefs: prefs);
    expect(cubit.state, const Locale('hr'));
    await cubit.close();
  });
}
