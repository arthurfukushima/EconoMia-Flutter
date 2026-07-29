import 'package:economia/data/models/list_item.dart';
import 'package:economia/data/prefs.dart';
import 'package:economia/domain/lista_share.dart';
import 'package:economia/features/lista/lista_screen.dart';
import 'package:economia/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  ListItem item(
    String name, {
    double qty = 1,
    String unit = 'un',
    bool checked = false,
    String? note,
  }) => ListItem(
    id: name,
    raw: name,
    name: name,
    qty: qty,
    unit: unit,
    checked: checked,
    note: note,
  );

  test('formats a compact checklist with quantities and checked state', () {
    expect(
      formatShoppingListForShare(
        listName: 'Churrasco',
        items: [
          item('Carne', qty: 2, unit: 'kg'),
          item('Pães', qty: 12),
          item('Refrigerante 2L', checked: true),
        ],
      ),
      '🛒 *Churrasco*\n\n☐ 2 kg Carne\n☐ 12 un Pães\n☑ 1 un Refrigerante 2L',
    );
  });

  test('uses Brazilian decimal quantities and includes notes', () {
    expect(
      formatShoppingListForShare(
        listName: 'Casa',
        items: [item('Arroz', qty: 2.5, unit: 'kg', note: 'integral')],
      ),
      '🛒 *Casa*\n\n☐ 2,5 kg Arroz (integral)',
    );
  });

  test('flattens multiline names and accents into one chat line', () {
    expect(
      formatShoppingListForShare(
        listName: '  Feira\n de sábado ',
        items: [item('Limão\n siciliano')],
      ),
      '🛒 *Feira de sábado*\n\n☐ 1 un Limão siciliano',
    );
  });

  test('returns no message for an empty list', () {
    expect(
      formatShoppingListForShare(listName: 'Vazia', items: const []),
      isEmpty,
    );
  });

  Future<Prefs> testPrefs({required bool populated}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = Prefs(await SharedPreferences.getInstance());
    await prefs.initLists();
    if (populated) {
      await prefs.setItemsOf(prefs.activeListId, [item('Arroz')]);
    }
    return prefs;
  }

  Future<void> pumpListScreen(WidgetTester tester, Prefs prefs) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: ListaScreen()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('share action is enabled for a populated list', (tester) async {
    await pumpListScreen(tester, await testPrefs(populated: true));

    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('compartilhar Minha Lista'),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('share action is unavailable for an empty list', (tester) async {
    await pumpListScreen(tester, await testPrefs(populated: false));

    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('compartilhar Minha Lista'),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
  });
}
