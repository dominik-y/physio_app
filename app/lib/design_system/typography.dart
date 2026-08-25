import 'package:flutter/material.dart';
import 'package:physio_app/design_system/colors.dart';

/// Type scale (spec §7), rebased on the Poliklinika Tendo brand pairing:
/// Manrope for all UI text, Libre Baskerville for display headings — the same
/// pairing as poliklinika-tendo.com. Base one step above platform default for
/// legibility — much of the roster is post-surgical or sixty.
/// Documented in vault/Design System/Typography.md; keep in sync.
abstract final class AppTypography {
  static const uiFamily = 'Manrope';
  static const displayFamily = 'LibreBaskerville';

  // Display / titles — serif carries the brand voice; only w400/w700 exist.
  static const screenTitle = TextStyle(
    fontFamily: displayFamily,
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text);
  static const titleLarge = TextStyle(
    fontFamily: displayFamily,
    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text);
  static const titleMedium = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text);
  static const heroHeadline = TextStyle(
    fontFamily: displayFamily,
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.onAccent, height: 1.25);

  // Body
  static const bodyLarge = TextStyle(fontSize: 17, height: 1.4, color: AppColors.text);
  static const bodyMedium = TextStyle(fontSize: 15, height: 1.4, color: AppColors.text);
  static const bodySmall = TextStyle(fontSize: 13, color: AppColors.textMuted);

  // Labels
  static const buttonLabel = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const eyebrow = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: AppColors.accentSoft);
  static const sectionHeader = TextStyle(
    fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: AppColors.textMuted);
  static const pillValue = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text);
  static const pillLabel = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: AppColors.textMuted);
  static const chip = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

  /// The app-wide TextTheme, derived from a Material base. The ambient
  /// family is Manrope (set via ThemeData.fontFamily in buildTheme); the two
  /// large title slots switch to the display serif.
  static TextTheme textTheme(TextTheme base) {
    final t = base.apply(bodyColor: AppColors.text, displayColor: AppColors.text);
    return t.copyWith(
      bodySmall: t.bodySmall?.copyWith(fontSize: 13, color: AppColors.textMuted),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 17, height: 1.4),
      titleMedium: t.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      titleLarge: t.titleLarge?.copyWith(
          fontFamily: displayFamily, fontSize: 22, fontWeight: FontWeight.w700),
      labelLarge: t.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}
