import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/nutrition.dart';
import '../data/off_api.dart';
import '../theme/tokens.dart';

/// Nutri-Score's official brand colours — a regulatory label, not part of
/// this app's own palette, so it stays outside [SaColors] on purpose.
const _nutriscoreColors = {
  'a': Color(0xFF038141),
  'b': Color(0xFF85BB2F),
  'c': Color(0xFFFECB02),
  'd': Color(0xFFEE8100),
  'e': Color(0xFFE63E11),
};

/// The bare body — badges, ingredients, per-100g table, disclaimer. Assumes a
/// hit; [NutritionPanel] and Mercado's collapsible each handle the states
/// around it (loading, not found) their own way.
class NutritionBody extends StatelessWidget {
  const NutritionBody({super.key, required this.n});

  final Nutrition n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final subtitle = [n.brands, n.quantity].where((s) => s.isNotEmpty).join(' · ');
    final scoreColor = _nutriscoreColors[n.nutriscore.toLowerCase()];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtitle.isNotEmpty) ...[
          Text(subtitle, style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted)),
          const SizedBox(height: 8),
        ],
        if (scoreColor != null || n.nova != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (scoreColor != null)
                _Badge(text: 'Nutri-Score ${n.nutriscore.toUpperCase()}', color: scoreColor),
              if (n.nova != null) _Badge(text: 'NOVA ${n.nova}', color: sa.paper2, textColor: sa.ink),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (n.ingredients.isNotEmpty) ...[
          Text('Ingredientes', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(n.ingredients, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
        ],
        if (n.nutrients.isNotEmpty) ...[
          Text('Por 100 g/ml', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Table(
            columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
            children: [
              for (final row in n.nutrients)
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(row.label, style: theme.textTheme.bodyMedium),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '${row.value == row.value.roundToDouble() ? row.value.toStringAsFixed(0) : row.value.toStringAsFixed(1).replaceAll('.', ',')} ${row.unit}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ]),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Text.rich(
          TextSpan(
            style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
            children: const [TextSpan(text: 'Dados de Open Food Facts (colaborativo) — podem estar incompletos.')],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, this.textColor});

  final String text;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: SaRadius.pill),
      child: Text(
        text,
        style: theme.textTheme.labelMedium!.copyWith(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Full panel with its own loading / not-found states — for Produto, where
/// nutrition is always visible under the price summary.
class NutritionPanel extends ConsumerWidget {
  const NutritionPanel({super.key, required this.gtin});

  final String gtin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final async = ref.watch(nutritionProvider(gtin));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informação nutricional', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        switch (async) {
          AsyncData(:final value?) => NutritionBody(n: value),
          AsyncLoading() => Text('Buscando informação nutricional…', style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted)),
          _ => Text(
              'Código $gtin não encontrado no Open Food Facts. A base é colaborativa e muitos '
              'produtos brasileiros ainda não têm cadastro.',
              style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
            ),
        },
      ],
    );
  }
}
