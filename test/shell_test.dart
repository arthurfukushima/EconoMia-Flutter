import 'package:economia/app.dart';
import 'package:economia/data/prefs.dart';
import 'package:economia/router.dart';
import 'package:economia/widgets/bottom_nav.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The router is a single global, so each test must start it back at the top.
  tearDown(() => router.go('/splash'));

  Future<void> bootToHome(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = Prefs(await SharedPreferences.getInstance());
    await tester.pumpWidget(ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
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
    expect(
      find.text('A casa da Mia — quanto dá pra economizar, atalhos e a dica do dia.'),
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
    expect(find.text('A casa da Mia — quanto dá pra economizar, atalhos e a dica do dia.'), findsOneWidget);
  });

  testWidgets('the scan button asks which kind of scan, then routes', (tester) async {
    await bootToHome(tester);

    await tester.tap(tab('Escanear'));
    await tester.pumpAndSettle();
    expect(find.text('O que vamos escanear?'), findsOneWidget);
    expect(find.text('Nota fiscal'), findsOneWidget);
    expect(find.text('Produto'), findsOneWidget);

    await tester.tap(find.text('Nota fiscal'));
    await tester.pumpAndSettle();
    expect(find.text('Aponte para o QR da nota fiscal.'), findsOneWidget);
  });

  testWidgets('routes pushed above the shell hide the tab bar', (tester) async {
    await bootToHome(tester);
    expect(find.byType(BottomNav), findsOneWidget);

    // Minhas Notas has no tab of its own — it opens from a Home shortcut.
    router.push('/notas');
    await tester.pumpAndSettle();

    expect(find.text('Suas notas escaneadas, com a economia de cada uma.'), findsOneWidget);
    expect(find.byType(BottomNav), findsNothing, reason: 'the bar belongs to the shell only');
  });
}
