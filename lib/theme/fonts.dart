import 'package:flutter/material.dart';

/// Typography: Fredoka for headings and labels, Baloo 2 for numbers, Nunito for
/// body — the three families the reference implementation loaded.
///
/// Google ships all three only as variable fonts, so each family is a single
/// asset and weight is selected along the `wght` axis. [_v] sets `fontWeight`
/// as well as `fontVariations`: the axis is what actually renders, the weight
/// keeps fallback fonts and any synthetic bolding in agreement with it.
abstract final class SaText {
  static const _fredoka = 'Fredoka';
  static const _baloo = 'Baloo2';
  static const _nunito = 'Nunito';

  static TextStyle _v(String family, double size, int weight, {double? height, double? letterSpacing}) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: FontWeight.values.firstWhere((w) => w.value == weight),
      fontVariations: [FontVariation('wght', weight.toDouble())],
    );
  }

  /// Numbers are always tabular so figures don't jitter as they update.
  static TextStyle number(double size, {int weight = 700}) =>
      _v(_baloo, size, weight, height: 1.1).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Headings and labels.
  static TextStyle fredoka(double size, {int weight = 600, double? height, double? letterSpacing}) =>
      _v(_fredoka, size, weight, height: height, letterSpacing: letterSpacing);

  /// Body copy.
  static TextStyle nunito(double size, {int weight = 400, double? height, double? letterSpacing}) =>
      _v(_nunito, size, weight, height: height ?? 1.45, letterSpacing: letterSpacing);

  /// Small uppercase section header — "ATALHOS", "MISSÕES DA MIA".
  static TextStyle get sectionLabel => fredoka(11.8, weight: 600, letterSpacing: 1.65);

  /// The tiny uppercase label on dark hero cards — "MIA · DÁ PRA ECONOMIZAR".
  static TextStyle get heroLabel => fredoka(11.5, weight: 600, letterSpacing: 1.15);

  static final theme = TextTheme(
    // Baloo 2 — the figures.
    displaySmall: number(34, weight: 800), // Resumo hero
    headlineMedium: number(32), // Home hero
    // Fredoka — headings and labels.
    headlineSmall: fredoka(24, weight: 700), // wordmark
    titleLarge: fredoka(18.4, weight: 600), // section headings
    titleMedium: fredoka(17, weight: 600), // greeting
    titleSmall: fredoka(15.7, weight: 600), // tile and quest names
    labelLarge: fredoka(13.6, weight: 600), // buttons
    labelSmall: fredoka(10.6, weight: 600, height: 1), // tab labels
    // Nunito — body.
    bodyLarge: nunito(16.8),
    bodyMedium: nunito(14.4),
    bodySmall: nunito(12.8),
    labelMedium: nunito(12.2, weight: 600), // metadata lines
  );
}
