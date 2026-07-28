import 'package:economia/app.dart';
import 'package:economia/data/prefs.dart';
import 'package:economia/data/receipt_repository.dart';
import 'package:economia/router.dart';
import 'package:economia/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' show newDatabaseFactoryMemory;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => router.go('/splash'));

  Future<void> bootToHome(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
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

  testWidgets('the scan button asks which kind of scan', (tester) async {
    await bootToHome(tester);

    await tester.tap(tabText('Escanear'));
    await tester.pumpAndSettle();
    expect(find.text('O que vamos escanear?'), findsOneWidget);
    expect(find.text('Nota fiscal'), findsOneWidget);
    expect(find.text('Produto'), findsOneWidget);
  });

  testWidgets('routes pushed above the shell hide the tab bar', (tester) async {
    await bootToHome(tester);
    expect(find.byType(BottomNav), findsOneWidget);

    router.push('/notas');
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma nota ainda'), findsOneWidget);
    expect(find.byType(BottomNav), findsNothing);
  });
}
