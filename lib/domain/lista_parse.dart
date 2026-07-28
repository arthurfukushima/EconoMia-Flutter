/// Free-text shopping list → items. "12 Pães", "2,5kg Carne boi", "Refrigerante 2l".
///
/// The whole point is that nobody is asked to fill in a quantity field: they jot
/// the line the way they'd write it on paper, and this pulls it apart. What it
/// pulls out is **three** things, not two:
///
/// | | Question it answers | Example |
/// |---|---|---|
/// | [ParsedLine.qty]/[ParsedLine.unit] | how much am I buying? | `2,5kg Carne` → 2,5 kg |
/// | [ParsedLine.size] | how big is one package? | `Refrigerante 2l` → 2 L |
/// | [ParsedLine.name] | what am I buying? | both → `Carne bovina`, `Refrigerante` |
///
/// Collapsing size into quantity is the bug this file exists to prevent. A size
/// read as a quantity multiplies the line — `500g Mortadela` priced as *500* of
/// something — and a quantity read as a size silently under-counts. Neither is
/// visible to someone reading the total.
///
/// **Syntax alone cannot do this.** `Arroz 5kg` and `Tomate 2kg` are the same
/// sentence; one is a five-kilo bag and the other is two kilos of loose tomato.
/// So the grammar consults [Staples] — a data file of what pt-BR grocery terms
/// are *sold as* — and where even that can't decide, it says so via
/// [ParsedLine.conf] rather than guessing, and the price search settles it later
/// against real product names (`lista_reconcile.dart`).
///
/// **The governing rule for anything still ambiguous: degrade toward `qty 1`.**
/// Never resolve an ambiguity in the direction that multiplies. A line that
/// comes back with no price is honest; a line that comes back 12× too expensive
/// is the failure that ends trust in the app.
///
/// Pure, and deliberately id-less — [parseInput] returns records, and the
/// controller stamps ids on them. A `parseItem` that reached for a random
/// generator could not be tested by calling it.
library;

import '../core/measure.dart';
import '../core/staples.dart';

/// How much the parser trusts its own reading of a line.
///
/// Not decoration: `medium` and `low` are what put the correction affordance on
/// the row, and `low` is what `lista_reconcile.dart` is allowed to overrule.
abstract final class ParseConf {
  /// Unambiguous. `2,5kg Carne`, `Alface`, `3 Leites`.
  static const high = 'high';

  /// A defensible reading with a real alternative. `12 Pães` (twelve rolls,
  /// priced per kilo — so *about* a kilo), `Refrigerante 2l`.
  static const medium = 'medium';

  /// Genuinely undecidable offline. `12 Ovos`: twelve eggs, or the carton of
  /// twelve that every market actually sells?
  static const low = 'low';
}

/// One parsed line.
///
/// [unit] is `un` | `kg` | `L` and answers *how much to buy*. [size] is the
/// package the user asked for and never multiplies anything — it steers which
/// of a search's candidate products the line is priced as. [raw] is kept so the
/// row can always show what the user actually typed.
typedef ParsedLine = ({
  String raw,
  String name,
  double qty,
  String unit,
  Measure? size,
  String conf,
  String? note,
});

// ---------------------------------------------------------------------------
// Patterns
// ---------------------------------------------------------------------------

/// A number in any of the shapes a person writes one: `2`, `1,5`, `1.5`, `1/2`,
/// `½`. Kept as one alternation so every quantity pattern accepts all of them.
const _n = r'(\d+/\d+|\d+(?:[.,]\d+)?|[½¼¾])';

/// The unit spellings [parseMeasure] understands, as an alternation. Duplicated
/// from `core/measure.dart` rather than exported: the patterns here need it
/// *inline*, and a single shared string that both files build regexes out of
/// would couple two very different jobs.
const _u = r'kgs?|quilos?|gramas?|grs?|gs|g|litros?|lts?|l|mls?|ml';

/// `1,5kg …`, `500 g …`, `2l …` — a measure the line *opens* with.
final _measurePrefix = RegExp('^$_n' r'\s*(' '$_u' r')\b\.?\s*(?:de\s+)?',
    caseSensitive: false);

/// `… 2kg`, `… 2l` — a measure the line *ends* with.
final _measureSuffix = RegExp('(?:^|\\s)$_n' r'\s*(' '$_u' r')\.?$',
    caseSensitive: false);

/// A measure sitting in the middle: `Leite 1L integral`. Always a package size —
/// it is inside the product's own name.
final _measureAny = RegExp('(?<![\\w,.])$_n' r'\s*(' '$_u' r')\b',
    caseSensitive: false);

/// `3 cx `, `2 pct `, `1 fardo de ` — a count of packages. The container word
/// itself is thrown away; what matters is that the number counts *packages*.
final _containerPrefix = RegExp(
  '^$_n'
  r'\s*(?:cx|caixas?|pct|pacotes?|fardos?|packs?|latas?|garrafas?|potes?'
  r'|sacos?|sc|bandejas?|vidros?|tabletes?|barras?|unid(?:ades?)?|und|un|pç|peças?)'
  r'\b\.?\s*(?:de\s+)?',
  caseSensitive: false,
);

/// `2 dz `, `meia dúzia de ` — twelve per dozen, resolved to a plain count so
/// it takes the same path as `12 Ovos`.
final _duziaPrefix =
    RegExp('^$_n' r'\s*d(?:z|[uú]zias?)\b\.?\s*(?:de\s+)?', caseSensitive: false);

/// `4x `, `4 x `. The lookahead keeps `3x mais` (a detergent's concentration
/// claim, not a quantity) out.
final _timesPrefix =
    RegExp(r'^(\d+)\s*x\s+(?!mais|maior|menos|melhor)', caseSensitive: false);

/// A bare leading count: `12 Pães`.
final _barePrefix = RegExp(r'^(\d+)\s+');

/// `R$ 20 de carne`, `20 reais de picanha` — buying by money value, which is
/// common here and which no price lookup can honour. The marker (`R$` or
/// `reais`) is required: a bare `20 de arroz` is not clearly money.
final _money = RegExp(
  r'^(?:r\$\s*' '$_n' r'|' '$_n' r'\s*(?:reais|real|conto|pila)s?)\s*(?:de|em)\s+',
  caseSensitive: false,
);

/// `meio quilo`, `meia dúzia`, `um litro`, `duas caixas` — spelled numbers, but
/// only in front of a unit word, so a product actually named "Uma…" survives.
final _spelled = RegExp(
  r'^(um|uma|dois|duas|tr[êe]s|quatro|cinco|seis|meia|meio)\s+'
  r'(?=(?:' '$_u' r'|d[uú]zias?|dz|cx|caixas?|pct|pacotes?|garrafas?|latas?|potes?)\b)',
  caseSensitive: false,
);

const _spelledValues = {
  'um': '1', 'uma': '1', 'dois': '2', 'duas': '2', 'três': '3', 'tres': '3',
  'quatro': '4', 'cinco': '5', 'seis': '6', 'meia': '0,5', 'meio': '0,5',
};

/// A parenthetical or a trailing " - …": the shopper's own note. Never part of
/// the search term — `Leite (o do desconto)` has to search for `Leite`.
final _paren = RegExp(r'\s*\(([^)]*)\)\s*');
final _trailingNote = RegExp(r'\s+[-–—]\s+(.+)$');

// ---------------------------------------------------------------------------
// Parsing
// ---------------------------------------------------------------------------

/// Pulls one jotted line apart into what to buy, how much, and how big.
///
/// [staples] is passed as a value, never injected: `domain/` stays pure, and a
/// test can hand it a lexicon of three words to prove one rule. It defaults to
/// [Staples.fallback] rather than to an empty lexicon, because *no* lexicon
/// silently downgrades every weight-sold term to a packaged one — a caller who
/// forgot to pass it would get plausible-looking, wrong answers instead of an
/// error. Pass `const Staples()` to genuinely test the lexicon-less path.
ParsedLine parseItem(String raw, {Staples staples = Staples.fallback}) {
  final line = _sanitizeLine(raw);
  if (line.isEmpty) return _plain(raw.trim(), staples);

  var body = line;
  var conf = ParseConf.high;
  String? note;

  // Notes first: they can hold digits ("(leve 2)") that must not be read as a
  // quantity, and they are never part of what to search for.
  (body, note) = _liftNotes(body);

  // Money next, before any digit-reading rule can eat the amount.
  final money = _money.firstMatch(body);
  if (money != null) {
    note = _joinNote(note, 'R\$ ${money[1] ?? money[2]}');
    body = body.substring(money.end);
    conf = ParseConf.medium;
  }

  body = _expandSpelled(body);
  if (body.trim().isEmpty) return _plain(line, staples, note: note);

  // --- Locate the numbers, without deciding what they mean yet. -------------
  final prefix = _measurePrefix.firstMatch(body);
  final suffix = prefix == null ? _measureSuffix.firstMatch(body) : null;
  final measured = prefix ?? suffix;

  // A leading count only counts when a measure didn't already claim the front.
  final count = prefix != null ? null : _leadingCount(body, staples);

  // Everything the numbers occupy comes out of the search term. Cut back to
  // front, so removing one span can't move the next one's offsets.
  final spans = <({int start, int end})>[
    if (measured != null) (start: measured.start, end: measured.end),
    if (count != null) (start: count.start, end: count.end),
  ]..sort((a, b) => b.start.compareTo(a.start));
  var head = body;
  for (final span in spans) {
    head = _cut(head, span.start, span.end);
  }

  // Any *other* measure is inside the product's own name ("Leite 1L integral").
  final embedded = _measureAny.firstMatch(head);
  if (embedded != null) head = _cut(head, embedded.start, embedded.end);

  // --- Now name it, because naming is what makes the numbers decidable. -----
  final name = _searchName(head.isEmpty ? body : head, staples);
  final staple = staples.lookup(name);

  var qty = 1.0;
  var unit = (staple?.soldByWeight ?? false) ? 'kg' : 'un';
  Measure? size = embedded == null ? null : _measureOf(embedded);
  if (embedded != null) conf = _lower(conf, ParseConf.medium);

  if (measured != null) {
    final m = _measureOf(measured)!;
    if (_isAmount(m, staple)) {
      qty = m.value;
      unit = m.unit;
      // A weight the lexicon didn't vouch for is the safe default, not a
      // certainty — "500g Patê" could be a deli slice or a sealed tub.
      if (staple == null) conf = _lower(conf, ParseConf.medium);
    } else {
      size ??= m;
      conf = _lower(conf, ParseConf.medium);
    }
  } else if (count != null) {
    (qty, unit, size, conf) = _readCount(count, staple, size, conf);
  }

  return (
    raw: line,
    name: name.isEmpty ? line : name,
    qty: qty,
    unit: unit,
    size: size,
    conf: conf,
    note: note,
  );
}

/// Is this measure *how much to buy*, or *how big one package is*?
///
/// - An explicit count (`12un`) is always a package size — nobody writes "un"
///   to mean "buy this many kilos".
/// - A volume is essentially always a package size. Brazilian markets sell
///   milk, soda and detergent in bottles; almost nothing is ladled out by the
///   loose litre.
/// - A weight is an amount **unless** the lexicon knows the product comes in
///   bags. `Tomate 2kg` is two kilos of tomato; `Arroz 5kg` is one five-kilo
///   bag. Unknown terms fall to *amount*, which is the safe side: the words
///   this lexicon is most likely to be missing are açougue and hortifruti cuts,
///   and those really are sold by weight.
bool _isAmount(Measure m, Staple? staple) {
  if (m.unit == 'un') return false;
  if (m.unit == 'L') return false;
  return staple == null || staple.soldByWeight;
}

/// What a bare count means once the product is known.
///
/// Three outcomes, and the awkward one in the middle is deliberate:
///
/// - **Sold by weight** (`12 Pães`, `6 Laranjas`) — you cannot buy twelve of
///   something priced per kilo. Multiplying a per-kilo price by twelve is the
///   catastrophic direction, so the count becomes a size hint and the line
///   stands at *one kilo*: a plausible number, marked `medium` so the row
///   offers a correction. Approximate on purpose.
/// - **A number that matches a real pack** (`12 Ovos`, `12 Papel higiênico`) —
///   almost certainly one carton, not twelve cartons. Takes the non-multiplying
///   reading and marks itself `low`, which is the reconciler's licence to
///   confirm or revert it against what the shops actually stock.
/// - **Anything else** (`3 Leites`, `2 Manteigas`) — an ordinary count.
(double, String, Measure?, String) _readCount(
    _Count count, Staple? staple, Measure? size, String conf) {
  final n = count.value;
  // A dozen names its own package. Nothing left to infer.
  if (count.pack != null) return (n, 'un', size ?? count.pack, conf);
  if (staple?.soldByWeight ?? false) {
    return (1, 'kg', size ?? (value: n, unit: 'un'), _lower(conf, ParseConf.medium));
  }
  // Only a *bare* number is ambiguous. Someone who wrote "4x" or "3 cx" already
  // said they meant a count, and re-reading that as a pack size would be
  // overruling them.
  if (!count.explicit && (staple?.packs.contains(n.round()) ?? false)) {
    return (1, 'un', size ?? (value: n, unit: 'un'), ParseConf.low);
  }
  // Nobody buys 500 lettuces: a number that large was part of the name.
  if (n > 99) return (1, 'un', size, ParseConf.low);
  return (n, 'un', size, conf);
}

/// A leading count.
///
/// [explicit] separates "the user said how many" (`4x`, `3 cx`) from "there was
/// a number in front" (`12 Ovos`) — only the second is open to reinterpretation.
/// [pack] is set when the spelling itself names a package, which only a dozen
/// does.
typedef _Count = ({double value, Measure? pack, bool explicit, int start, int end});

_Count? _leadingCount(String body, Staples staples) {
  final duzia = _duziaPrefix.firstMatch(body);
  if (duzia != null) {
    final n = _num(duzia[1]!);
    if (n != null) {
      // "2 dúzias" is two cartons of twelve; "meia dúzia" is one of six.
      return (
        value: n < 1 ? 1 : n,
        pack: (value: n < 1 ? 12 * n : 12, unit: 'un'),
        explicit: true,
        start: duzia.start,
        end: duzia.end,
      );
    }
  }
  final container = _containerPrefix.firstMatch(body);
  if (container != null) {
    final n = _num(container[1]!);
    if (n != null) {
      return (
        value: n,
        pack: null,
        explicit: true,
        start: container.start,
        end: container.end,
      );
    }
  }
  final times = _timesPrefix.firstMatch(body);
  if (times != null) {
    return (
      value: double.parse(times[1]!),
      pack: null,
      explicit: true,
      start: times.start,
      end: times.end,
    );
  }
  // A brand that opens with a digit is not a quantity: "3 Corações Café" is a
  // coffee, and eating the 3 leaves a search term that matches nothing.
  if (staples.startsWithBrand(body)) return null;
  final bare = _barePrefix.firstMatch(body);
  if (bare == null) return null;
  // "12" on its own is not a shopping list line; keep it as the name.
  if (body.substring(bare.end).trim().length < 2) return null;
  return (
    value: double.parse(bare[1]!),
    pack: null,
    explicit: false,
    start: bare.start,
    end: bare.end,
  );
}

/// The search term: quantity stripped, plurals collapsed, shorthand expanded.
///
/// Plurals **before** aliases, and aliases exactly once. Both orderings matter:
/// `Refris` only reaches the `refri` alias after it is singular, and running
/// the alias pass twice would rewrite its own output — `Coca` → `coca cola` →
/// `coca cola cola`.
///
/// Accents are **kept**. `norm()` exists for deciding whether two strings mean
/// the same thing; the upstream price data is written with accents, so the
/// query should be too.
String _searchName(String head, Staples staples) {
  final trimmed = head.trim();
  // "3 Corações" is a coffee, not three hearts — a brand is a proper noun and
  // has no plural to collapse.
  final singular = staples.startsWithBrand(trimmed)
      ? trimmed
      : [
          for (final t in trimmed.split(' '))
            if (t.isNotEmpty) staples.singular(t),
        ].join(' ');
  return _capitalize(staples.expandAliases(singular).trim());
}

/// A line with nothing to pull off it — no quantity, no note, just a product.
ParsedLine _plain(String line, Staples staples, {String? note}) {
  final name = _searchName(line, staples);
  return (
    raw: line,
    name: name.isEmpty ? line : name,
    qty: 1,
    unit: staples.lookup(name)?.soldByWeight ?? false ? 'kg' : 'un',
    size: null,
    conf: ParseConf.high,
    note: note,
  );
}

/// Lifts "(…)" and a trailing " - …" out of [body], joined into one note.
(String, String?) _liftNotes(String body) {
  String? note;
  var out = body.replaceAllMapped(_paren, (m) {
    note = _joinNote(note, m[1]!.trim());
    return ' ';
  });
  final trailing = _trailingNote.firstMatch(out);
  if (trailing != null) {
    note = _joinNote(note, trailing[1]!.trim());
    out = out.substring(0, trailing.start);
  }
  return (out.replaceAll(_spaces, ' ').trim(), note);
}

String? _joinNote(String? a, String b) =>
    b.isEmpty ? a : (a == null || a.isEmpty ? b : '$a · $b');

String _expandSpelled(String body) {
  final m = _spelled.firstMatch(body);
  if (m == null) return body;
  final value = _spelledValues[m[1]!.toLowerCase()];
  return value == null ? body : '$value ${body.substring(m.end)}';
}

Measure? _measureOf(RegExpMatch m) {
  final n = _num(m[1]!);
  return n == null ? null : parseMeasure('$n${m[2]}'.replaceAll(',', '.'));
}

/// `2`, `1,5`, `1.5`, `1/2`, `½` → a double.
double? _num(String s) {
  const vulgar = {'½': 0.5, '¼': 0.25, '¾': 0.75};
  final v = vulgar[s];
  if (v != null) return v;
  if (s.contains('/')) {
    final parts = s.split('/');
    final a = double.tryParse(parts[0]);
    final b = double.tryParse(parts[1]);
    return a == null || b == null || b == 0 ? null : a / b;
  }
  return double.tryParse(s.replaceAll(',', '.'));
}

String _cut(String s, int start, int end) =>
    '${s.substring(0, start)} ${s.substring(end)}'.replaceAll(_spaces, ' ').trim();

/// Confidence only ever falls. Two `medium` reasons on one line don't add up to
/// `low`, but a `low` reason anywhere wins.
String _lower(String a, String b) {
  const rank = {ParseConf.high: 2, ParseConf.medium: 1, ParseConf.low: 0};
  return rank[a]! <= rank[b]! ? a : b;
}

/// First letter uppercased, the rest left alone — "tomates" → "Tomates", but
/// "TOMATES" and "pão DE queijo" keep the casing they were typed in. The row
/// shows [ParsedLine.raw] verbatim anyway; this is only the search name.
String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ---------------------------------------------------------------------------
// Splitting a pasted list
// ---------------------------------------------------------------------------

/// How a **store's own** product name should be priced, and what size it is.
///
/// Not [parseItem]: a catalog description is a whole product name, not a jotted
/// line, and running the grammar over "1KG ARROZ TIO JOÃO" would read the
/// leading packaging token as a quantity and eat it.
///
/// The basis hinges on whether the `KG` has a number stuck to it.
/// `CARNE BOVINA KG` is weighed at the counter; `ARROZ TIO JOÃO 1KG` is a
/// one-kilo bag with a per-package price, and asking for a per-KG basis on it
/// compares a bag to a kilo.
({String unit, Measure? size}) readCatalogName(String description) {
  final size = parseMeasure(description);
  final withoutSizes = description.replaceAll(_measureAny, ' ');
  final perKg = RegExp(r'\bkgs?\b', caseSensitive: false).hasMatch(withoutSizes);
  return (unit: perKg ? 'kg' : 'un', size: perKg ? null : size);
}

/// A leading bullet or dash: `•`, `-`, `–`, `*`, … Also matches NBSP as
/// whitespace, which is what a paste out of Notes/Word/PDF actually contains.
final _bullet = RegExp(r'^[\s ]*[•●◦▪·‣∙\-–—*]+[\s ]*');

/// Leading numbering — "1. " or "1) ". Requires the trailing space so a bare
/// count ("12 Pães") stays a *quantity* rather than being stripped as a marker.
final _numbering = RegExp(r'^\s*\d+[.)]\s+');

/// A checkbox from whatever app the list was written in first.
final _checkbox = RegExp(r'^[\s ]*(?:\[\s*[xX✓✔]?\s*\]|[☐☑☒✅✔❏])[\s ]*');

/// Emoji at either end of a line. Only at the ends: a `🍞` someone typed *into*
/// a product name is theirs to keep, and stripping mid-string would split it.
final _edgeEmoji = RegExp(
  r'^[\u{1F300}-\u{1FAFF}\u{2190}-\u{21FF}\u{2600}-\u{27BF}\u{FE0F}\u{2B00}-\u{2BFF}\s]+'
  r'|[\u{1F300}-\u{1FAFF}\u{2190}-\u{21FF}\u{2600}-\u{27BF}\u{FE0F}\u{2B00}-\u{2BFF}\s]+$',
  unicode: true,
);

/// Runs of whitespace, NBSP and tabs included.
final _spaces = RegExp(r'[\s ]+');

/// Unicode formatting characters: zero-width spaces and joiners, the bidi
/// embeddings and isolates, soft hyphen, the BOM.
///
/// These have to go **first**, before any other rule looks at the line. They
/// are category `Cf`, not whitespace, so neither `\s` nor a hand-written space
/// class matches them in Dart — and they are invisible, so nobody can see why
/// their list stopped working.
///
/// This is not hypothetical: WhatsApp writes a WORD JOINER (U+2060) after the
/// bullet *and* immediately before the text of every line it copies. It
/// survived the bullet strip and sat between the margin and the digits, so
/// `12 Pães` was no longer a line that began with a number and every quantity
/// in a pasted list silently became part of the product name. Typing the same
/// line by hand inserts nothing and worked fine, which is what made it look
/// like a bulk-paste problem rather than one invisible character.
final _formatting = RegExp(
  // Soft hyphen, arabic letter mark, mongolian vowel separator, the
  // zero-width family plus LRM/RLM, the bidi embeddings and overrides,
  // WORD JOINER and the invisible operators, the bidi isolates, and the BOM.
  r'[\u00AD\u061C\u180E\u200B-\u200F\u202A-\u202E\u2060-\u206F\uFEFF]',
);

/// Strips the decoration a pasted list carries so [parseItem] sees a clean
/// "qty unit name" line instead of "•  ☑ 12 Pães 🍞".
String _sanitizeLine(String s) => s
    .replaceAll(_formatting, '')
    .replaceFirst(_bullet, '')
    .replaceFirst(_checkbox, '')
    .replaceFirst(_numbering, '')
    .replaceAll(_edgeEmoji, '')
    .replaceAll(_spaces, ' ')
    .trim();

/// Splits on newlines, semicolons, pipes — and commas, **except** a comma
/// between two digits, which is a decimal separator here and not punctuation.
/// Getting that wrong turns a pasted "1,5kg Carne" into two items, one of them
/// named "1".
///
/// " e " is deliberately not a separator: "molho de tomate e manjericão" is one
/// product, and there is no cheap way to tell it from "pão e leite".
final _separators = RegExp(r'\n+|[;|]+|(?<!\d),(?!\d)');

/// Splits a pasted list, one item per entry.
///
/// So a whole list can be dumped in one go — the input is a notepad, not a
/// form. Lines are sanitised first: people paste out of Notes, WhatsApp, Word
/// and PDFs, and those arrive bulleted, numbered, ticked and full of NBSPs.
List<ParsedLine> parseInput(String text, {Staples staples = Staples.fallback}) => [
      // Formatting characters come out *before* the split, not just per line:
      // the decimal-comma guard below is a lookaround on digits, and an
      // invisible character wedged between the `1` and the `,5` would hide the
      // digit from it and cut "1,5kg Carne" in half again.
      for (final line in text.replaceAll(_formatting, '').split(_separators))
        if (_sanitizeLine(line).isNotEmpty) parseItem(line, staples: staples),
    ];
