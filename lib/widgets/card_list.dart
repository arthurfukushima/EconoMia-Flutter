import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The bordered, divided list every card-style section is drawn in — receipt
/// rows, basket rows, nearby-store rows. One shared shell so a divider tweak
/// doesn't need to be repeated per screen.
class CardList extends StatelessWidget {
  const CardList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final sa = Theme.of(context).sa;
    return Container(
      decoration: BoxDecoration(
        color: sa.paper,
        borderRadius: SaRadius.mdAll,
        border: Border.all(color: sa.stroke, width: 1.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: sa.stroke),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: children[i],
            ),
          ],
        ],
      ),
    );
  }
}
