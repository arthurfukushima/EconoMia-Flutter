/// Free-text shopping list → items. "4x Tomates", "1.5kg Carne", "Toddy".
///
/// The whole point is that nobody is asked to fill in a quantity field: they jot
/// the line the way they'd write it on paper and a quantity/unit prefix is
/// lifted off the front if one is there. Everything after the prefix is the
/// search term.
///
/// Pure, and deliberately id-less — [parseInput] returns records, and the
/// controller stamps ids on them. A `parseItem` that reached for a random
/// generator could not be tested by calling it.
library;

/// One parsed line. [unit] is `un` | `kg` | `L`.
///
/// Only `kg` drives a per-KG price search; `un` and `L` match either basis,
/// because packaged goods are priced per unit in the upstream data. [raw] is
/// kept so the row can always show what the user actually typed.
typedef ParsedLine = ({String raw, String name, double qty, String unit});

/// `1.5kg`, `500 g`, `2l`, `300ml` — a number plus a unit of measure.
final _qtyUnit = RegExp(
  r'^(\d+(?:[.,]\d+)?)\s*(kg|g|l|lt|litros?|ml)\b\.?\s*',
  caseSensitive: false,
);

/// `4x `, `4 x `.
final _qtyTimes = RegExp(r'^(\d+)\s*x\s*', caseSensitive: false);

/// A bare leading count: `4 Tomates`.
final _qtyBare = RegExp(r'^(\d+)\s+');

/// Pulls an optional quantity/unit prefix off one line.
///
/// Grams and millilitres map to `un`, not to `kg`/`L`: "500g Café" is a packaged
/// product sold by the unit, and searching it per-KG would compare a 500g pack
/// against a price per kilo. That is the same UN-vs-KG trap the receipt path
/// guards, arriving from the other direction.
///
/// A line that is *only* a quantity ("2kg") keeps the raw text as its name —
/// a nameless item cannot be priced, but it can still be checked off, and
/// silently dropping what someone typed is worse.
ParsedLine parseItem(String raw) {
  final s = raw.trim();
  var qty = 1.0;
  var unit = 'un';
  var rest = s;

  final measured = _qtyUnit.firstMatch(s);
  if (measured != null) {
    qty = double.parse(measured[1]!.replaceAll(',', '.'));
    final u = measured[2]!.toLowerCase();
    unit = u == 'kg' ? 'kg' : (u.startsWith('l') ? 'L' : 'un');
    rest = s.substring(measured[0]!.length);
  } else {
    final counted = _qtyTimes.firstMatch(s) ?? _qtyBare.firstMatch(s);
    if (counted != null) {
      qty = double.parse(counted[1]!);
      rest = s.substring(counted[0]!.length);
    }
  }

  final name = rest.trim();
  return (raw: s, name: _capitalize(name.isEmpty ? s : name), qty: qty, unit: unit);
}

/// First letter uppercased, the rest left alone — "tomates" → "Tomates", but
/// "TOMATES" and "pão DE queijo" keep the casing they were typed in. The row
/// shows [ParsedLine.raw] verbatim anyway; this is only the search name.
String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// A leading bullet or dash: `•`, `-`, `–`, `*`, … Also matches NBSP as
/// whitespace, which is what a paste out of Notes/Word/PDF actually contains.
final _bullet = RegExp(r'^[\s ]*[•●◦▪·‣∙\-–—*]+[\s ]*');

/// Leading numbering — "1. " or "1) ". Requires the trailing space so a bare
/// count ("4 Tomates") stays a *quantity* for [parseItem] rather than being
/// stripped as a list marker.
final _numbering = RegExp(r'^\s*\d+[.)]\s+');

/// Runs of whitespace, NBSP and tabs included.
final _spaces = RegExp(r'[\s ]+');

/// Strips the decoration a pasted list carries so [parseItem] sees a clean
/// "qty unit name" line instead of "•  12 Pães".
String _sanitizeLine(String s) => s
    .replaceFirst(_bullet, '')
    .replaceFirst(_numbering, '')
    .replaceAll(_spaces, ' ')
    .trim();

/// Splits a pasted list on commas or newlines, one item per entry.
///
/// So "4x Tomates, 2x Laranjas, Toddy" can be dumped in one go — the input is a
/// notepad, not a form. Lines are sanitised first: people paste out of Notes,
/// Word and PDFs, and those arrive bulleted, numbered and full of NBSPs.
List<ParsedLine> parseInput(String text) => [
      for (final line in text.split(RegExp(r'[,\n]+')))
        if (_sanitizeLine(line).isNotEmpty) parseItem(_sanitizeLine(line)),
    ];
