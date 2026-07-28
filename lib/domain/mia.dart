import '../core/text.dart';
import '../data/models/receipt.dart';

const pointsPerProduct = 10;

/// The note faucet is deliberately based on unique products, not line count.
/// GTIN is the stable identity; weighed/PLU lines use the same fallback as
/// insights so the two parts of the app agree.
int notePoints(Receipt receipt) {
  final keys = <String>{};
  for (final item in receipt.items) {
    keys.add(item.gtin?.trim().isNotEmpty == true ? item.gtin!.trim() : norm(item.description));
  }
  return keys.length * pointsPerProduct;
}
