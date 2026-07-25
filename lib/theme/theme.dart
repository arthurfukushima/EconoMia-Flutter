import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fonts.dart';
import 'tokens.dart';

/// Design tokens → [ThemeData].
///
/// Material's own roles are wired to the Sage & Amber palette so an unstyled
/// `Card`, `TextButton` or `TextField` already looks like the app. The roles
/// Material has no slot for live in [SaColors], reachable as
/// `Theme.of(context).sa`.
ThemeData buildTheme() {
  const sa = SaColors.light;

  final scheme = ColorScheme.fromSeed(
    seedColor: sa.amber,
    primary: sa.amber,
    onPrimary: sa.ink, // the amber CTA carries dark text, not white
    secondary: sa.green,
    onSecondary: sa.paper,
    surface: sa.paper,
    onSurface: sa.ink,
    surfaceContainerHighest: sa.paper2,
    outline: sa.stroke2,
    outlineVariant: sa.stroke,
    error: sa.danger,
    onError: sa.paper,
    errorContainer: sa.dangerBg,
    onErrorContainer: sa.danger,
  );

  return ThemeData(
    colorScheme: scheme,
    extensions: const [sa],
    textTheme: SaText.theme.apply(bodyColor: sa.ink, displayColor: sa.ink),
    scaffoldBackgroundColor: sa.paper,
    splashFactory: InkSparkle.splashFactory,

    appBarTheme: AppBarTheme(
      backgroundColor: sa.paper,
      foregroundColor: sa.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: SaText.fredoka(18.4, weight: 700).copyWith(color: sa.ink),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    // Sheets are the app's modal idiom — the scan chooser and every picker.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: sa.paper,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: const Color(0x6B0F241C), // rgba(15,36,28,.42)
      showDragHandle: true,
      dragHandleColor: sa.stroke2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: SaRadius.xl),
      ),
    ),

    dividerTheme: DividerThemeData(color: sa.stroke, thickness: 1.5, space: 1.5),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: sa.amber,
        foregroundColor: sa.ink,
        textStyle: SaText.fredoka(15, weight: 700),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: SaRadius.pill),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: sa.amberPress,
        textStyle: SaText.fredoka(13.6, weight: 600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: sa.paper2,
      hintStyle: SaText.nunito(14.4).copyWith(color: sa.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: SaRadius.smAll,
        borderSide: BorderSide(color: sa.stroke, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: SaRadius.smAll,
        borderSide: BorderSide(color: sa.stroke, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: SaRadius.smAll,
        borderSide: BorderSide(color: sa.amber, width: 2),
      ),
    ),
  );
}
