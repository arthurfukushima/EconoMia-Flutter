import 'package:freezed_annotation/freezed_annotation.dart';

part 'nutrition.freezed.dart';

/// One per-100g/ml nutrient row: "Energia · 52 kcal".
///
/// No JSON codec — [OffApi] maps Open Food Facts' raw `nutriments` shape onto
/// this by hand (see its own doc comment for why), so there is no matching
/// wire shape for `fromJson` to round-trip.
@freezed
abstract class NutrientValue with _$NutrientValue {
  const factory NutrientValue({
    required String label,
    required String unit,
    required double value,
  }) = _NutrientValue;
}

/// One product's Open Food Facts entry — Nutri-Score, NOVA group, ingredients
/// and the per-100g nutrient table. Shared by Produto (always visible) and
/// Mercado (inside a collapsible), independent of the pricing spine.
@freezed
abstract class Nutrition with _$Nutrition {
  const factory Nutrition({
    @Default('') String name,
    @Default('') String brands,
    @Default('') String quantity,
    @Default('') String ingredients,

    /// `a`–`e`, lowercase, or `''` when Open Food Facts has none on file.
    @Default('') String nutriscore,

    /// `1`–`4` (unprocessed → ultra-processed), or null when absent.
    int? nova,
    @Default(<NutrientValue>[]) List<NutrientValue> nutrients,
  }) = _Nutrition;
}
