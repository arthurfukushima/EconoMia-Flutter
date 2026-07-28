import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/economia_api.dart';
import '../../data/models/precos.dart';
import '../location/location_controller.dart';

/// One scanned barcode → local price range, cheapest offer and nearby stores.
///
/// Watches the location so a CEP set *after* landing on this screen (the
/// ordinary first-scan path) triggers the lookup without a manual retry. A
/// null location resolves to `null` data immediately rather than an error —
/// the screen tells the two apart by reading [locationControllerProvider]
/// itself, same as [ReceiptScreen]'s unpriced state.
final produtoProvider = FutureProvider.autoDispose.family<Precos?, String>((ref, gtin) async {
  final location = ref.watch(locationControllerProvider);
  if (location == null) return null;
  return ref.watch(economiaApiProvider).lookupProduct(gtin, location);
});
