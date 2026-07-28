import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/economia_api.dart';
import '../../data/models/app_location.dart';
import '../../data/models/precos.dart';
import '../location/location_controller.dart';

/// Seeds the "which market am I in?" picker before any product has been
/// scanned. Recomputes whenever the location changes — a CEP set after
/// landing on the screen re-seeds without a manual retry, same pattern as
/// [produtoProvider].
final mercadoSeedProvider = FutureProvider.autoDispose<List<Offer>>((ref) async {
  final location = ref.watch(locationControllerProvider);
  if (location == null) return const [];
  return ref.watch(economiaApiProvider).nearbyStores(location);
});

/// The store to assume the user is standing in until they say otherwise. A
/// precise (GPS) fix is authoritative — it *is* which store you're in, so it
/// wins even over a previously persisted pick. Otherwise the persisted pick
/// stands if it's still among the known [stores]; failing that, nearest.
String? defaultStoreCod(AppLocation location, List<Offer> stores, String? saved) {
  if (stores.isEmpty) return null;
  if (location.precise) return stores.first.cod;
  if (saved != null && stores.any((s) => s.cod == saved)) return saved;
  return stores.first.cod;
}

/// The embedded Mercado scanner emits the same barcode on consecutive frames
/// while the product is still in view. Accept the first hit, then require a
/// different code before handling another camera scan.
bool shouldHandleCameraScan(String digits, String? lastAcceptedDigits) =>
    digits.isNotEmpty && digits != lastAcceptedDigits;
