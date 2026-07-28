import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/staggered_entrance.dart';
import 'gamification_controller.dart';
import 'mission_widgets.dart';

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gamificationProvider);
    final gamification = ref.read(gamificationProvider.notifier);
    final view = gamification.view();

    return Scaffold(
      appBar: AppBar(title: const Text('Missoes da Mia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: StaggeredEntrance(
          index: 1,
          child: MissionsBoard(view: view, onClaim: gamification.claim),
        ),
      ),
    );
  }
}
