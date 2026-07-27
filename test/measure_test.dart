import 'package:economia/core/measure.dart';
import 'package:economia/core/staples.dart';
import 'package:flutter_test/flutter_test.dart';

/// The size primitive, tested the way `money_test` tests cents: this is where
/// "500g" and "0,5kg" become one number, and a crossed unit here is a wrong
/// price everywhere downstream.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseMeasure canonicalises to kg / L / un', () {
    test('weights collapse to kilos', () {
      for (final entry in {
        '1kg': 1.0, '2 quilos': 2.0, '500g': 0.5, '500 gr': 0.5,
        '250gramas': 0.25, '1,5kg': 1.5, '1.5 KG': 1.5,
      }.entries) {
        expect(parseMeasure(entry.key), (value: entry.value, unit: 'kg'), reason: entry.key);
      }
    });

    test('volumes collapse to litres', () {
      for (final entry in {
        '2l': 2.0, '2L': 2.0, '2lt': 2.0, '2 litros': 2.0,
        '350ml': 0.35, '2000ML': 2.0, '600 ML': 0.6,
      }.entries) {
        expect(parseMeasure(entry.key), (value: entry.value, unit: 'L'), reason: entry.key);
      }
    });

    test('a unit inside a word is not a unit', () {
      // The `g` in MARGARINA, the `l` in LARANJA.
      expect(parseMeasure('MARGARINA QUALY'), isNull);
      expect(parseMeasure('LARANJA PERA'), isNull);
      expect(parseMeasure('KGEL'), isNull);
    });

    test('a decimal is not two numbers', () {
      expect(parseMeasure('1,5kg'), (value: 1.5, unit: 'kg'));
      expect(parseMeasures('ARROZ 1,5KG'), [(value: 1.5, unit: 'kg')]);
    });
  });

  group('reading a size back out of a store product name', () {
    test('the same bottle, however three stores spelled it', () {
      const want = (value: 2.0, unit: 'L');
      for (final name in [
        'REFRIGERANTE COCA COLA PET 2L',
        'REFRI GUARANA 2000ML',
        'REFRIGERANTE 2.0 L RETORNAVEL',
      ]) {
        expect(textHasMeasure(name, want), isTrue, reason: name);
      }
      expect(textHasMeasure('REFRIGERANTE LATA 350ML', want), isFalse);
    });

    test('pack counts, in the spellings shops actually use', () {
      for (final name in ['OVO BRANCO 12UN', 'OVOS C/12', 'OVO CAIPIRA DUZIA', 'LEVE 12 OVOS']) {
        expect(parsePackCounts(name), contains(12), reason: name);
      }
    });

    test('a 1% tolerance, because rounding is not a different product', () {
      expect(measureNear((value: 2.0, unit: 'L'), (value: 2.0, unit: 'L')), isTrue);
      expect(measureNear((value: 1.99, unit: 'L'), (value: 2.0, unit: 'L')), isTrue);
      expect(measureNear((value: 1.5, unit: 'L'), (value: 2.0, unit: 'L')), isFalse);
      // Units never compare equal across kinds, whatever the number.
      expect(measureNear((value: 2.0, unit: 'kg'), (value: 2.0, unit: 'L')), isFalse);
    });
  });

  test('formatMeasure puts the grams back — "500g" reads as a package', () {
    expect(formatMeasure((value: 0.5, unit: 'kg')), '500g');
    expect(formatMeasure((value: 2, unit: 'kg')), '2kg');
    expect(formatMeasure((value: 1.5, unit: 'kg')), '1,5kg');
    expect(formatMeasure((value: 0.35, unit: 'L')), '350ml');
    expect(formatMeasure((value: 2, unit: 'L')), '2L');
    expect(formatMeasure((value: 12, unit: 'un')), '12un');
  });

  group('the shipped lexicon', () {
    late Staples staples;
    setUpAll(() async => staples = await Staples.load());

    test('parses, and the sale units that cost money are right', () {
      // Every one of these being wrong is a wrong basket total, not a typo.
      for (final term in ['carne', 'tomate', 'pão', 'queijo', 'mortadela', 'laranja']) {
        expect(staples.lookup(term)?.sale, 'kg', reason: term);
      }
      for (final term in ['arroz', 'leite', 'refrigerante', 'café', 'detergente']) {
        expect(staples.lookup(term)?.sale, 'un', reason: term);
      }
    });

    test('the longest matching term wins, so a jar is not its filling', () {
      expect(staples.lookup('molho de tomate')?.sale, 'un');
      expect(staples.lookup('tomate')?.sale, 'kg');
      expect(staples.lookup('peito de frango')?.sale, 'kg');
    });

    test('expandAliases is idempotent', () {
      // Running it twice must not compound: "Coca" → "coca cola" → not
      // "coca cola cola".
      for (final input in ['Coca', 'Coca cola', 'PH', 'papel higiênico', 'Sabão roupa']) {
        final once = staples.expandAliases(input);
        expect(staples.expandAliases(once), once, reason: input);
      }
    });

    test('irregular plurals, and words that only look plural', () {
      expect(staples.singular('Pães'), 'pão');
      expect(staples.singular('Limões'), 'limão');
      expect(staples.singular('Pastéis'), 'pastel');
      expect(staples.singular('Laranjas'), 'laranja');
      for (final word in ['Arroz', 'mais', 'menos', 'lápis', 'Toddy']) {
        expect(staples.singular(word), word, reason: word);
      }
    });

    test('the fallback covers the terms where being wrong costs money', () {
      // A build with no asset bundled must still know that beef is weighed.
      for (final term in ['carne', 'tomate', 'pão', 'mortadela', 'queijo']) {
        expect(Staples.fallback.lookup(term)?.soldByWeight, isTrue, reason: term);
      }
    });
  });
}
