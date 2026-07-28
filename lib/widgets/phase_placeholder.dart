import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Stands in for a screen a later phase builds.
///
/// Names the phase so the running app and `PROGRESS.md` never disagree about
/// what is left. Every one of these disappears as its phase lands.
class PhasePlaceholder extends StatelessWidget {
  const PhasePlaceholder({super.key, required this.title, required this.phase, required this.summary});

  final String title;
  final int phase;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: sa.paper2,
                borderRadius: SaRadius.pill,
                border: Border.all(color: sa.stroke, width: 1.5),
              ),
              child: Text(
                'FASE $phase',
                style: theme.textTheme.labelSmall!.copyWith(color: sa.amberPress, letterSpacing: 1.2),
              ),
            ),
            const SizedBox(height: 14),
            Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              summary,
              style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
