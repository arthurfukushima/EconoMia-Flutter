/// Brazilian currency ↔ integer cents.
///
/// Every price in this app is an `int` of cents. Doubles are read at the parse
/// boundary and never again — a savings figure assembled from floats is a
/// savings figure that is one rounding error away from being a lie.
///
/// Two source formats reach the app and **must never be crossed**:
///
/// | Source | Looks like | Reader |
/// |---|---|---|
/// | SEFAZ-PR consulta | `"R$ 1.234,56"` | [parseBRL] |
/// | Menor Preço / VTEX | `"3.19"` | [reaisToCents] |
///
/// Feeding `"3.19"` to [parseBRL] yields `31900`, because the dot reads as a
/// thousands separator. That is the failure mode this split exists to prevent.
library;

/// `"R$ 1.234,56"` → `123456`.
///
/// Strips currency symbols, NBSP and letters, drops the thousands dot, then
/// reads the comma as the decimal separator. Anything unparseable is `0` —
/// a missing price is worth nothing, never a crash mid-receipt.
int parseBRL(Object? value) {
  if (value == null) return 0;
  final cleaned = value
      .toString()
      .replaceAll(RegExp(r'[^\d,.-]'), '') // "R$", NBSP, letters
      .replaceAll('.', '') // thousands separator
      .replaceAll(',', '.'); // decimal comma → dot
  final n = double.tryParse(cleaned);
  return n == null ? 0 : (n * 100).round();
}

/// `"3.19"` or `3.19` → `319`. Dot-decimal reais, as Menor Preço returns them.
int reaisToCents(Object? value) {
  if (value == null) return 0;
  if (value is num) return (value * 100).round();
  final n = double.tryParse(value.toString().replaceAll(',', '.'));
  return n == null ? 0 : (n * 100).round();
}

/// `123456` → `"R$ 1.234,56"`.
///
/// Grouping is done by hand rather than through `intl`'s `NumberFormat`: the
/// output is one fixed pt-BR shape, and this keeps the whole money path
/// dependency-free and synchronous (no locale initialisation before a widget
/// can draw a price).
String formatBRL(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  final reais = (abs ~/ 100)
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  final centavos = (abs % 100).toString().padLeft(2, '0');
  return '${sign}R\$ $reais,$centavos';
}

/// A local price spread as "R$X" (min == max) or "R$X – R$Y" — the shape
/// Produto, Mercado and "buscar por nome" all show for a product's region
/// range. `null` (no offers at all) reads as "—".
String formatRangeBRL(int? minCents, int? maxCents) {
  if (minCents == null || maxCents == null) return '—';
  return minCents == maxCents ? formatBRL(minCents) : '${formatBRL(minCents)} – ${formatBRL(maxCents)}';
}
