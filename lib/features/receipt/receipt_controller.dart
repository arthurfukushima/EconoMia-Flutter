import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/economia_api.dart';
import '../../data/enrichment.dart';
import '../../data/models/receipt.dart';
import '../../data/receipt_repository.dart';
import '../location/location_controller.dart';

/// Reads a saved nota back from disk — scan and History both land here by
/// [Receipt.accessKey], so re-opening one is always this same lookup.
///
/// Pricing writes back to the same store and invalidates this, which is what
/// makes "the report fills in once prices arrive" a re-read rather than a
/// second copy of the receipt held in memory.
final receiptProvider = FutureProvider.autoDispose.family<Receipt?, String>(
  (ref, accessKey) => ref.watch(receiptRepositoryProvider).getReceipt(accessKey),
);

final receiptControllerProvider = NotifierProvider<ReceiptController, void>(
  ReceiptController.new,
);

class ReceiptController extends Notifier<void> {
  @override
  void build() {}

  /// Prices [receipt] against the current location and saves the result.
  ///
  /// A no-op when there is no location or the nota is already priced for this
  /// CEP — the caller can fire it freely on every open. Throws only if the
  /// *write* fails; individual price lookups that fail leave their item
  /// uncompared rather than sinking the pass.
  Future<void> price(Receipt receipt) async {
    final location = ref.read(locationControllerProvider);
    if (location == null || !needsPricing(receipt, location)) return;

    final priced = await enrichReceipt(
      ref.read(economiaApiProvider),
      receipt,
      location,
    );
    final repo = ref.read(receiptRepositoryProvider);
    await repo.saveReceipt(priced);
    // Trend observations are a by-product; losing them must never cost the
    // user the prices that were just fetched.
    unawaited(repo.saveOffers(mineOffers(priced.items)).catchError((Object _) {}));
    ref.invalidate(receiptProvider(priced.accessKey));
  }
}
