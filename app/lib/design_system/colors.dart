import 'package:flutter/material.dart';

/// Poliklinika Tendo palette — brand blue #0090C3 on cool clinical white,
/// extracted from poliklinika-tendo.com (Wix theme variables). Documented in
/// vault/Design System/Colors.md; keep the two in sync when anything changes.
///
/// Contrast discipline (WCAG AA, measured):
/// - text on bg: 14.9:1, textMuted on bg: 5.1:1
/// - brand blue on bg is only 3.4:1 — reserved for fills, gradients and
///   large graphics; anything textual or carrying white text uses accentDeep
///   (white on accentDeep: 7.1:1).
abstract final class AppColors {
  // Surfaces
  static const bg = Color(0xFFF5F8F9);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFD5E0E5);

  // Text
  static const text = Color(0xFF03262F); // Tendo ink (deep petrol)
  static const textMuted = Color(0xFF546D7A);

  // Brand
  static const accent = Color(0xFF0090C3); // Tendo blue (logo)
  static const accentDeep = Color(0xFF03607F);
  static const accentSoft = Color(0xFFB5E3F2);
  static const onAccent = Color(0xFFFFFFFF);

  // Signals
  static const warning = Color(0xFFB45309); // skipped-exercise indicator
  static const danger = Color(0xFFB3261E); // inactive-patient warning

  // Signal fills (chip backgrounds)
  static const warningSoft = Color(0xFFF6E3CE);
  static const dangerSoft = Color(0xFFF6D9D6);

  // Video surfaces (session player, single-video page)
  static const videoBg = Color(0xFF03262F);

  /// Hero gradient: accentDeep → accent at 150° (spec §7).
  static const heroGradient = LinearGradient(
    begin: Alignment(-0.87, -0.5), // 150°
    end: Alignment(0.87, 0.5),
    colors: [accentDeep, accent],
  );
}
