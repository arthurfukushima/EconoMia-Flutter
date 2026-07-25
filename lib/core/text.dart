/// Text normalisation shared by category matching, weekday-trend grouping and
/// the store picker's filter. One copy of the rules, mirroring the backend's
/// `src/lib/text.js` so client and server agree on what two strings being
/// "the same" means.
library;

// Dart has no Unicode normalisation in core (no `String.normalize('NFD')`), and
// pulling a package in for it would be a dependency for one line. pt-BR uses a
// closed set of accents, so a translation table covers it. Anything outside the
// table is caught by the `[^A-Z0-9 ]` sweep below and becomes a space — worse
// than dropping the diacritic (it splits the token) but never wrong output.
const _accented = 'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑÝ';
const _plain = 'AAAAAEEEEIIIIOOOOOUUUUCNY';

/// Uppercase, unaccented, punctuation-free, single-spaced.
///
/// `"Pão de Açúcar 500g"` → `"PAO DE ACUCAR 500G"`.
String norm(String? s) {
  var out = (s ?? '').toUpperCase();
  for (var i = 0; i < _accented.length; i++) {
    out = out.replaceAll(_accented[i], _plain[i]);
  }
  return out
      .replaceAll(RegExp('[^A-Z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Tokens dropped when reducing a store's razão social to its distinctive name.
/// Every supermarket in Paraná is a "COMERCIO DE ALIMENTOS LTDA"; what tells
/// them apart is the one word left after these go.
const _storeStop = {
  'IRMAOS', 'CIA', 'LTDA', 'ME', 'EPP', 'EIRELI', 'EIRELLI', 'COMERCIO', 'COM',
  'SUPERMERCADO', 'SUPERMERCADOS', 'MERCADO', 'SUPER', 'ATACADO', 'ATACAREJO',
  'DISTRIBUIDORA', 'E', 'DE', 'DO', 'DA', 'DOS', 'DAS', 'SA', 'S', 'A',
};

/// The words that actually identify a chain.
///
/// `"SUPERMERCADOS MUFFATO E CIA LTDA"` → `["MUFFATO"]`, which is what lets two
/// branches of the same chain be recognised as one store.
List<String> distinctiveStoreTokens(String? name) => norm(name)
    .split(' ')
    .where((t) => t.length >= 4 && !_storeStop.contains(t))
    .toList();
