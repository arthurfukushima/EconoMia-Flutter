/// Weights, volumes and counts — the one place that knows `500g` and `0,5kg`
/// are the same thing.
///
/// Money has [money.dart] because two source formats must never be crossed;
/// measures have this for the same reason. A shopping list carries *two*
/// unrelated numbers that both look like "2" — how much to buy (an amount) and
/// how big one package is (a size) — and both arrive as free text from a human
/// and as ALL-CAPS noise inside a store's product description
/// (`COCA COLA PET 2L`). Comparing them by string is how a 350ml can gets
/// priced as a 2L bottle.
///
/// Everything is canonicalised on the way in, so the rest of the app compares
/// numbers rather than spellings:
///
/// | Written | Canonical |
/// |---|---|
/// | `500g`, `500 gr`, `0,5kg` | `(0.5, kg)` |
/// | `350ml`, `0.35 l` | `(0.35, L)` |
/// | `12un`, `c/12`, `dúzia` | `(12, un)` |
library;

/// A quantity with a unit, always in canonical units: `kg`, `L` or `un`.
///
/// There is no gram or millilitre variant on purpose — a `Measure` that could
/// be either `(500, g)` or `(0.5, kg)` would need every comparison to
/// re-normalise, which is exactly the bug this type exists to prevent.
/// [formatMeasure] puts the grams back for display.
typedef Measure = ({double value, String unit});

/// Everything people write for a unit of measure, mapped to its canonical unit
/// and the factor to get there. Longest spellings first — `litros` must be
/// tried before `l`, or `2 litros` parses as `2 l` with `itros` left over.
const _unitAliases = <String, ({String unit, double factor})>{
  'quilos': (unit: 'kg', factor: 1),
  'quilo': (unit: 'kg', factor: 1),
  'kgs': (unit: 'kg', factor: 1),
  'kg': (unit: 'kg', factor: 1),
  'gramas': (unit: 'kg', factor: 0.001),
  'grama': (unit: 'kg', factor: 0.001),
  'grs': (unit: 'kg', factor: 0.001),
  'gr': (unit: 'kg', factor: 0.001),
  'gs': (unit: 'kg', factor: 0.001),
  'g': (unit: 'kg', factor: 0.001),
  'litros': (unit: 'L', factor: 1),
  'litro': (unit: 'L', factor: 1),
  'lts': (unit: 'L', factor: 1),
  'lt': (unit: 'L', factor: 1),
  'l': (unit: 'L', factor: 1),
  'mls': (unit: 'L', factor: 0.001),
  'ml': (unit: 'L', factor: 0.001),
  'unidades': (unit: 'un', factor: 1),
  'unidade': (unit: 'un', factor: 1),
  'unid': (unit: 'un', factor: 1),
  'und': (unit: 'un', factor: 1),
  'un': (unit: 'un', factor: 1),
};

/// The alternation used inside every measure pattern, longest-first so `ml`
/// beats `l` and `kg` beats `g`.
final _unitAlt = (_unitAliases.keys.toList()..sort((a, b) => b.length.compareTo(a.length)))
    .join('|');

/// A number plus a unit, anywhere in a string. `\b` on both ends so the `g` in
/// `MARGARINA` is not a gram and `2LT` is not `2L` with a stray `T`.
final _measure = RegExp(
  r'(?<![\w,.])(\d+(?:[.,]\d+)?)\s*(' + _unitAlt + r')\b',
  caseSensitive: false,
);

/// `12un`, `c/ 12`, `com 12`, `leve 12` — a pack count, which carries a number
/// but often no unit at all.
final _packCount = RegExp(
  r'(?:\bc/\s*|\bcom\s+|\bleve\s+|\bpack\s+)(\d{1,3})\b|\b(\d{1,3})\s*(?:un|und|unid|unidades?)\b',
  caseSensitive: false,
);

final _duzia = RegExp(r'\bd[uú]zia', caseSensitive: false);

/// Reads one measure out of [s], canonicalised. Null when there isn't one.
///
/// Takes the **first** match: a product description is written
/// "size then noise" far more often than the reverse, and a lexicon size
/// string (`"2L"`) only ever has one.
Measure? parseMeasure(String? s) {
  final m = s == null ? null : _measure.firstMatch(s);
  return m == null ? null : _fromMatch(m);
}

/// Every measure in [s], canonicalised — a product description can carry two
/// (`REFRI 2L LEVE 3`), and only one of them may be the one being looked for.
List<Measure> parseMeasures(String? s) => s == null
    ? const []
    : [for (final m in _measure.allMatches(s)) ?_fromMatch(m)];

/// Group 1 is the number, group 2 the unit spelling — the shape every pattern
/// built on [_unitAlt] has.
Measure? _fromMatch(RegExpMatch m) {
  final n = double.tryParse(m[1]!.replaceAll(',', '.'));
  if (n == null) return null;
  final alias = _unitAliases[m[2]!.toLowerCase()]!;
  // Rounded, because `350 * 0.001` is 0.35000000000000003 in binary floating
  // point and this value is both displayed and persisted. Six places is far
  // finer than any package is labelled.
  return (value: _round6(n * alias.factor), unit: alias.unit);
}

double _round6(double v) => (v * 1e6).roundToDouble() / 1e6;

/// Every pack count in [s]: `12UN`, `C/12`, `LEVE 6`, and `DÚZIA` as 12.
///
/// Separate from [parseMeasures] because a count is not a measure of anything —
/// `OVO BRANCO 12UN` is one carton, not twelve of something to be multiplied.
List<int> parsePackCounts(String? s) {
  if (s == null) return const [];
  final out = <int>[
    for (final m in _packCount.allMatches(s)) ?int.tryParse(m[1] ?? m[2] ?? ''),
  ];
  if (_duzia.hasMatch(s)) out.add(12);
  return out;
}

/// Whether two measures are the same size, within 1%.
///
/// Tolerance rather than equality because the same bottle is tagged `2L`,
/// `2000ML` and `2.0 L` by three different stores, and 0.001 of rounding
/// must not make them different products.
bool measureNear(Measure a, Measure b) =>
    a.unit == b.unit && (a.value - b.value).abs() <= b.value.abs() * 0.01 + 1e-9;

/// Whether [text] (a store's product description) advertises size [m].
bool textHasMeasure(String? text, Measure m) {
  if (m.unit == 'un') return parsePackCounts(text).any((c) => (c - m.value).abs() < 0.5);
  return parseMeasures(text).any((found) => measureNear(found, m));
}

/// pt-BR, and grams/millilitres back for anything under one: `0,5 kg` reads as
/// a calculation, `500 g` reads as a package.
String formatMeasure(Measure m) {
  if (m.unit == 'un') return '${_num(m.value)}un';
  final small = m.value < 1;
  final value = small ? m.value * 1000 : m.value;
  final unit = small ? (m.unit == 'kg' ? 'g' : 'ml') : m.unit;
  return '${_num(value)}$unit';
}

/// Trims a trailing `,0` and uses a comma — `2` not `2.0`, `1,5` not `1.5`.
String _num(double v) {
  final s = v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
  return (s.contains('.') ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '') : s)
      .replaceAll('.', ',');
}
