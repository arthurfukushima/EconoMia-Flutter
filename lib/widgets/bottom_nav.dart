import 'package:flutter/material.dart';

import '../theme/fonts.dart';
import '../theme/tokens.dart';

/// The five-slot tab bar. Four are routes; the raised centre one is the scan
/// action, which opens a chooser sheet rather than navigating.
///
/// "No mercado" and "Minhas Notas" deliberately have no slot here — they are
/// reached from Home's shortcut tiles. That is what keeps the bar at five.
class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onScan,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;

  static const _barHeight = 60.0;
  static const _fabSize = 64.0;

  /// How far the scan button rises above the bar's top edge.
  static const _fabOverhang = 30.0;

  /// Total vertical space the bar occupies, so screens can pad their scroll
  /// views clear of it.
  static double heightOf(BuildContext context) =>
      _barHeight + _fabOverhang + MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final sa = Theme.of(context).sa;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: _barHeight + _fabOverhang + safeBottom,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: _barHeight + safeBottom,
              padding: EdgeInsets.only(bottom: safeBottom),
              decoration: BoxDecoration(
                color: sa.paper,
                border: Border(top: BorderSide(color: sa.stroke2, width: 1.5)),
                borderRadius: const BorderRadius.vertical(top: SaRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: sa.ink.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _Tab(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Início',
                    selected: currentIndex == 0,
                    onTap: () => onSelect(0),
                  ),
                  _Tab(
                    icon: Icons.shopping_cart_outlined,
                    activeIcon: Icons.shopping_cart_rounded,
                    label: 'Lista',
                    selected: currentIndex == 1,
                    onTap: () => onSelect(1),
                  ),
                  const SizedBox(width: _fabSize + 16),
                  _Tab(
                    icon: Icons.local_offer_outlined,
                    activeIcon: Icons.local_offer_rounded,
                    label: 'Ofertas',
                    selected: currentIndex == 2,
                    onTap: () => onSelect(2),
                  ),
                  _Tab(
                    icon: Icons.bar_chart_rounded,
                    activeIcon: Icons.bar_chart_rounded,
                    label: 'Resumo',
                    selected: currentIndex == 3,
                    onTap: () => onSelect(3),
                  ),
                ],
              ),
            ),
          ),
          Align(alignment: Alignment.topCenter, child: _ScanButton(onTap: onScan)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.sa.amberPress : theme.sa.muted;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: SaRadius.mdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? activeIcon : icon, size: 24, color: color),
                const SizedBox(height: 3),
                // A wrapped label would blow the bar's fixed height. One line,
                // always — the icon carries the meaning if it has to clip.
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: theme.textTheme.labelSmall!.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The flagship action, and the only entry point to scanning.
class _ScanButton extends StatefulWidget {
  const _ScanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<_ScanButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final sa = Theme.of(context).sa;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Semantics(
        button: true,
        label: 'Escanear',
        child: AnimatedContainer(
          duration: SaMotion.fast,
          curve: SaMotion.easeOut,
          transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
          width: BottomNav._fabSize,
          height: BottomNav._fabSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [sa.amberLight, sa.amber],
            ),
            border: Border.all(color: const Color(0x385A2D0A), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: sa.amberPress.withValues(alpha: 0.34),
                blurRadius: _pressed ? 14 : 22,
                offset: Offset(0, _pressed ? 5 : 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner_rounded, size: 26, color: sa.ink),
              const SizedBox(height: 1),
              Text(
                'Escanear',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: SaText.fredoka(9.3, weight: 700, height: 1).copyWith(color: sa.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
