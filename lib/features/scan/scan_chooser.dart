import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'scan_mode.dart';

/// Asks what the user is about to scan. Resolves to `null` if dismissed.
Future<ScanMode?> showScanChooser(BuildContext context) {
  return showModalBottomSheet<ScanMode>(
    context: context,
    builder: (context) => const _ScanChooser(),
  );
}

class _ScanChooser extends StatelessWidget {
  const _ScanChooser();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('O que vamos escanear?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 14),
            _Option(
              emoji: '🧾',
              tint: theme.sa.paper2,
              title: 'Nota fiscal',
              subtitle: 'QR da nota — entra no seu histórico',
              onTap: () => Navigator.pop(context, ScanMode.nota),
            ),
            const SizedBox(height: 10),
            _Option(
              emoji: '🏷️',
              tint: theme.sa.tintAmber,
              title: 'Produto',
              subtitle: 'Código de barras — compara o preço perto',
              onTap: () => Navigator.pop(context, ScanMode.produto),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.emoji,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Material(
      color: sa.paper,
      shape: RoundedRectangleBorder(
        borderRadius: SaRadius.mdAll,
        side: BorderSide(color: sa.stroke, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: SaRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tint, borderRadius: SaRadius.smAll),
                // Decorative: the adjacent title already names the option.
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: sa.muted),
            ],
          ),
        ),
      ),
    );
  }
}
