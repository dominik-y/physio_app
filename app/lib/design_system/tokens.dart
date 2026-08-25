import 'package:flutter/material.dart';
import 'package:physio_app/design_system/colors.dart';
import 'package:physio_app/design_system/typography.dart';

export 'package:physio_app/design_system/colors.dart';
export 'package:physio_app/design_system/typography.dart';

abstract final class AppRadii {
  static const double card = 13;
  static const double button = 12;
  static const double chip = 9;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
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
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentSoft,
      foregroundColor: AppColors.accentDeep,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accentSoft.withOpacity(0.45),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
  );
}
