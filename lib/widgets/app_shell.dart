import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/notifications.dart';
import '../data/receipt_repository.dart';
import '../domain/insights.dart';
import '../domain/notifications_copy.dart';
import '../features/action_indicators/action_indicators.dart';
import '../features/gamification/gamification_controller.dart';
import '../features/scan/scan_chooser.dart';
import '../features/gamification/quest_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import 'bottom_nav.dart';
import 'location_bar.dart';
import 'wordmark.dart';

/// The persistent frame: wordmark on top, tab bar at the bottom, the selected
/// branch in between. Screens reached from Home's shortcut tiles (Minhas Notas,
/// No mercado) are pushed *above* this shell, so they hide the bar and get a
/// back button.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  Future<void> _openScanChooser(BuildContext context) async {
    final mode = await showScanChooser(context);
    if (mode == null || !context.mounted) return;
    context.push('/scan?mode=${mode.name}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Schedule daily reminder on gamification or receipts change. The quests
    // might refresh (a new daily), and the receipts might update (a new scan).
    ref.watch(gamificationProvider);
    final actionIndicators = ref.watch(actionIndicatorsProvider);
    ref.watch(receiptRepositoryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final receipts = await ref
            .read(receiptRepositoryProvider)
            .listReceipts();
        final gamification = ref.read(gamificationProvider.notifier);
        final view = gamification.view();
        final lastPurchase = mostRecentPurchase(receipts);
        final daysSinceLastScan = lastPurchase == null
            ? null
            : DateTime.now().difference(lastPurchase).inDays;
        final copy = dailyReminderCopy(
          quests: view,
          daysSinceLastScan: daysSinceLastScan,
        );

        if (copy != null) {
          await NotificationService.scheduleDaily(
            title: 'EconoMia',
            body: copy,
          );
        } else {
          await NotificationService.cancelDaily();
        }
      } catch (_) {
        // Silently skip scheduling if init wasn't called (test environment)
      }
    });

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: const Wordmark(),
            titleSpacing: 18,
            floating: true,
            snap: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.5),
              child: Divider(height: 1.5, color: Theme.of(context).sa.stroke),
            ),
          ),
        ],
        body: Stack(
          children: [
            Column(
              children: [
                const LocationBar(),
                Expanded(child: navigationShell),
              ],
            ),
            const QuestToast(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: navigationShell.currentIndex,
        indicators: actionIndicators,
        // `initialLocation: true` on a re-tap pops that branch back to its root,
        // which is the behaviour people expect from a tab bar.
        onSelect: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        onScan: () => _openScanChooser(context),
      ),
    );
  }
}
