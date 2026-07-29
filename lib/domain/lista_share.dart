import '../data/models/list_item.dart';

/// Builds the compact, WhatsApp-friendly representation of a shopping list.
///
/// Prices and cached product metadata intentionally do not appear here: this
/// is the user's list to send to another person, not a price report.
String formatShoppingListForShare({
  required String listName,
  required List<ListItem> items,
}) {
  if (items.isEmpty) return '';

  final title = _singleLine(listName).isEmpty
      ? 'Minha Lista'
      : _singleLine(listName);
  final lines = [
    '🛒 *$title*',
    '',
    for (final item in items)
      '${item.checked ? '☑' : '☐'} ${_quantity(item)} ${_singleLine(item.name)}${_note(item.note)}',
  ];
  return lines.join('\n');
}

String _quantity(ListItem item) =>
    '${_number(item.qty)} ${_singleLine(item.unit)}';

String _number(double value) => value
    .toStringAsFixed(3)
    .replaceFirst(RegExp(r'\.?0+$'), '')
    .replaceAll('.', ',');

String _note(String? note) {
  final value = _singleLine(note ?? '');
  return value.isEmpty ? '' : ' ($value)';
}

String _singleLine(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();
