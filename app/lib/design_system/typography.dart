import 'package:flutter/material.dart';
import 'package:physio_app/design_system/colors.dart';

/// Type scale (spec §7), rebased on the MacJack design system: Figtree for
/// every text role — headings carry hierarchy through weight (w700/w800),
/// not a second face. Sizes keep the app's legibility floor (one step above
/// platform default — much of the roster is post-surgical or sixty), which
/// sits above MacJack's 14px body on purpose.
/// Documented in vault/Design System/Typography.md; keep in sync.
abstract final class AppTypography {
  static const uiFamily = 'Figtree';

  // Display / titles — bold Figtree, MacJack H3 idiom (22/w700).
  static const screenTitle = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text);
  static const titleLarge = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text);
  static const titleMedium = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text);
  static const heroHeadline = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.onAccent, height: 1.2);

  // Body — MacJack body runs Medium (w500), not Regular.
  static const bodyLarge = TextStyle(
    fontSize: 17, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.text);
  static const bodyMedium = TextStyle(
    fontSize: 15, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.text);
  static const bodySmall = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted);

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
  /// family is Figtree (set via ThemeData.fontFamily in buildTheme).
  static TextTheme textTheme(TextTheme base) {
    final t = base.apply(bodyColor: AppColors.text, displayColor: AppColors.text);
    return t.copyWith(
      bodySmall: t.bodySmall?.copyWith(
          fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 15, height: 1.4, fontWeight: FontWeight.w500),
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 17, height: 1.4, fontWeight: FontWeight.w500),
      titleMedium: t.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      titleLarge: t.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      labelLarge: t.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}
