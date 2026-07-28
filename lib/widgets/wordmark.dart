import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// "Econo" + "Mia" — the name is the mascot, so the second half always carries
/// the accent colour.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.showLogo = true, this.fontSize = 24, this.color});

  final bool showLogo;
  final double fontSize;

  /// Colour of the "Econo" half. Defaults to ink; the splash overrides it,
  /// since ink is invisible on forest.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final style = theme.textTheme.headlineSmall!.copyWith(fontSize: fontSize, color: color ?? sa.ink);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(fontSize * 0.37),
            child: Image.asset(
              'assets/img/mia_logo_android.png',
              width: fontSize * 1.67,
              height: fontSize * 1.67,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: fontSize * 0.42),
        ],
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Econo'),
              TextSpan(text: 'Mia', style: TextStyle(color: sa.amber)),
            ],
          ),
          style: style,
        ),
      ],
    );
  }
}
