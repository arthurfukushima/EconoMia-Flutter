import 'package:economia/core/categoria.dart';
import 'package:economia/core/money.dart';
import 'package:economia/core/pooled.dart';
import 'package:economia/core/text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('money', () {
    test('reads the SEFAZ format', () {
      expect(parseBRL(r'R$ 1.234,56'), 123456);
      expect(parseBRL('0,99'), 99);
      expect(parseBRL(r'-R$ 4,50'), -450);
      expect(parseBRL(null), 0);
      expect(parseBRL('—'), 0);
    });

    test('reads the Menor Preço format', () {
      expect(reaisToCents('3.19'), 319);
      expect(reaisToCents(3.19), 319);
      expect(reaisToCents('12'), 1200);
      expect(reaisToCents(null), 0);
    });

    // The failure this whole split exists to prevent: the dot means opposite
    // things in the two formats, so crossing them is off by 100x and silent.
    test('the two formats are never interchangeable', () {
      expect(parseBRL('3.19'), 31900);
      expect(reaisToCents('3.19'), 319);
    });

    test('formats back to pt-BR', () {
      expect(formatBRL(123456), r'R$ 1.234,56');
      expect(formatBRL(0), r'R$ 0,00');
      expect(formatBRL(5), r'R$ 0,05');
      expect(formatBRL(-1750), r'-R$ 17,50');
      expect(formatBRL(100000000), r'R$ 1.000.000,00');
    });
  });

  group('text', () {
    test('normalises accents, case and punctuation', () {
      expect(norm('Pão de Açúcar 500g'), 'PAO DE ACUCAR 500G');
      expect(norm('  IOG.  ACTIVIA/MORANGO '), 'IOG ACTIVIA MORANGO');
      expect(norm(null), '');
    });

    test('reduces a razão social to the chain name', () {
      expect(distinctiveStoreTokens('SUPERMERCADOS MUFFATO E CIA LTDA'), ['MUFFATO']);
      expect(distinctiveStoreTokens('SUPER ATACADO DISTRIBUIDORA LTDA'), <String>[]);
    });
  });

  group('categoria', () {
    test('a fiscal NCM beats the description', () {
      // "LEITE" would key to laticínios; NCM chapter 08 says fruit and wins.
      expect(classify(description: 'LEITE DE COCO', ncm: '08045000'), Categoria.frutas);
      expect(classify(description: 'QUALQUER COISA', ncm: '22021000'), Categoria.bebidas);
    });

    test('falls back to the first keyword in the description', () {
      expect(classify(description: 'BANANA NANICA KG'), Categoria.frutas);
      expect(classify(description: 'ALCATRA BOV KG'), Categoria.carnes);
      expect(classify(description: 'PAES DE FORMA'), Categoria.padaria);
    });

    test('an unrecognised item is honestly outros', () {
      expect(classify(description: 'PILHA AAA 4UN'), Categoria.outros);
      expect(classify(description: ''), Categoria.outros);
      // A 3-digit NCM is not a chapter we can trust; fall through to keywords.
      expect(classify(description: 'CERVEJA LATA', ncm: '220'), Categoria.bebidas);
    });

    test('reads a persisted name back, unknown ones included', () {
      expect(Categoria.fromKey('carnes'), Categoria.carnes);
      expect(Categoria.fromKey('hortifruti'), Categoria.outros);
      expect(Categoria.fromKey(null), Categoria.outros);
    });
  });

  group('pooled', () {
    test('keeps input order and never exceeds the limit', () async {
      var inFlight = 0;
      var peak = 0;
      final out = await pooled(List.generate(20, (i) => i), 6, (i) async {
        peak = ++inFlight > peak ? inFlight : peak;
        await Future<void>.delayed(const Duration(milliseconds: 2));
        inFlight--;
        return 'item$i';
      });

      expect(out.first, 'item0');
      expect(out.last, 'item19');
      expect(out, List.generate(20, (i) => 'item$i'));
      expect(peak, lessThanOrEqualTo(6));
      expect(peak, greaterThan(1), reason: 'a pool that never overlaps is a for loop');
    });

    test('an empty list does nothing', () async {
      expect(await pooled(<int>[], 6, (i) async => i), isEmpty);
    });
  });
}
