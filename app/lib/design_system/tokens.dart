import 'package:flutter/material.dart';
import 'package:physio_app/design_system/colors.dart';
import 'package:physio_app/design_system/typography.dart';

export 'package:physio_app/design_system/colors.dart';
export 'package:physio_app/design_system/typography.dart';

/// MacJack radius idiom: generously rounded cards, fully-round pills for
/// anything tappable-and-small, a modest radius for inline tiles.
abstract final class AppRadii {
  static const double card = 20;
  static const double pill = 100; // buttons, chips — reads as a stadium
  static const double tile = 12; // dosage pills, thumbs, inputs
  // Legacy aliases so call sites keep reading naturally.
  static const double button = pill;
  static const double chip = pill;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// MacJack "card" effect, recolored to Tendo ink: one soft drop shadow does
/// the lifting — cards are borderless.
abstract final class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x1F03262F), // AppColors.text at 12%
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
}

/// Light only (spec §7). Colors from colors.dart, type from typography.dart.
ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppTypography.uiFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.bg,
  );
  return base.copyWith(
    textTheme: AppTypography.textTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.screenTitle,
    ),
    dividerColor: AppColors.border,
    // MacJack FAB: solid brand, fully round — stadium keeps extended FABs a
    // pill and square ones a circle. accentDeep, not accent — white on
    // accent is only 3.4:1.
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentDeep,
      foregroundColor: AppColors.onAccent,
      shape: StadiumBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentDeep, // white label on accent fails AA
        foregroundColor: AppColors.onAccent,
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentDeep,
        shape: const StadiumBorder(),
      ),
    ),
    // MacJack dialogs: white, radius ~24, bold centered title.
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: AppTypography.titleLarge,
      contentTextStyle: AppTypography.bodyMedium,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accentTint,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.accentDeep : AppColors.textMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected) ? AppColors.accentDeep : AppColors.textMuted,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.accentDeep,
      contentTextStyle: const TextStyle(color: AppColors.onAccent, fontSize: 15),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.tile)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted),
      floatingLabelStyle: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.accentDeep),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.tile),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.tile),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.tile),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
  );
}
