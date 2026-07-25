import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/scan/scan_chooser.dart';
import '../theme/tokens.dart';
import 'bottom_nav.dart';
import 'wordmark.dart';

/// The persistent frame: wordmark on top, tab bar at the bottom, the selected
/// branch in between. Screens reached from Home's shortcut tiles (Minhas Notas,
/// No mercado) are pushed *above* this shell, so they hide the bar and get a
/// back button.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  Future<void> _openScanChooser(BuildContext context) async {
    final mode = await showScanChooser(context);
    if (mode == null || !context.mounted) return;
    context.push('/scan?mode=${mode.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Wordmark(),
        titleSpacing: 18,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Divider(height: 1.5, color: Theme.of(context).sa.stroke),
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: BottomNav(
        currentIndex: navigationShell.currentIndex,
        // `initialLocation: true` on a re-tap pops that branch back to its root,
        // which is the behaviour people expect from a tab bar.
        onSelect: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        onScan: () => _openScanChooser(context),
      ),
    );
  }
}
