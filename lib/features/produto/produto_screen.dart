import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../data/models/precos.dart';
import '../../theme/tokens.dart';
import '../../widgets/card_list.dart';
import '../../widgets/cat_chip.dart';
import '../../widgets/location_bar.dart';
import '../../widgets/nutrition_panel.dart';
import '../../widgets/offer_span.dart';
import '../../widgets/raw_data.dart';
import '../location/location_controller.dart';
import 'produto_controller.dart';

/// One scanned barcode → the local price range, the cheapest nearby offer,
/// and every store that carries it — `/api/precos`'s GTIN path, where the
/// barcode *is* the identity, so there is no "aprox." flag and no options to
/// choose between.
class ProdutoScreen extends ConsumerWidget {
  const ProdutoScreen({super.key, required this.gtin});

  final String gtin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationControllerProvider);
    final async = ref.watch(produtoProvider(gtin));
    final data = async.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Produto')),
      body: Column(
        children: [
          const LocationBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push('/scan?mode=produto'),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('escanear outro'),
              ),
            ),
          ),
          // Price section and nutrition are independent lookups — nutrition
          // needs only the gtin, so it renders below regardless of whether a
          // location is set or the price lookup is loading or failed.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              children: [
                switch ((location, data, async)) {
                  (null, _, _) =>
                    const _Banner(text: 'Informe seu CEP acima para comparar preços na sua região.'),
                  (_, final Precos p, _) => _PriceSummary(gtin: gtin, data: p),
                  (_, _, AsyncError()) => _Banner(
                      text: 'Falha ao buscar preços. Tente novamente.',
                      danger: true,
                      onRetry: () => ref.invalidate(produtoProvider(gtin)),
                    ),
                  _ => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                },
                const SizedBox(height: 22),
                NutritionPanel(gtin: gtin),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.danger = false, this.onRetry});

  final String text;
  final bool danger;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: theme.textTheme.bodyMedium!.copyWith(color: danger ? sa.danger : sa.muted),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('tentar de novo')),
          ],
        ],
      ),
    );
  }
}

/// The name/category header, the price range + cheapest offer (or the honest
/// "nothing nearby" state), the raw-data inspector, and the full nearby-store
/// list.
class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.gtin, required this.data});

  final String gtin;
  final Precos data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final hasOffers = data.nOffers > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: CatChip(description: data.name, ncm: data.ncm),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(data.name ?? 'Código $gtin', style: theme.textTheme.titleMedium),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (hasOffers) ...[
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                const TextSpan(text: 'Na sua região: '),
                TextSpan(text: _rangeText(data.range), style: theme.textTheme.titleMedium),
                TextSpan(
                  text: ' · ${data.nOffers} ${data.nOffers == 1 ? 'oferta' : 'ofertas'}'
                      ' em ${data.nStores} ${data.nStores == 1 ? 'loja' : 'lojas'}',
                  style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
                ),
              ],
            ),
          ),
          if (data.cheapest != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mais barato: ', style: theme.textTheme.bodyMedium),
                Expanded(child: OfferSpan(offer: data.cheapest!)),
              ],
            ),
          ],
        ] else
          Text(
            'Sem preço por perto para o código $gtin. Os preços cobrem cerca de duas '
            'semanas de notas fiscais na região — tente aumentar o raio acima.',
            style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
          ),
        const SizedBox(height: 10),
        RawData(data: data.toJson()),
        if (data.stores.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('Lojas próximas (${data.stores.length})', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          CardList(children: [for (final s in data.stores) StoreRow(offer: s)]),
          const SizedBox(height: 10),
          Text(
            'Preços de notas fiscais recentes na sua região (Menor Preço / Nota Paraná).',
            style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
          ),
        ],
      ],
    );
  }
}

String _rangeText(PriceRange? range) => formatRangeBRL(range?.minCents, range?.maxCents);
