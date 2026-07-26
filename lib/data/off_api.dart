import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'models/nutrition.dart';

final offApiProvider = Provider<OffApi>((ref) {
  final api = OffApi();
  ref.onDispose(api.close);
  return api;
});

/// One scanned barcode's Open Food Facts entry, or null when the product
/// isn't in the database — a miss is normal (crowdsourced coverage; many
/// Brazilian items are absent), never surfaced as an error.
final nutritionProvider = FutureProvider.autoDispose.family<Nutrition?, String>(
  (ref, gtin) => ref.watch(offApiProvider).lookup(gtin),
);

/// Per-100g nutrients surfaced, in display order: (`nutriments` key, label, unit).
const _nutrientFields = [
  ('energy-kcal', 'Energia', 'kcal'),
  ('carbohydrates', 'Carboidratos', 'g'),
  ('sugars', 'Açúcares', 'g'),
  ('proteins', 'Proteínas', 'g'),
  ('fat', 'Gorduras', 'g'),
  ('saturated-fat', 'Gord. saturadas', 'g'),
  ('fiber', 'Fibras', 'g'),
  ('sodium', 'Sódio', 'g'),
];

/// Open Food Facts lookup by barcode — a data source wholly independent of
/// the pricing spine (`/api/*`): a different host, no auth, and its own
/// response shape, so it gets its own tiny client rather than [ApiClient]'s
/// `{error: "<code>"}` contract. [Nutrition] has no `fromJson` to match
/// against because the mapping below isn't a passthrough — it also handles
/// the `_pt` field fallback and reshapes `nutriments` into [NutrientValue]s.
class OffApi {
  OffApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _base = 'https://world.openfoodfacts.org/api/v2/product';
  static const _fields = 'product_name,product_name_pt,brands,quantity,ingredients_text,'
      'ingredients_text_pt,nutriments,nutriscore_grade,nova_group';

  /// Never throws: a network failure, a 404, and a genuinely absent product
  /// all mean the same thing to the caller — no nutrition info to show.
  Future<Nutrition?> lookup(String gtin) async {
    try {
      final uri = Uri.parse('$_base/$gtin.json').replace(queryParameters: {'fields': _fields});
      final res = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (json['status'] != 1) return null; // 0 = not found
      final product = json['product'] as Map<String, dynamic>?;
      if (product == null) return null;

      final n = (product['nutriments'] as Map<String, dynamic>?) ?? const {};
      final nutrients = <NutrientValue>[];
      for (final (key, label, unit) in _nutrientFields) {
        final value = n['${key}_100g'];
        if (value is num) nutrients.add(NutrientValue(label: label, unit: unit, value: value.toDouble()));
      }

      final name = (product['product_name_pt'] as String?) ?? (product['product_name'] as String?) ?? '';
      final ingredients =
          (product['ingredients_text_pt'] as String?) ?? (product['ingredients_text'] as String?) ?? '';
      // A hit with neither a name, ingredients, nor any nutrient is just noise.
      if (name.isEmpty && ingredients.isEmpty && nutrients.isEmpty) return null;

      return Nutrition(
        name: name,
        brands: (product['brands'] as String?) ?? '',
        quantity: (product['quantity'] as String?) ?? '',
        ingredients: ingredients,
        nutriscore: (product['nutriscore_grade'] as String?) ?? '',
        nova: (product['nova_group'] as num?)?.toInt(),
        nutrients: nutrients,
      );
    } catch (_) {
      return null;
    }
  }

  void close() => _client.close();
}
