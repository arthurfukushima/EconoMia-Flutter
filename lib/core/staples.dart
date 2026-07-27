import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'measure.dart';
import 'text.dart';

/// What pt-BR grocery words *mean*, which is the one thing a parser cannot
/// derive from syntax.
///
/// `Arroz 5kg` and `Tomate 2kg` are the same sentence. One is a five-kilo bag
/// (buy one) and the other is two kilos of loose tomato (buy two). Nothing in
/// the grammar distinguishes them — only knowing that rice comes in bags and
/// tomatoes come by weight does. That knowledge is this file, and it is data
/// rather than code so it can be corrected without a release-shaped change.
///
/// Loaded from `assets/data/staples.json` exactly the way `AppConfig` loads its
/// own JSON, including the compile-time [fallback]: a missing or unbundled
/// asset degrades to a smaller lexicon, never to a crash. A **malformed** one
/// still throws at launch — a typo here silently mis-prices a basket, which is
/// far worse than failing loudly.
class Staples {
  const Staples({
    this.byKey = const {},
    this.aliases = const {},
    this.brands = const [],
    this.plurals = const {},
  });

  /// Singular, `norm()`-ed term → how it is sold. `'CARNE BOVINA'`, `'OVO'`.
  final Map<String, Staple> byKey;

  /// `norm()`-ed shorthand → what to actually search for, accents and all.
  /// `'PH'` → `'papel higiênico'`.
  final Map<String, String> aliases;

  /// `norm()`-ed brand names that *begin with a digit* — the only ones that
  /// matter, since a leading number is otherwise read as a quantity.
  /// `'3 CORACOES'`, `'51'`.
  final List<String> brands;

  /// Irregular pt-BR plurals that no suffix rule gets right, `norm()`-ed →
  /// accented singular. `'PAES'` → `'pão'`.
  final Map<String, String> plurals;

  /// The lexicon with no asset at all. Deliberately not the whole file: it
  /// covers the terms where being wrong costs *money* — everything sold loose
  /// by the kilo, where mistaking a size for an amount multiplies a line — plus
  /// the packaged staples people most often write a size next to.
  static const fallback = Staples(
    byKey: {
      'TOMATE': Staple.kg, 'CEBOLA': Staple.kg, 'BATATA': Staple.kg,
      'CENOURA': Staple.kg, 'LARANJA': Staple.kg, 'LIMAO': Staple.kg,
      'MACA': Staple.kg, 'BANANA': Staple.kg, 'UVA': Staple.kg,
      'MELANCIA': Staple.kg, 'MAMAO': Staple.kg, 'MANGA': Staple.kg,
      'ALHO': Staple.kg, 'CARNE': Staple.kg, 'CARNE BOVINA': Staple.kg,
      'CARNE MOIDA': Staple.kg, 'FRANGO': Staple.kg, 'PICANHA': Staple.kg,
      'COSTELA': Staple.kg, 'LINGUICA': Staple.kg, 'BACON': Staple.kg,
      'QUEIJO': Staple.kg, 'MUSSARELA': Staple.kg, 'PRESUNTO': Staple.kg,
      'MORTADELA': Staple.kg, 'PEIXE': Staple.kg, 'PAO': Staple.kg,
      'PAO DE QUEIJO': Staple.kg,
      'ALFACE': Staple.un, 'REPOLHO': Staple.un, 'BROCOLIS': Staple.un,
      'BOLO': Staple.un, 'SUCO': Staple.un, 'GELEIA': Staple.un,
      'NUTELLA': Staple.un, 'PRINGLES': Staple.un, 'TODDY': Staple.un,
      'MANTEIGA': Staple.un, 'MARGARINA': Staple.un,
      'OVO': Staple(sale: 'un', packs: [6, 10, 12, 20, 30]),
      'PAPEL HIGIENICO': Staple(sale: 'un', packs: [4, 8, 12, 16, 24, 30]),
      'LEITE': Staple(sale: 'un', sizes: [(value: 1, unit: 'L')]),
      'REFRIGERANTE': Staple(sale: 'un', sizes: [
        (value: 0.35, unit: 'L'), (value: 0.6, unit: 'L'),
        (value: 1, unit: 'L'), (value: 2, unit: 'L'), (value: 2.5, unit: 'L'),
      ]),
      'ARROZ': Staple(sale: 'un', sizes: [
        (value: 1, unit: 'kg'), (value: 2, unit: 'kg'), (value: 5, unit: 'kg'),
      ]),
      'FEIJAO': Staple(sale: 'un', sizes: [(value: 1, unit: 'kg')]),
      'ACUCAR': Staple(sale: 'un', sizes: [
        (value: 1, unit: 'kg'), (value: 5, unit: 'kg'),
      ]),
      'CAFE': Staple(sale: 'un', sizes: [
        (value: 0.25, unit: 'kg'), (value: 0.5, unit: 'kg'),
      ]),
      'SABAO EM PO': Staple(sale: 'un', sizes: [
        (value: 0.8, unit: 'kg'), (value: 1, unit: 'kg'),
      ]),
      'DETERGENTE': Staple(sale: 'un', sizes: [(value: 0.5, unit: 'L')]),
      'MOLHO DE TOMATE': Staple(sale: 'un', sizes: [(value: 0.34, unit: 'kg')]),
    },
    aliases: {
      'PH': 'papel higiênico',
      'REFRI': 'refrigerante',
      'COCA': 'coca cola',
      'SABAO ROUPA': 'sabão em pó',
      'SABAO DE ROUPA': 'sabão em pó',
      'CARNE BOI': 'carne bovina',
      'CARNE DE BOI': 'carne bovina',
      'MOLHO TOMATE': 'molho de tomate',
    },
    brands: ['51', '3 CORACOES', '7 BELO', '2 IRMAOS'],
    plurals: {
      'PAES': 'pão', 'LIMOES': 'limão', 'FEIJOES': 'feijão',
      'MELOES': 'melão', 'MAMOES': 'mamão', 'CORACOES': 'coração',
      'PASTEIS': 'pastel', 'PAPEIS': 'papel', 'OVOS': 'ovo',
    },
  );

  static const _asset = 'assets/data/staples.json';

  /// Reads the bundled lexicon. A missing asset is [fallback]; a malformed one
  /// throws, for the same reason `AppConfig` does.
  static Future<Staples> load({AssetBundle? bundle}) async {
    final String raw;
    try {
      raw = await (bundle ?? rootBundle).loadString(_asset);
    } catch (_) {
      return fallback; // not bundled
    }
    try {
      return Staples.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      throw FormatException('$_asset is not a usable staples lexicon: $e');
    }
  }

  factory Staples.fromJson(Map<String, dynamic> json) {
    final staples = (json['staples'] as Map<String, dynamic>?) ?? const {};
    final aliases = (json['aliases'] as Map<String, dynamic>?) ?? const {};
    final plurals = (json['plurals'] as Map<String, dynamic>?) ?? const {};
    final brands = (json['brands'] as List?) ?? const [];
    return Staples(
      byKey: {
        // An entry that is neither the `"kg"` shorthand nor an object is a typo;
        // `?` drops it rather than letting it become a bogus `un`, which would
        // read a size as an amount and multiply the line.
        for (final e in staples.entries) norm(e.key): ?Staple.fromJson(e.value),
      },
      aliases: {for (final e in aliases.entries) norm(e.key): '${e.value}'},
      brands: [for (final b in brands) norm('$b')],
      plurals: {for (final e in plurals.entries) norm(e.key): '${e.value}'},
    );
  }

  /// How [name] is sold, or null when it isn't a term we know.
  ///
  /// Longest contiguous token run wins, so `"molho de tomate"` is a jar (`un`)
  /// and not the tomato (`kg`) hiding inside it. Ties at the same length go
  /// left-to-right — the head of a pt-BR noun phrase is its first word
  /// (`"suco de laranja"` is a juice, not an orange).
  Staple? lookup(String? name) {
    final n = norm(name);
    if (n.isEmpty || byKey.isEmpty) return null;
    final tokens = n.split(' ');
    for (var len = math.min(_maxKeyTokens, tokens.length); len >= 1; len--) {
      for (var i = 0; i + len <= tokens.length; i++) {
        final hit = byKey[tokens.sublist(i, i + len).join(' ')];
        if (hit != null) return hit;
      }
    }
    return null;
  }

  /// Rewrites the shorthand people actually type into something the price
  /// search can match: `"PH"` → `"papel higiênico"`, `"Sabão roupa"` →
  /// `"sabão em pó"`. Untouched tokens keep the casing they arrived in.
  ///
  /// An alias whose expansion is **already there** is skipped, so the pass is
  /// idempotent: `"Coca cola"` stays `"Coca cola"` rather than becoming
  /// `"coca cola cola"`, while `"Coca 600"` still expands.
  String expandAliases(String name) {
    if (aliases.isEmpty) return name;
    final tokens = [for (final t in name.split(' ')) if (t.isNotEmpty) t];
    final out = <String>[];
    var i = 0;
    while (i < tokens.length) {
      var taken = 0;
      for (var len = math.min(_maxAliasTokens, tokens.length - i); len >= 1; len--) {
        final hit = aliases[norm(tokens.sublist(i, i + len).join(' '))];
        if (hit == null) continue;
        final already = _spelledOutAt(tokens, i, hit);
        if (already > 0) {
          out.addAll(tokens.sublist(i, i + already));
          taken = already;
        } else {
          out.add(hit);
          taken = len;
        }
        break;
      }
      if (taken == 0) out.add(tokens[i]);
      i += taken == 0 ? 1 : taken;
    }
    return out.join(' ');
  }

  /// How many of [tokens] from [i] already spell out [expansion], or 0.
  static int _spelledOutAt(List<String> tokens, int i, String expansion) {
    final want = norm(expansion).split(' ');
    if (i + want.length > tokens.length) return 0;
    for (var k = 0; k < want.length; k++) {
      if (norm(tokens[i + k]) != want[k]) return 0;
    }
    return want.length;
  }

  /// Whether [name] *starts* with a brand that begins with a digit.
  ///
  /// Only the leading position matters: `Coca 600` is never misread, but
  /// `3 Corações Café` would lose its brand to the quantity parser.
  bool startsWithBrand(String name) {
    if (brands.isEmpty) return false;
    final n = norm(name);
    return brands.any((b) => b.isNotEmpty && (n == b || n.startsWith('$b ')));
  }

  /// One word, singularised. `"Pães"` → `"pão"`, `"Laranjas"` → `"laranja"`.
  ///
  /// Portuguese plurals are irregular enough that suffix rules alone get
  /// `pães` and `pastéis` wrong, so [plurals] overrides first and the lexicon
  /// itself vetoes words that merely end in `s` while already being singular
  /// (`arroz`, `lápis`). A word no rule touches is returned **unchanged**,
  /// casing included — this runs over the search term, not the display text.
  String singular(String word) {
    if (word.length <= 3) return word;
    final n = norm(word);
    final irregular = plurals[n];
    if (irregular != null) return irregular;
    if (byKey.containsKey(n) || _notPlural.contains(n)) return word;
    if (!word.toLowerCase().endsWith('s')) return word;

    final w = word.toLowerCase();
    for (final suffix in const ['ões', 'ães', 'ãos']) {
      if (w.endsWith(suffix)) return '${w.substring(0, w.length - 3)}ão';
    }
    // "pastéis" → "pastel", "papéis" → "papel": a vowel + "is" is a collapsed
    // "l". Five letters minimum, because every real one has them and the short
    // words that would match ("mais", "dois", "seis") are not plurals at all.
    final vowelIs = RegExp(r'([aeiouáéíóúâêô])is$');
    if (w.length >= 5 && vowelIs.hasMatch(w)) {
      return w.replaceFirstMapped(vowelIs, (m) => '${_deaccent(m[1]!)}l');
    }
    for (final rule in const [('ens', 'em'), ('res', 'r'), ('zes', 'z'), ('ses', 's')]) {
      if (w.endsWith(rule.$1)) {
        return w.substring(0, w.length - rule.$1.length) + rule.$2;
      }
    }
    return w.substring(0, w.length - 1);
  }

  /// `"pastéis"` collapses to `"pastel"`, not `"pastél"` — the accent only
  /// existed to carry the stress the dropped `i` took with it.
  static String _deaccent(String vowel) {
    const from = 'áéíóúâêô';
    const to = 'aeiouaeo';
    final i = from.indexOf(vowel);
    return i < 0 ? vowel : to[i];
  }

  int get _maxKeyTokens => _maxTokens(byKey.keys);
  int get _maxAliasTokens => _maxTokens(aliases.keys);

  static int _maxTokens(Iterable<String> keys) =>
      keys.fold(1, (m, k) => math.max(m, k.split(' ').length));
}

/// Words that end in `s` while being perfectly singular. Without these, a
/// suffix rule turns "Omo 3x mais" into "Omo 3x mal" and quietly makes the
/// search term wrong. `norm()`-ed, so unaccented.
const _notPlural = {
  'MAIS', 'MENOS', 'DEPOIS', 'APOS', 'ATRAS', 'TALVEZ', 'DOIS', 'TRES', 'SEIS',
  'LAPIS', 'ONIBUS', 'VIRUS', 'ATLAS', 'GAS', 'MES', 'PAIS', 'ARROZ', 'AVOS',
};

/// How one term is sold, and in what packages.
class Staple {
  const Staple({required this.sale, this.sizes = const [], this.packs = const []});

  /// `'kg'` — loose, priced per kilo, so a weight next to it is **how much to
  /// buy**. `'un'` — a package, so a weight next to it is **how big the package
  /// is**. This single field is what separates `Tomate 2kg` from `Arroz 5kg`.
  final String sale;

  /// Package sizes this product actually comes in, canonicalised. Used to
  /// prefer the right one out of a price search's candidates.
  final List<Measure> sizes;

  /// How many come in one package — eggs by 12, papel higiênico by 4/8/12.
  /// The reason `12 Ovos` can be recognised as a carton rather than a dozen
  /// separate purchases.
  final List<int> packs;

  static const kg = Staple(sale: 'kg');
  static const un = Staple(sale: 'un');

  bool get soldByWeight => sale == 'kg';

  /// Accepts both the shorthand (`"kg"`) and the full object form.
  static Staple? fromJson(Object? value) {
    if (value is String) return Staple(sale: value == 'kg' ? 'kg' : 'un');
    if (value is! Map<String, dynamic>) return null;
    final sizes = (value['sizes'] as List?) ?? const [];
    final packs = (value['packs'] as List?) ?? const [];
    return Staple(
      sale: value['sale'] == 'kg' ? 'kg' : 'un',
      sizes: [for (final s in sizes) ?parseMeasure('$s')],
      packs: [for (final p in packs) ?int.tryParse('$p')],
    );
  }
}

/// Overridden in `main()` with the loaded lexicon, like `appConfigProvider`.
/// Defaults to [Staples.fallback] so a widget test that never loads assets
/// still parses sensibly.
final staplesProvider = Provider<Staples>((ref) => Staples.fallback);
