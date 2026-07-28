import 'package:economia/core/measure.dart';
import 'package:economia/core/staples.dart';
import 'package:economia/domain/lista_parse.dart';
import 'package:flutter_test/flutter_test.dart';

/// The parser's corpus.
///
/// This file *is* the specification: a line of a shopping list is worth
/// whatever this table says it is worth. It runs against the real shipped
/// `assets/data/staples.json`, not a stub — the lexicon is half the parser, and
/// a corpus that passed against a hand-made lexicon would prove nothing about
/// what ships.
///
/// The rule every case is measured against: **ambiguity degrades toward
/// `qty 1`.** A line the parser cannot read must come back priceless or
/// approximate, never multiplied. `500g Mortadela` meaning *500 packages* is
/// the failure this whole corpus exists to keep from coming back.

/// One expectation. [size] and [conf] are checked only when given, so a case
/// that only cares about the quantity stays one line long.
typedef _Case = ({
  String line,
  double qty,
  String unit,
  String name,
  String? size,
  String? conf,
});

_Case _c(
  String line,
  double qty,
  String unit,
  String name, {
  String? size,
  String? conf,
}) =>
    (line: line, qty: qty, unit: unit, name: name, size: size, conf: conf);

/// The list this whole feature was rebuilt for, clean. The WhatsApp test
/// below re-decorates *this* string, so the two can never drift apart.
const _sampleList = '''
•  12 Pães
•  2.5kg Carne boi
•  12 Ovos
•  Alface
•  6 Laranjas
•  Uva
•  Melancia
•  Tomate
•  5 Cebola
•  3 Leites
•  Papel Higienico
•  Pringles
•  Bolo
•  Sabão roupa
•  2 Manteigas
•  Suco
•  Refrigerante 2l
•  Toddy
•  Molho de tomate
•  Geleia
•  Nutella
•  500g Mortadela''';

/// The shipped lexicon, loaded once. Top-level because the tables below are
/// built while the file is still being declared — long before `setUpAll` runs.
late Staples _staples;

void _runTable(String description, List<_Case> cases) {
  test(description, () {
    for (final c in cases) {
      final p = parseItem(c.line, staples: _staples);
      final actual = (qty: p.qty, unit: p.unit, name: p.name);
      expect(
        actual,
        (qty: c.qty, unit: c.unit, name: c.name),
        reason: '«${c.line}»',
      );
      if (c.size != null) {
        expect(
          p.size == null ? null : formatMeasure(p.size!),
          c.size,
          reason: '«${c.line}» size',
        );
      }
      if (c.conf != null) {
        expect(p.conf, c.conf, reason: '«${c.line}» confidence');
      }
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => _staples = await Staples.load());

  test('the shipped lexicon is the one under test, not the fallback', () {
    // Guards the whole file: if the asset stopped being bundled, every case
    // below would quietly re-run against Staples.fallback and still pass.
    expect(_staples.byKey.length, greaterThan(150));
    expect(_staples.lookup('mortadela')?.sale, 'kg');
    expect(_staples.lookup('arroz')?.sale, 'un');
  });

  group('the whole list, as someone actually pastes it', () {
    // The 22 lines this feature was rebuilt for. Every one of them was wrong,
    // approximate or lossy under the old three-regex parser.
    test('22 lines in one paste', () {
      const pasted = _sampleList;

      final lines = parseInput(pasted, staples: _staples);
      expect(lines.length, 22);

      final got = [
        for (final l in lines)
          '${l.name} · ${l.qty}${l.unit}'
              '${l.size == null ? '' : ' · ${formatMeasure(l.size!)}'}',
      ];
      expect(got, [
        // Bread is priced per kilo, so twelve rolls cannot be twelve × a kilo
        // price. One kilo, with the count kept as a hint.
        'Pão · 1.0kg · 12un',
        'Carne bovina · 2.5kg', // "carne boi" is an alias
        // The undecidable one: twelve eggs, or the carton of twelve? Takes the
        // non-multiplying reading and lets the reconciler settle it.
        'Ovo · 1.0un · 12un',
        'Alface · 1.0un',
        'Laranja · 1.0kg · 6un',
        'Uva · 1.0kg', // a bare hortifruti term defaults to its own sale unit
        'Melancia · 1.0kg',
        'Tomate · 1.0kg',
        'Cebola · 1.0kg · 5un',
        'Leite · 3.0un', // packaged: an ordinary count, no hedging
        'Papel Higienico · 1.0un',
        'Pringles · 1.0un',
        'Bolo · 1.0un',
        'Sabão em pó · 1.0un', // alias rewrite, so the search can match
        'Manteiga · 2.0un',
        'Suco · 1.0un',
        // The 2l is the bottle, not the amount — and it leaves the search term
        // so the query stays broad enough to return every 2L option.
        'Refrigerante · 1.0un · 2L',
        'Toddy · 1.0un',
        'Molho de tomate · 1.0un',
        'Geleia · 1.0un',
        'Nutella · 1.0un',
        'Mortadela · 0.5kg', // NOT 500 units
      ]);
    });

    test('the same list pasted out of WhatsApp parses identically', () {
      // The real paste. WhatsApp writes a WORD JOINER (U+2060) after the bullet
      // *and* immediately before the text of every line. A word joiner is a Cf
      // format character, not whitespace, so neither `\\s` nor a hand-written
      // space class matches it in Dart or in ECMAScript. It survived the bullet
      // strip, sat between the margin and the digits, and every quantity in the
      // list stopped being a quantity.
      //
      // This is exactly why typing one line worked and pasting twenty-two did
      // not — and why the clean-paste test above passed the whole time.
      //
      // Asserted as "same as the clean list" rather than by repeating the
      // twenty-two expectations: decoration must be *invisible to the parser*,
      // which is one claim, not twenty-two.
      const wj = '\u2060';
      final decorated = [
        for (final line in _sampleList.split('\n'))
          '\u2022$wj  $wj${line.replaceFirst(RegExp(r'^\u2022\s+'), '')}',
      ].join('\n');

      String show(ParsedLine l) => '${l.name} · ${l.qty}${l.unit} · ${l.conf}'
          '${l.size == null ? '' : ' · ${formatMeasure(l.size!)}'}';

      final clean = parseInput(_sampleList, staples: _staples).map(show).toList();
      final pasted = parseInput(decorated, staples: _staples).map(show).toList();
      expect(pasted, clean);
      expect(pasted.length, 22);

      // And nothing invisible reaches the search term or the row's label.
      final invisible =
          RegExp(r'[\u00AD\u180E\u200B-\u200F\u202A-\u202E\u2060-\u206F\uFEFF]');
      for (final l in parseInput(decorated, staples: _staples)) {
        expect(invisible.hasMatch('${l.name}${l.raw}'), isFalse, reason: l.raw);
      }
    });

    test('every zero-width and bidi control a paste can carry is stripped', () {
      // Soft hyphen, Mongolian vowel separator, the zero-width family, the
      // bidi embeddings/overrides/isolates, word joiner, and the BOM.
      const controls = [
        '\u00AD', '\u180E', '\u200B', '\u200C', '\u200D',
        '\u200E', '\u200F', '\u202A', '\u202B', '\u202C',
        '\u202D', '\u202E', '\u2060', '\u2061', '\u2062',
        '\u2063', '\u2064', '\u2066', '\u2067', '\u2068',
        '\u2069', '\uFEFF',
      ];
      for (final ch in controls) {
        final label = 'U+${ch.codeUnitAt(0).toRadixString(16).toUpperCase()}';
        final p = parseItem('•$ch 12$ch Ovos', staples: _staples);
        expect(p.name, 'Ovo', reason: label);
        expect(p.size?.value, 12, reason: label);
      }
    });

    test('nothing in that list multiplies a per-kilo price by a count', () {
      // The catastrophic direction, asserted directly.
      for (final line in ['12 Pães', '6 Laranjas', '5 Cebola', '500g Mortadela']) {
        final p = parseItem(line, staples: _staples);
        expect(p.unit == 'kg' ? p.qty : 0.0, lessThanOrEqualTo(2.5), reason: line);
      }
    });
  });

  group('amount vs package size', () {
    _runTable('a weight on a loose product is how much to buy', [
      _c('2,5kg Carne boi', 2.5, 'kg', 'Carne bovina', conf: ParseConf.high),
      _c('Tomate 2kg', 2, 'kg', 'Tomate'),
      _c('500g Mortadela', 0.5, 'kg', 'Mortadela'),
      _c('1,5 kg Picanha', 1.5, 'kg', 'Picanha'),
      _c('250 gramas de presunto', 0.25, 'kg', 'Presunto'),
    ]);

    _runTable('a weight on a bagged product is the bag', [
      // The pair that proves syntax alone cannot do this: same sentence shape,
      // opposite meaning, and only the lexicon knows which is which.
      _c('Arroz 5kg', 1, 'un', 'Arroz', size: '5kg'),
      _c('5kg Arroz', 1, 'un', 'Arroz', size: '5kg'),
      _c('500g Café', 1, 'un', 'Café', size: '500g'),
      _c('Açúcar 1kg', 1, 'un', 'Açúcar', size: '1kg'),
    ]);

    _runTable('a volume is a bottle, never a ladled amount', [
      _c('Refrigerante 2l', 1, 'un', 'Refrigerante', size: '2L'),
      _c('2l Refrigerante', 1, 'un', 'Refrigerante', size: '2L'),
      _c('Leite 1L integral', 1, 'un', 'Leite integral', size: '1L'),
      _c('Detergente 500ml', 1, 'un', 'Detergente', size: '500ml'),
      _c('Coca cola 2,5l', 1, 'un', 'Coca cola', size: '2,5L'),
    ]);

    _runTable('an unknown weight term falls to "amount", the safe side', [
      // What the lexicon is most likely to be missing is an açougue or
      // hortifruti cut, and those genuinely are sold by weight.
      _c('300g Patê caseiro', 0.3, 'kg', 'Patê caseiro', conf: ParseConf.medium),
      _c('2kg Zabumba', 2, 'kg', 'Zabumba', conf: ParseConf.medium),
    ]);
  });

  group('counts', () {
    _runTable('a count of a packaged product is just a count', [
      _c('3 Leites', 3, 'un', 'Leite', conf: ParseConf.high),
      _c('2 Manteigas', 2, 'un', 'Manteiga'),
      _c('4x Sabonete', 4, 'un', 'Sabonete'),
      _c('4 x Iogurte', 4, 'un', 'Iogurte'), // 4 IS an iogurte pack size — but "4 x" said count

    ]);

    _runTable('a count of a per-kilo product becomes a kilo plus a hint', [
      _c('12 Pães', 1, 'kg', 'Pão', size: '12un', conf: ParseConf.medium),
      _c('6 Laranjas', 1, 'kg', 'Laranja', size: '6un'),
      _c('5 Cebola', 1, 'kg', 'Cebola', size: '5un'),
      _c('2 Limões', 1, 'kg', 'Limão', size: '2un'),
    ]);

    _runTable('a count that matches a real pack is read as one pack', [
      _c('12 Ovos', 1, 'un', 'Ovo', size: '12un', conf: ParseConf.low),
      _c('30 Ovos', 1, 'un', 'Ovo', size: '30un', conf: ParseConf.low),
      _c('12 Papel higiênico', 1, 'un', 'Papel higiênico', size: '12un'),
      // 7 is not a carton anyone sells, so it stays an ordinary count.
      _c('7 Ovos', 7, 'un', 'Ovo', conf: ParseConf.high),
    ]);

    _runTable('containers and dozens', [
      _c('3 cx Leite', 3, 'un', 'Leite'),
      _c('2 pct Arroz', 2, 'un', 'Arroz'),
      _c('1 fardo de Cerveja', 1, 'un', 'Cerveja'),
      _c('2 garrafas de Vinho', 2, 'un', 'Vinho'),
      _c('2 unidades de Sabonete', 2, 'un', 'Sabonete'),
      _c('2 dz Ovos', 2, 'un', 'Ovo', size: '12un'), // two cartons of twelve
      _c('meia dúzia de Ovos', 1, 'un', 'Ovo', size: '6un'),
    ]);

    _runTable('spelled-out numbers in front of a unit word', [
      _c('meio quilo de Queijo', 0.5, 'kg', 'Queijo'),
      _c('um quilo de Feijão', 1, 'un', 'Feijão', size: '1kg'),
      _c('dois litros de Refrigerante', 1, 'un', 'Refrigerante', size: '2L'),
      // Not in front of a unit word, so it stays part of the name.
      _c('Uma Coisa', 1, 'un', 'Uma Coisa'),
    ]);

    _runTable('fractions', [
      _c('1/2 kg Carne', 0.5, 'kg', 'Carne'),
      _c('½ kg Carne', 0.5, 'kg', 'Carne'),
      _c('1/2 kg de Mortadela', 0.5, 'kg', 'Mortadela'),
    ]);
  });

  group('digits that are not quantities', () {
    _runTable('a brand that opens with a number keeps it', [
      _c('3 Corações Café', 1, 'un', '3 Corações Café'),
      _c('51', 1, 'un', '51'),
      _c('7 Belo', 1, 'un', '7 Belo'),
    ]);

    _runTable('a number with no unit, mid-name, is left alone', [
      _c('Coca 600', 1, 'un', 'Coca cola 600'),
      _c('Skol 350', 1, 'un', 'Skol 350'),
      _c('Omo 3x mais', 1, 'un', 'Omo 3x mais'),
    ]);

    _runTable('an implausible count was part of the name', [
      _c('500 Folhas', 1, 'un', 'Folha', conf: ParseConf.low),
    ]);
  });

  group('notes and money', () {
    test('a parenthetical is a note, never part of the search', () {
      final p = parseItem('Leite (o do desconto)', staples: _staples);
      expect((p.name, p.note), ('Leite', 'o do desconto'));
    });

    test('a trailing dash is a note too', () {
      final p = parseItem('Carne - pro churrasco', staples: _staples);
      expect((p.name, p.note), ('Carne', 'pro churrasco'));
    });

    test('digits inside a note are not a quantity', () {
      expect(parseItem('Cerveja (leve 12)', staples: _staples).qty, 1);
    });

    test('buying by money value cannot be priced, and says so', () {
      for (final raw in ['R\$ 20 de carne', '20 reais de picanha']) {
        final p = parseItem(raw, staples: _staples);
        expect(p.qty, 1, reason: raw);
        expect(p.note, contains('R\$'), reason: raw);
        expect(p.conf, isNot(ParseConf.high), reason: raw);
      }
      expect(parseItem('20 reais de picanha', staples: _staples).name, 'Picanha');
    });
  });

  group('names', () {
    _runTable('pt-BR plurals, including the irregular ones', [
      _c('Pães', 1, 'kg', 'Pão'),
      _c('Limões', 1, 'kg', 'Limão'),
      _c('Ovos', 1, 'un', 'Ovo'),
      _c('Laranjas', 1, 'kg', 'Laranja'),
      _c('Tomates', 1, 'kg', 'Tomate'),
    ]);

    test('a word already ending in s is not "singularised"', () {
      expect(parseItem('Arroz', staples: _staples).name, 'Arroz');
      expect(parseItem('Pastéis', staples: _staples).name, 'Pastel');
    });

    _runTable('shorthand is expanded so the search can match', [
      _c('PH', 1, 'un', 'Papel higiênico'),
      _c('2 refri', 2, 'un', 'Refrigerante'),
      _c('Sabão roupa', 1, 'un', 'Sabão em pó'),
      _c('Carne de boi', 1, 'kg', 'Carne bovina'),
    ]);

    test('casing beyond the first letter is left alone', () {
      expect(parseItem('tomate', staples: _staples).name, 'Tomate');
      expect(parseItem('TODDY', staples: _staples).name, 'TODDY');
      expect(parseItem('pão DE queijo', staples: _staples).name, 'Pão DE queijo');
    });
  });

  group('parseInput', () {
    test('a decimal comma is not a separator', () {
      // The old parser split this into "1" and "5kg Carne".
      final lines = parseInput('1,5kg Carne', staples: _staples);
      expect(lines.length, 1);
      expect((lines.single.qty, lines.single.unit), (1.5, 'kg'));
    });

    test('an invisible character cannot hide a digit from the decimal guard', () {
      // The guard is a lookaround on digits, so it has to run on text the
      // formatting characters have already been taken out of — otherwise a
      // word joiner wedged beside the comma splits the line in half again.
      for (final raw in ['1⁠,5kg Carne', '1,⁠5kg Carne', '1​,5kg Carne']) {
        final lines = parseInput(raw, staples: _staples);
        expect(lines.length, 1, reason: raw);
        expect((lines.single.qty, lines.single.unit), (1.5, 'kg'), reason: raw);
      }
    });

    test('commas, newlines, semicolons and pipes all split', () {
      final lines = parseInput('Uva, Toddy\nAlface;Bolo|Suco', staples: _staples);
      expect(lines.map((l) => l.name), ['Uva', 'Toddy', 'Alface', 'Bolo', 'Suco']);
    });

    test('nothing typed → nothing added', () {
      expect(parseInput('   ,\n ', staples: _staples), isEmpty);
    });

    test('paste decoration is stripped: bullets, numbering, checkboxes, emoji', () {
      final lines = parseInput(
        '• 12 Pães\n- Toddy\n1. Arroz\n2) Feijão\n[ ] Alface\n☑ Uva\n✅ Bolo\n🍞 Pão de queijo',
        staples: _staples,
      );
      expect(lines.map((l) => l.name), [
        'Pão', 'Toddy', 'Arroz', 'Feijão', 'Alface', 'Uva', 'Bolo', 'Pão de queijo',
      ]);
    });

    test('non-breaking spaces and doubled whitespace collapse', () {
      final line = parseInput('•  2x  Leite   Integral', staples: _staples).single;
      expect((line.qty, line.name), (2.0, 'Leite Integral'));
    });

    test('a long paste stays one item per line', () {
      final text = List.generate(100, (i) => 'Item $i').join('\n');
      expect(parseInput(text, staples: _staples).length, 100);
    });
  });

  group('degenerate input', () {
    test('a line that is only a quantity keeps the raw text as its name', () {
      // Unpriceable, but still checkable — silently dropping what someone typed
      // is worse than a row that says "2kg".
      final p = parseItem('2kg', staples: _staples);
      expect((p.name, p.unit), ('2kg', 'kg'));
    });

    test('a bare number is a name, not a count of nothing', () {
      expect(parseItem('2', staples: _staples).name, '2');
      expect(parseItem('2', staples: _staples).qty, 1);
    });

    test('non-grocery lines survive instead of crashing', () {
      for (final raw in ['Ligar pra mãe', 'Bread', 'mantega', 'Verdura']) {
        final p = parseItem(raw, staples: _staples);
        expect(p.qty, 1, reason: raw);
        expect(p.name, isNotEmpty, reason: raw);
      }
    });

    test('"kg" inside a word is not a unit', () {
      expect(parseItem('4x Kgel', staples: _staples).unit, 'un');
    });

    test('every parse is either exact or falls back to a single unit', () {
      // The regression guard. Whatever a line means, it may never come back
      // asking for more than a handful of something — that is the shape of the
      // 500× bug, and it must be structurally impossible to reintroduce.
      const wild = [
        '12 Ovos', '500g Mortadela', '1kg Ovos', '2,5kg Carne', 'Refrigerante 2l',
        '300ml Molho', '0,5kg Queijo', '99 Alface', '1 sc 5kg Arroz', 'R\$ 50 de carne',
        'Leite 1L', 'Arroz 5kg', '½ Melancia', '3 Corações', 'Coca 2l zero',
      ];
      for (final raw in wild) {
        final p = parseItem(raw, staples: _staples);
        expect(p.qty, lessThanOrEqualTo(99), reason: raw);
        expect(p.qty, greaterThan(0), reason: raw);
        if (p.unit == 'kg') {
          expect(p.qty, lessThanOrEqualTo(10), reason: '$raw — a per-kilo amount');
        }
      }
    });
  });
}
