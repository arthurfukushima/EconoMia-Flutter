import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'staggered_entrance.dart';

/// The bordered, divided list every card-style section is drawn in — receipt
/// rows, basket rows, nearby-store rows. One shared shell so a divider tweak
/// doesn't need to be repeated per screen.
class CardList extends StatelessWidget {
  const CardList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final sa = Theme.of(context).sa;
    // A Material, not a DecoratedBox: rows carry ListTiles and ExpansionTiles
    // (the "trocar produto" and nutrition collapsibles), and those paint their
    // background and ink on the nearest Material ancestor — a coloured box in
    // between would swallow both.
    return Material(
      color: sa.paper,
      shape: RoundedRectangleBorder(
        borderRadius: SaRadius.mdAll,
        side: BorderSide(color: sa.stroke, width: 1.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: sa.stroke),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: StaggeredEntrance(index: i, child: children[i]),
            ),
          ],
        ],
      ),
    );
  }
}
