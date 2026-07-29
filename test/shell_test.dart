import 'dart:convert';

import 'package:economia/app.dart';
import 'package:economia/data/prefs.dart';
import 'package:economia/data/receipt_repository.dart';
import 'package:economia/domain/quests.dart';
import 'package:economia/router.dart';
import 'package:economia/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' show newDatabaseFactoryMemory;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => router.go('/splash'));

  Future<void> bootToHome(
    WidgetTester tester, {
    Map<String, Object> initialPrefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = Prefs(await SharedPreferences.getInstance());
    final repo = await tester.runAsync(
      () async => ReceiptRepository(
        await newDatabaseFactoryMemory().openDatabase('shell_test.db'),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          receiptRepositoryProvider.overrideWithValue(repo!),
        ],
        child: const EconoMiaApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder tabText(String label) =>
      find.descendant(of: find.byType(BottomNav), matching: find.text(label));

  Finder bottomNavText(String text) =>
      find.descendant(of: find.byType(BottomNav), matching: find.text(text));

  String questsJsonWithClaimableDaily() => jsonEncode(
    QuestState(
      counts: const {'note': 1},
      daily: QuestTrack(
        at: DateTime.now().millisecondsSinceEpoch,
        slots: const [QuestSlot(id: 'd_nota', base: 0)],
      ),
    ).toJson(),
  );

  testWidgets('splash hands over to Inicio', (tester) async {
    await bootToHome(tester);
    expect(find.text('MISSOES EM DESTAQUE'), findsOneWidget);
  });

  testWidgets('the bar has four tabs plus the scan button, and they switch', (
    tester,
  ) async {
    await bootToHome(tester);

    for (final label in ['Lista', 'Ofertas', 'Resumo', 'Escanear']) {
      expect(tabText(label), findsOneWidget, reason: 'missing tab: $label');
    }
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);

    await tester.tap(tabText('Resumo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Com 3 ou mais compras'), findsOneWidget);

    await tester.tap(tabText('Lista'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ex: 12'), findsOneWidget);
    expect(find.textContaining('Sua lista'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text('MISSOES EM DESTAQUE'), findsOneWidget);
  });

  testWidgets('home tab badge reflects claimable mission rewards', (
    tester,
  ) async {
    await bootToHome(
      tester,
      initialPrefs: {'economia.quests': questsJsonWithClaimableDaily()},
    );

    expect(bottomNavText('1'), findsOneWidget);

    await tester.ensureVisible(find.text('Resgatar +30').first);
    await tester.tap(find.text('Resgatar +30').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(bottomNavText('1'), findsNothing);
  });

  testWidgets('home tab has no badge when no action is pending', (
    tester,
  ) async {
    await bootToHome(tester);

    expect(bottomNavText('1'), findsNothing);
  });

  testWidgets('the scan button asks which kind of scan', (tester) async {
    await bootToHome(tester);

    await tester.tap(tabText('Escanear'));
    await tester.pumpAndSettle();
    expect(find.text('O que vamos escanear?'), findsOneWidget);
    expect(find.text('Nota fiscal'), findsOneWidget);
    expect(find.text('Produto'), findsOneWidget);
  });

  testWidgets(
    'creating a list closes its naming dialog without controller errors',
    (tester) async {
      await bootToHome(tester);

      await tester.tap(tabText('Lista'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Minha Lista'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nova lista'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Feira');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Feira'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('routes pushed above the shell hide the tab bar', (tester) async {
    await bootToHome(tester);
    expect(find.byType(BottomNav), findsOneWidget);

    router.push('/notas');
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma nota ainda'), findsOneWidget);
    expect(find.byType(BottomNav), findsNothing);
  });
}
