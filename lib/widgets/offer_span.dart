import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
          TextSpan(text: formatBRL(offer.priceCents), style: body.copyWith(color: sa.green)),
          if (offer.km != null) TextSpan(text: ' (${_km(offer.km!)})'),
          if ((offer.addr ?? '').isNotEmpty) ...[
            const TextSpan(text: ' · '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _MapLink(addr: offer.addr!),
            ),
          ],
          if (age != null)
            TextSpan(text: ' · preço $age', style: body.copyWith(color: sa.muted)),
        ],
      ),
    );
  }
}

String _km(double km) => '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

class _MapLink extends StatelessWidget {
  const _MapLink({required this.addr});

  final String addr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': addr}),
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
