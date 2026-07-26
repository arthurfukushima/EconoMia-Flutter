import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Collapsed-by-default dump of a raw `/api/precos` response — an escape
/// hatch for judging a match without reading server logs. Shared by Produto
/// and Mercado.
class RawData extends StatelessWidget {
  const RawData({super.key, required this.data});

  final Object? data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Container(
      decoration: BoxDecoration(
        borderRadius: SaRadius.smAll,
        border: Border.all(color: sa.stroke, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      // A Material, not just a coloured Container — ExpansionTile needs one
      // to paint its ink splash on.
      child: Material(
        color: sa.paper,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text('Dados brutos', style: theme.textTheme.labelLarge),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(data),
                  style: theme.textTheme.bodySmall!.copyWith(color: sa.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
