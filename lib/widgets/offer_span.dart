import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_config.dart';
import '../core/money.dart';
import '../data/models/precos.dart';
import '../theme/tokens.dart';

/// How old a price is, in the same pt-BR shape the reference app used.
///
/// Formatted at render time rather than at fetch time, so a receipt reopened
/// from disk two weeks later says "de 14 dias atrás" instead of "de hoje".
String? priceAge(String? iso, {DateTime? now}) {
  final seen = DateTime.tryParse(iso ?? '');
  if (seen == null) return null;
  final days = (now ?? DateTime.now()).difference(seen).inDays;
  if (days <= 0) return 'de hoje';
  if (days == 1) return 'de ontem';
  return 'de $days dias atrás';
}

/// One store's offer: "Loja · bairro **R$ 3,19** (1,2 km) · mapa · preço de
/// ontem". Shared by the receipt, produto and mercado screens.
///
/// Everything after the price is optional and simply absent when the API did
/// not send it — a nameless offer still shows its price rather than inventing
/// a store.
class OfferSpan extends StatelessWidget {
  const OfferSpan({super.key, required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final body = theme.textTheme.labelMedium!;
    final age = priceAge(offer.datahora);
    final where = [
      offer.store ?? 'loja próxima',
      if ((offer.bairro ?? '').isNotEmpty) offer.bairro!,
    ].join(' · ');

    return Text.rich(
      TextSpan(
        style: body,
        children: [
          TextSpan(text: '$where '),
          TextSpan(
            text: formatBRL(offer.priceCents),
            style: body.copyWith(color: sa.green),
          ),
          if (offer.km != null) TextSpan(text: ' (${_km(offer.km!)})'),
          if ((offer.addr ?? '').isNotEmpty) ...[
            const TextSpan(text: ' · '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _MapLink(addr: offer.addr!),
            ),
          ],
          if (age != null)
            TextSpan(
              text: ' · preço $age',
              style: body.copyWith(color: sa.muted),
            ),
        ],
      ),
    );
  }
}

String _km(double km) => '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

/// One store's offer as a two-line card, for "N mercados" lists.
///
/// [OfferSpan] packs the same facts into one wrapping sentence, which is fine
/// inline ("mais barato: …") but cramped as a list row — a long store name
/// pushes price, distance and age onto a third line. Here line 1 is the place
/// and line 2 packs price/distance/age behind icons, with the map link as a
/// corner button instead of a word in the middle of the text.
class StoreRow extends ConsumerWidget {
  const StoreRow({super.key, required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final meta = theme.textTheme.labelMedium!;
    final age = priceAge(offer.datahora)?.replaceFirst(RegExp(r'^de '), '');
    final where = [
      offer.store ?? 'loja próxima',
      if ((offer.bairro ?? '').isNotEmpty) offer.bairro!,
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(where, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    formatBRL(offer.priceCents),
                    style: meta.copyWith(color: sa.green),
                  ),
                  if (offer.km != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.place_outlined, size: 15, color: sa.muted),
                    const SizedBox(width: 3),
                    Text(_km(offer.km!), style: meta.copyWith(color: sa.muted)),
                  ],
                  if (age != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: sa.muted,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              age,
                              style: meta.copyWith(color: sa.muted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if ((offer.addr ?? '').isNotEmpty)
          IconButton(
            icon: const Icon(Icons.place_outlined, size: 18),
            color: sa.amberPress,
            tooltip: 'ver ${offer.store ?? 'loja'} no mapa',
            visualDensity: VisualDensity.compact,
            onPressed: () => launchUrl(
              ref.read(appConfigProvider).maps.uriFor(offer.addr!),
              mode: LaunchMode.externalApplication,
            ),
          ),
      ],
    );
  }
}

class _MapLink extends ConsumerWidget {
  const _MapLink({required this.addr});

  final String addr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => launchUrl(
        ref.read(appConfigProvider).maps.uriFor(addr),
        mode: LaunchMode.externalApplication,
      ),
      child: Text(
        'mapa',
        semanticsLabel: 'abrir $addr no mapa',
        style: theme.textTheme.labelMedium!.copyWith(
          color: theme.sa.amberPress,
          decoration: TextDecoration.underline,
          decorationColor: theme.sa.amberPress,
        ),
      ),
    );
  }
}
