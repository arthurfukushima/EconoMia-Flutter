import 'package:economia/data/models/catalog.dart';
import 'package:economia/features/catalogo/catalogo_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Catálogo's non-UI logic: which rows show, in what order.
CatalogItem item(
  String description, {
  int priceCents = 100,
  int? pct,
  String category = 'outros',
  String bucket = 'ok',
  int nStores = 3,
}) =>
    CatalogItem(
      description: description,
      priceCents: priceCents,
      pct: pct,
      category: category,
      bucket: bucket,
      nStores: nStores,
    );

void main() {
  group('category filter', () {
    final items = [
      item('LEITE', category: 'laticinios'),
      item('ARROZ', category: 'outros'),
      item('QUEIJO', category: 'laticinios'),
    ];

    test('null shows everything', () {
      expect(visibleCatalogItems(items).length, 3);
    });

    test('a category shows only its own', () {
      final visible = visibleCatalogItems(items, category: 'laticinios');
      expect(visible.map((i) => i.description), containsAll(['LEITE', 'QUEIJO']));
      expect(visible, hasLength(2));
    });

    test('a category nothing matches is empty, not everything', () {
      expect(visibleCatalogItems(items, category: 'carnes'), isEmpty);
    });

    test('the source list is never mutated', () {
      visibleCatalogItems(items, sort: CatalogoSort.nome);
      expect(items.first.description, 'LEITE', reason: 'sorted a copy');
    });
  });

  group('sort', () {
    test('barato ranks by how far above the region minimum the price sits', () {
      final items = [
        item('CARO', pct: 80),
        item('MELHOR', pct: 0),
        item('MEIO', pct: 40),
      ];

      expect(
        visibleCatalogItems(items, sort: CatalogoSort.barato).map((i) => i.description),
        ['MELHOR', 'MEIO', 'CARO'],
      );
    });

    // An item only one market carries has nothing to be cheaper *than*, so it
    // must not outrank a product that genuinely is the region's best price.
    test('barato sends pct-less items last, never to the top', () {
      final items = [
        item('SO AQUI', pct: null, nStores: 1),
        item('MELHOR PRECO', pct: 0),
      ];

      expect(
        visibleCatalogItems(items, sort: CatalogoSort.barato).map((i) => i.description),
        ['MELHOR PRECO', 'SO AQUI'],
      );
    });

    test('preco ranks by the price here, cheapest first', () {
      final items = [
        item('C', priceCents: 900, pct: 0),
        item('A', priceCents: 100, pct: 90),
        item('B', priceCents: 500, pct: 50),
      ];

      expect(
        visibleCatalogItems(items, sort: CatalogoSort.preco).map((i) => i.description),
        ['A', 'B', 'C'],
      );
    });

    test('nome is alphabetical', () {
      final items = [item('ZUCCHINI'), item('ARROZ'), item('MACARRAO')];

      expect(
        visibleCatalogItems(items, sort: CatalogoSort.nome).map((i) => i.description),
        ['ARROZ', 'MACARRAO', 'ZUCCHINI'],
      );
    });

    test('filter and sort compose', () {
      final items = [
        item('LEITE B', category: 'laticinios', pct: 60),
        item('ARROZ', category: 'outros', pct: 0),
        item('LEITE A', category: 'laticinios', pct: 10),
      ];

      expect(
        visibleCatalogItems(items, category: 'laticinios', sort: CatalogoSort.barato)
            .map((i) => i.description),
        ['LEITE A', 'LEITE B'],
      );
    });
  });
}
