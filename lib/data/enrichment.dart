import '../core/api_client.dart';
import '../core/categoria.dart';
import '../core/pooled.dart';
import 'economia_api.dart';
import 'models/app_location.dart';
import 'models/precos.dart';
import 'models/receipt.dart';

/// Prices a whole nota against the user's location: one `/api/precos` call per
/// item, `pricing.receiptConcurrency` (default six) in flight.
///
/// Six, not twenty: Menor Preço rate-limits, and a 429 is an item that comes
/// back silently unpriced. An item whose call fails is left with `precos ==
/// null` — the report shows it as uncompared, and the rest of the nota still
/// renders. A whole failed pass therefore never blocks the receipt.
///
/// [ReceiptItem.unit] travels on every call because the backend's per-UN vs
/// per-KG like-for-like filter is armed by it — that is the client's half of
/// the produce false-match guardrail.
///
/// The matched product's fiscal NCM is stamped onto the item so `classify()`
/// stops guessing from the description on every re-open.
Future<Receipt> enrichReceipt(
  EconomiaApi api,
  Receipt receipt,
  AppLocation location,
) async {
  final items = await pooled(receipt.items, api.config.pricing.receiptConcurrency, (ReceiptItem item) async {
    Precos? precos;
    try {
      precos = await api.precosForItem(
        description: item.description,
        unit: item.unit,
        storeName: receipt.header.storeName,
        city: receipt.header.city,
        location: location,
      );
    } on ApiException {
      precos = null;
    }
    return item.copyWith(precos: precos, ncm: precos?.ncm ?? item.ncm);
  });

  return receipt.copyWith(
    items: items,
    enrichedAt: DateTime.now().millisecondsSinceEpoch,
    locationCep: location.cep,
  );
}

/// Every per-store price seen during enrichment, as dated observations for
/// weekday-trend detection.
///
/// An offer with no store code or no date is dropped: the code is the record
/// key and the date is the entire point, so a partial one could only dilute a
/// median later.
List<PriceObservation> mineOffers(List<ReceiptItem> items) => [
      for (final item in items)
        for (final offer in item.precos?.stores ?? const <Offer>[])
          if (offer.cod != null && (offer.datahora ?? '').isNotEmpty)
            PriceObservation(
              cod: offer.cod!,
              store: offer.store,
              category: classify(description: item.description, ncm: item.ncm),
              gtin: item.precos?.gtin,
              priceCents: offer.priceCents,
              datahora: offer.datahora!,
            ),
    ];

/// Whether a receipt's prices are missing or about somewhere the user no longer
/// is. A nota priced for another CEP is worse than an unpriced one — it looks
/// authoritative and is about another city.
bool needsPricing(Receipt receipt, AppLocation location) =>
    receipt.enrichedAt == null || receipt.locationCep != location.cep;
