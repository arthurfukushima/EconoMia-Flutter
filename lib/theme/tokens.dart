import 'package:flutter/material.dart';

/// The "Sage & Amber" design system.
///
/// Values are the `--sa-*` custom properties from the reference implementation,
/// carried over verbatim. Sage & Amber is the *only* palette here: the reference
/// app ran it alongside an older high-contrast "sticker" palette and shipping
/// only this one was the single open design debt it recorded.
///
/// Everything a widget draws comes from here or from [ColorScheme] — no
/// hardcoded `Color(0x…)` anywhere under `lib/features/`. That rule is what
/// makes adding a dark theme later a wiring job instead of a refactor; the dark
/// values are already worked out in [SaColors.dark] below.
@immutable
class SaColors extends ThemeExtension<SaColors> {
  const SaColors({
    required this.paper,
    required this.paper2,
    required this.paper3,
    required this.forest,
    required this.forestDeep,
    required this.ink,
    required this.muted,
    required this.amber,
    required this.amberLight,
    required this.amberPress,
    required this.green,
    required this.mint,
    required this.danger,
    required this.dangerBg,
    required this.tintGreen,
    required this.tintAmber,
    required this.stroke,
    required this.stroke2,
    required this.lift,
    required this.liftSm,
  });

  /// Page background and card fill.
  final Color paper;

  /// Recessed fill — pills, inputs, icon chips.
  final Color paper2;

  /// One step deeper than [paper2]; used where two recessed tones meet.
  final Color paper3;

  /// The dark hero surface (Mia's savings card, "today" cards).
  final Color forest;

  /// Deeper forest, for elements layered *on* [forest].
  final Color forestDeep;

  /// Primary text.
  final Color ink;

  /// Secondary text — metadata, captions, inactive tabs.
  final Color muted;

  /// The accent. Calls to action, the scan FAB, the active tab.
  final Color amber;

  /// Top stop of the amber CTA gradient.
  final Color amberLight;

  /// Pressed amber — also the active-tab text, which needs more contrast than
  /// [amber] can give against [paper].
  final Color amberPress;

  /// Savings, on light surfaces.
  final Color green;

  /// Savings, on [forest]. [green] is unreadable there.
  final Color mint;

  /// Overpaying, errors.
  final Color danger;

  /// Error banner fill.
  final Color dangerBg;

  /// Icon-chip tint for "savings/produce" shortcuts.
  final Color tintGreen;

  /// Icon-chip tint for "offers/deals" shortcuts.
  final Color tintAmber;

  /// Hairline borders.
  final Color stroke;

  /// Emphasised hairline — the tab bar's top edge, completed quest rows.
  final Color stroke2;

  /// The soft card lift.
  final List<BoxShadow> lift;

  /// A shallower lift, for small elements like the points pill.
  final List<BoxShadow> liftSm;

  static const light = SaColors(
    paper: Color(0xFFF5EEDD),
    paper2: Color(0xFFEBE0C6),
    paper3: Color(0xFFE1D5B8),
    forest: Color(0xFF14312A),
    forestDeep: Color(0xFF0F241C),
    ink: Color(0xFF14312A),
    muted: Color(0xFF8A8064),
    amber: Color(0xFFE4872B),
    amberLight: Color(0xFFEC9740),
    amberPress: Color(0xFFC96E1E),
    green: Color(0xFF1E7A52),
    mint: Color(0xFF54C98C),
    danger: Color(0xFFD64B2A),
    dangerBg: Color(0xFFFBDAD0),
    tintGreen: Color(0xFFCFE6D3),
    tintAmber: Color(0xFFF4D8AF),
    stroke: Color(0x2614312A), // rgba(20,49,42,.15)
    stroke2: Color(0x4714312A), // rgba(20,49,42,.28)
    lift: [BoxShadow(color: Color(0x1714312A), blurRadius: 22, offset: Offset(0, 8))],
    liftSm: [BoxShadow(color: Color(0x0F14312A), blurRadius: 12, offset: Offset(0, 3))],
  );

  /// Worked out and contrast-checked against `paper`, but **not wired up** —
  /// [MaterialApp] ships `theme:` only. Enabling dark mode is: pass this to a
  /// second [ThemeData], add `darkTheme:`, then walk the screens once.
  ///
  /// Derived by inverting the paper/forest relationship. Amber and mint carry
  /// over unchanged because that pairing is already proven on a forest surface
  /// — it is exactly the light theme's hero card.
  static const dark = SaColors(
    paper: Color(0xFF0F241C),
    paper2: Color(0xFF16342B),
    paper3: Color(0xFF1E4438),
    forest: Color(0xFF0A1A14),
    forestDeep: Color(0xFF061009),
    ink: Color(0xFFF5EEDD),
    muted: Color(0xFF9AA79E),
    amber: Color(0xFFE4872B),
    amberLight: Color(0xFFEC9740),
    amberPress: Color(0xFFEC9740), // press goes lighter on a dark surface
    green: Color(0xFF54C98C), // #1E7A52 dies here
    mint: Color(0xFF54C98C),
    danger: Color(0xFFF08163),
    dangerBg: Color(0xFF3A1A12),
    tintGreen: Color(0xFF1E4438),
    tintAmber: Color(0xFF4A3418),
    stroke: Color(0x24F5EEDD), // rgba(245,238,221,.14)
    stroke2: Color(0x42F5EEDD), // rgba(245,238,221,.26)
    lift: [BoxShadow(color: Color(0x66000000), blurRadius: 22, offset: Offset(0, 8))],
    liftSm: [BoxShadow(color: Color(0x4D000000), blurRadius: 12, offset: Offset(0, 3))],
  );

  @override
  SaColors copyWith({
    Color? paper,
    Color? paper2,
    Color? paper3,
    Color? forest,
    Color? forestDeep,
    Color? ink,
    Color? muted,
    Color? amber,
    Color? amberLight,
    Color? amberPress,
    Color? green,
    Color? mint,
    Color? danger,
    Color? dangerBg,
    Color? tintGreen,
    Color? tintAmber,
    Color? stroke,
    Color? stroke2,
    List<BoxShadow>? lift,
    List<BoxShadow>? liftSm,
  }) {
    return SaColors(
      paper: paper ?? this.paper,
      paper2: paper2 ?? this.paper2,
      paper3: paper3 ?? this.paper3,
      forest: forest ?? this.forest,
      forestDeep: forestDeep ?? this.forestDeep,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      amber: amber ?? this.amber,
      amberLight: amberLight ?? this.amberLight,
      amberPress: amberPress ?? this.amberPress,
      green: green ?? this.green,
      mint: mint ?? this.mint,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      tintGreen: tintGreen ?? this.tintGreen,
      tintAmber: tintAmber ?? this.tintAmber,
      stroke: stroke ?? this.stroke,
      stroke2: stroke2 ?? this.stroke2,
      lift: lift ?? this.lift,
      liftSm: liftSm ?? this.liftSm,
    );
  }

  @override
  SaColors lerp(SaColors? other, double t) {
    if (other == null) return this;
    return SaColors(
      paper: Color.lerp(paper, other.paper, t)!,
      paper2: Color.lerp(paper2, other.paper2, t)!,
      paper3: Color.lerp(paper3, other.paper3, t)!,
      forest: Color.lerp(forest, other.forest, t)!,
      forestDeep: Color.lerp(forestDeep, other.forestDeep, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberLight: Color.lerp(amberLight, other.amberLight, t)!,
      amberPress: Color.lerp(amberPress, other.amberPress, t)!,
      green: Color.lerp(green, other.green, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      tintGreen: Color.lerp(tintGreen, other.tintGreen, t)!,
      tintAmber: Color.lerp(tintAmber, other.tintAmber, t)!,
      stroke: Color.lerp(stroke, other.stroke, t)!,
      stroke2: Color.lerp(stroke2, other.stroke2, t)!,
      lift: BoxShadow.lerpList(lift, other.lift, t)!,
      liftSm: BoxShadow.lerpList(liftSm, other.liftSm, t)!,
    );
  }
}

/// `Theme.of(context).sa` — the shorthand every widget uses.
extension SaThemeAccess on ThemeData {
  SaColors get sa => extension<SaColors>()!;
}

/// Corner radii. The reference implementation had no formal spacing scale, so
/// none is invented here — only these radii recur enough to name.
abstract final class SaRadius {
  /// Inputs, small buttons.
  static const sm = Radius.circular(12);

  /// Tiles, quest rows, list cards.
  static const md = Radius.circular(16);

  /// Toasts.
  static const lg = Radius.circular(18);

  /// Hero cards, bottom sheets, the tab bar's top corners.
  static const xl = Radius.circular(22);

  static const smAll = BorderRadius.all(sm);
  static const mdAll = BorderRadius.all(md);
  static const lgAll = BorderRadius.all(lg);
  static const xlAll = BorderRadius.all(xl);

  /// Chips, badges, CTAs, progress bars.
  static const pill = BorderRadius.all(Radius.circular(999));
}

/// Motion, carried over from the reference implementation's three easings.
abstract final class SaMotion {
  /// Entrances.
  static const easeOut = Cubic(0.16, 1, 0.3, 1);

  /// Overshoot — things that pop in.
  static const easeBack = Cubic(0.34, 1.56, 0.64, 1);

  /// Presses.
  static const easeSquish = Cubic(0.22, 1, 0.36, 1);

  static const fast = Duration(milliseconds: 100);
  static const normal = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 750);
}
