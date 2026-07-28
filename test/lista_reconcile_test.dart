import 'dart:convert';
import 'dart:io';

import 'package:economia/core/staples.dart';
import 'package:economia/data/models/list_item.dart';
import 'package:economia/data/models/precos.dart';
import 'package:economia/domain/lista_parse.dart';
import 'package:economia/domain/lista_reconcile.dart';
import 'package:flutter_test/flutter_test.dart';

/// The layer that settles what the grammar couldn't, using the products the
/// shops actually stock.
///
/// Every rule here is allowed to change a parse, which makes "when does it
/// *not* fire" the more important half of this file. It must never act without
/// evidence in the response, never act twice, and never overrule the user.

/// An item as `parseItem` would have produced it, so a case starts from a real
/// parse rather than a hand-built ListItem that could drift from one.
ListItem _typed(String line, Staples staples) {
  final p = parseItem(line, staples: staples);
  return ListItem(
    id: 'x',
    raw: p.raw,
    name: p.name,
    qty: p.qty,
    unit: p.unit,
    sizeValue: p.size?.value,
    sizeUnit: p.size?.unit,
    parseConf: p.conf,
  );
}

Precos _withOptions(List<String> names) => Precos(
      cheapest: const Offer(priceCents: 1000),
      options: [
        for (var i = 0; i < names.length; i++)
          ProductOption(key: 'k$i', name: names[i], cheapest: const Offer(priceCents: 1000)),
      ],
    );

/// A successful lookup that simply found nothing nearby — distinct from a
/// failed fetch, which never reaches the reconciler at all.
const _nothing = Precos();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Staples staples;
  setUpAll(() async => staples = await Staples.load());

  group('rule 1 — the wrong price basis', () {
    test('an unknown weight term with no per-KG offers is really a package', () {
      // "300g Patê" parsed as an amount, because an unknown weight term is
      // usually an açougue cut. Nothing came back per-KG, so it wasn't.
      final item = _typed('300g Patê caseiro', staples);
      expect((item.unit, item.qty), ('kg', 0.3));

      final read = reconcile(item, _nothing, staples);
      expect(read.reprice, isTrue);
      expect(read.item.unit, 'un');
      expect(read.item.qty, 1, reason: 'never 0,3 × a package price');
      expect(read.item.size, (value: 0.3, unit: 'kg'),
          reason: 'the weight survives as a hint, so the 300g tub still wins');
    });

    test('a term the lexicon vouched for is left alone', () {
      // Beef really is sold by the kilo. An empty per-KG result is a gap in
      // local coverage, and pricing beef per package would be meaningless.
      final item = _typed('2,5kg Carne boi', staples);
      final read = reconcile(item, _nothing, staples);
      expect(read.reprice, isFalse);
      expect((read.item.unit, read.item.qty), ('kg', 2.5));
    });

    test('it fires once, never in a loop', () {
      final flipped = reconcile(_typed('300g Patê', staples), _nothing, staples).item;
      expect(flipped.reconciled, isTrue);
      expect(reconcile(flipped, _nothing, staples).reprice, isFalse);
    });

    test('offers came back, so the basis was fine', () {
      final item = _typed('300g Patê', staples);
      final read = reconcile(item, _withOptions(['PATE 300G']), staples);
      expect(read.reprice, isFalse);
      expect(read.item.unit, 'kg');
    });
  });

  group('rule 2 — was that a count, or the pack it comes in?', () {
    test('a matching pack on the shelves confirms the carton reading', () {
      final item = _typed('12 Ovos', staples);
      expect((item.qty, item.parseConf), (1.0, ParseConf.low));

      final read = reconcile(item, _withOptions(['OVO BRANCO GRANDE 12UN']), staples);
      expect(read.item.qty, 1);
      expect(read.item.size, (value: 12.0, unit: 'un'));
      expect(read.item.parseConf, ParseConf.medium, reason: 'now evidenced, so it stops guessing');
    });

    test('no such pack nearby reverts to twelve loose eggs', () {
      final read = reconcile(
        _typed('12 Ovos', staples),
        _withOptions(['OVO VERMELHO UNIDADE', 'OVO CAIPIRA']),
        staples,
      );
      expect(read.item.qty, 12);
      expect(read.item.size, isNull);
      expect(read.item.parseConf, ParseConf.medium);
    });

    test('"C/12" and "dúzia" count as the same evidence', () {
      for (final name in ['OVOS C/12', 'OVO BCO DUZIA', 'OVO 12 UNIDADES']) {
        final read = reconcile(_typed('12 Ovos', staples), _withOptions([name]), staples);
        expect(read.item.qty, 1, reason: name);
      }
    });

    test('an explicit count was never in question', () {
      // "4x" already said count, so the parser never marked it low and this
      // rule has no licence to touch it.
      final item = _typed('4x Iogurte', staples);
      expect(item.parseConf, ParseConf.high);
      final read = reconcile(item, _withOptions(['IOGURTE MORANGO C/4']), staples);
      expect(read.item.qty, 4);
    });
  });

  group('rule 3 — price the size that was asked for', () {
    test('the 2L bottle is picked out of the candidates, not the can', () {
      final item = _typed('Refrigerante 2l', staples);
      expect(item.size, (value: 2.0, unit: 'L'));

      final read = reconcile(
        item,
        _withOptions(['REFRIGERANTE COLA LATA 350ML', 'REFRIGERANTE COLA PET 2L']),
        staples,
      );
      expect(read.item.chosenKey, 'k1');
    });

    test('2000ML is the same bottle as 2L', () {
      final read = reconcile(
        _typed('Refrigerante 2l', staples),
        _withOptions(['REFRI LARANJA 600ML', 'REFRI GUARANA 2000ML']),
        staples,
      );
      expect(read.item.chosenKey, 'k1');
    });

    test('a size nobody stocks leaves the row honest about it', () {
      final read = reconcile(
        _typed('Refrigerante 2l', staples),
        _withOptions(['REFRIGERANTE LATA 350ML']),
        staples,
      );
      expect(read.item.chosenKey, isNull, reason: 'no fabricated match');
      expect(read.item.parseConf, isNot(ParseConf.high));
    });

    test("the user's own pick is never overwritten", () {
      final item = _typed('Refrigerante 2l', staples).copyWith(chosenKey: 'mine');
      final read = reconcile(item, _withOptions(['REFRI 2L']), staples);
      expect(read.item.chosenKey, 'mine');
    });
  });

  group('no evidence, no change', () {
    test('a lookup that found nothing rewrites nothing', () {
      final item = _typed('3 Leites', staples);
      final read = reconcile(item, _nothing, staples);
      expect(read.reprice, isFalse);
      expect(
        (read.item.qty, read.item.unit, read.item.name, read.item.size),
        (item.qty, item.unit, item.name, item.size),
      );
    });

    test('a real recorded response is handled as-is', () async {
      // Shape realism: proves the rules run against what the backend actually
      // sends, not against a hand-built Precos that could drift from it.
      final json = jsonDecode(
        await File('test/fixtures/precos_desc.json').readAsString(),
      ) as Map<String, dynamic>;
      final precos = Precos.fromJson(json);
      expect(precos.name, 'ARROZ 5KG');

      final item = _typed('Arroz 5kg', staples);
      expect(item.size, (value: 5.0, unit: 'kg'));

      final read = reconcile(item, precos, staples);
      expect(read.reprice, isFalse);
      expect((read.item.qty, read.item.unit), (1.0, 'un'));
      expect(read.item.reconciled, isTrue);
    });
  });
}
