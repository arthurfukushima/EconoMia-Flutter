import 'package:freezed_annotation/freezed_annotation.dart';

part 'shopping_list.freezed.dart';
part 'shopping_list.g.dart';

/// One named shopping list — "Churrasco", "Casa", "Mês".
///
/// The list's *items* are not in here: they live under their own prefs key per
/// list (`economia.shoppingList.<id>`), so switching lists reads one key and
/// editing a 40-item list never rewrites the index. This is the index entry.
@freezed
abstract class ShoppingList with _$ShoppingList {
  const factory ShoppingList({
    required String id,
    required String name,

    /// Epoch millis. Creation order is the display order — lists are few and
    /// people think of them positionally ("the second one").
    @Default(0) int createdAt,
  }) = _ShoppingList;

  factory ShoppingList.fromJson(Map<String, dynamic> json) => _$ShoppingListFromJson(json);
}
