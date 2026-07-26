import 'package:economia/app.dart';
import 'package:economia/data/prefs.dart';
import 'package:economia/data/receipt_repository.dart';
import 'package:economia/router.dart';
import 'package:economia/widgets/bottom_nav.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' show newDatabaseFactoryMemory;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The router is a single global, so each test must start it back at the top.
  tearDown(() => router.go('/splash'));

  Future<void> bootToHome(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = Prefs(await SharedPreferences.getInstance());
    final repo = await tester.runAsync(
      () async => ReceiptRepository(await newDatabaseFactoryMemory().openDatabase('shell_test.db')),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        receiptRepositoryProvider.overrideWithValue(repo!),
      ],
      child: const EconoMiaApp(),
    ));
    // Sit through the splash animation, which hands over to Home when it ends.
    await tester.pumpAndSettle();
  }

  /// Tab labels repeat the screen names, so anything targeting the bar has to
  /// say so — otherwise "Resumo" matches both the tab and the screen heading.
  Finder tab(String label) =>
      find.descendant(of: find.byType(BottomNav), matching: find.text(label));

  testWidgets('splash hands over to Início', (tester) async {
    await bootToHome(tester);
    // No receipts in this repo, so Home's hero is in its onboarding state.
    expect(
      find.text('Escaneie sua primeira nota e eu começo a caçar economia pra você.'),
      findsOneWidget,
    );
  });

  testWidgets('the bar has four tabs plus the scan button, and they switch', (tester) async {
    await bootToHome(tester);

    for (final label in ['Início', 'Lista', 'Ofertas', 'Resumo', 'Escanear']) {
      expect(tab(label), findsOneWidget, reason: 'missing tab: $label');
    }

    await tester.tap(tab('Resumo'));
    await tester.pumpAndSettle();
    expect(find.text('Para onde vai seu dinheiro e onde dá pra economizar.'), findsOneWidget);

    await tester.tap(tab('Lista'));
    await tester.pumpAndSettle();
    expect(find.text('Lista de Compras'), findsOneWidget);

    await tester.tap(tab('Início'));
    await tester.pumpAndSettle();
    expect(find.text('Escaneie sua primeira nota e eu começo a caçar economia pra você.'), findsOneWidget);
  });

  testWidgets('the scan button asks which kind of scan', (tester) async {
    await bootToHome(tester);

    await tester.tap(tab('Escanear'));
    await tester.pumpAndSettle();
    expect(find.text('O que vamos escanear?'), findsOneWidget);
    expect(find.text('Nota fiscal'), findsOneWidget);
    expect(find.text('Produto'), findsOneWidget);

    // Picking an option routes into ScanScreen, which owns a real camera —
    // untestable off a device (see qr_payload / scan_controller tests for the
    // logic that screen delegates to).
  });

  testWidgets('routes pushed above the shell hide the tab bar', (tester) async {
    await bootToHome(tester);
    expect(find.byType(BottomNav), findsOneWidget);

    // Minhas Notas has no tab of its own — it opens from a Home shortcut.
    router.push('/notas');
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma nota ainda'), findsOneWidget);
    expect(find.byType(BottomNav), findsNothing, reason: 'the bar belongs to the shell only');
  });
}
