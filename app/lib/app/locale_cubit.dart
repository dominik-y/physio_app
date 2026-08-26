import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App language. Croatian is the product default (owner call 2026-08-25:
/// Tendo's physios and patients are Croatian); English is secondary.
class LocaleCubit extends Cubit<Locale> {
  static const _prefsKey = 'app_locale';
  static const supported = [Locale('hr'), Locale('en')];

  final SharedPreferences? _prefs;

  LocaleCubit({SharedPreferences? prefs})
      : _prefs = prefs,
        super(_initial(prefs)) {
    Intl.defaultLocale = state.languageCode;
  }

  static Locale _initial(SharedPreferences? prefs) {
    final saved = prefs?.getString(_prefsKey);
    return supported.firstWhere(
      (l) => l.languageCode == saved,
      orElse: () => const Locale('hr'),
    );
  }

  void setLanguage(String code) {
    final locale = supported.firstWhere(
      (l) => l.languageCode == code,
      orElse: () => const Locale('hr'),
    );
    Intl.defaultLocale = locale.languageCode;
    _prefs?.setString(_prefsKey, locale.languageCode);
    emit(locale);
  }

  void toggle() =>
      setLanguage(state.languageCode == 'hr' ? 'en' : 'hr');
}
