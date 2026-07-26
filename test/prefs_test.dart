import 'package:economia/data/prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `productSearchHistory` — the "buscar por nome" recent-searches list
/// (backend-integration port, mirrors the reference's `searchHistory.js`).
void main() {
  Future<Prefs> newPrefs() async {
    SharedPreferences.setMockInitialValues({});
    return Prefs(await SharedPreferences.getInstance());
  }

  test('empty until something is searched', () async {
    final prefs = await newPrefs();
    expect(prefs.productSearchHistory, isEmpty);
  });

  test('newest first', () async {
    final prefs = await newPrefs();
    await prefs.addProductSearchHistory('arroz');
    await prefs.addProductSearchHistory('leite');
    expect(prefs.productSearchHistory, ['leite', 'arroz']);
  });

  test('re-searching a term moves it back to the front, case-insensitively, without a duplicate', () async {
    final prefs = await newPrefs();
    await prefs.addProductSearchHistory('Toddy');
    await prefs.addProductSearchHistory('arroz');
    await prefs.addProductSearchHistory('TODDY');
    expect(prefs.productSearchHistory, ['TODDY', 'arroz']);
  });

  test('blank input is a no-op', () async {
    final prefs = await newPrefs();
    await prefs.addProductSearchHistory('   ');
    expect(prefs.productSearchHistory, isEmpty);
  });

  test('caps at 8, dropping the oldest', () async {
    final prefs = await newPrefs();
    for (var i = 0; i < 10; i++) {
      await prefs.addProductSearchHistory('termo$i');
    }
    expect(prefs.productSearchHistory, hasLength(8));
    expect(prefs.productSearchHistory.first, 'termo9');
    expect(prefs.productSearchHistory, isNot(contains('termo0')));
    expect(prefs.productSearchHistory, isNot(contains('termo1')));
  });

  test('removeProductSearchHistory drops just that term', () async {
    final prefs = await newPrefs();
    await prefs.addProductSearchHistory('arroz');
    await prefs.addProductSearchHistory('leite');
    await prefs.removeProductSearchHistory('arroz');
    expect(prefs.productSearchHistory, ['leite']);
  });
}
