import 'dart:async';
import 'dart:convert';

import 'package:economia/core/api_client.dart';
import 'package:economia/data/economia_api.dart';
import 'package:economia/data/models/app_location.dart';
import 'package:economia/data/models/receipt.dart';
import 'package:economia/data/prefs.dart';
import 'package:economia/data/receipt_repository.dart';
import 'package:economia/features/receipt/receipt_screen.dart';
import 'package:economia/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The pricing pass writes to disk and invalidates the read, rather than
/// keeping a second copy of the receipt in memory. This is that round trip:
/// open unpriced → price → the report is on screen and the nota on disk is the
/// priced one.
void main() {
  const receipt = Receipt(
    accessKey: '41250712345678000190650010000123451987654321',
    header: ReceiptHeader(storeName: 'MUFFATO', city: 'Londrina', totalCents: 898),
    items: [
      ReceiptItem(description: 'LEITE ITALAC 1L', unit: 'UN', qty: 2, unitPriceCents: 449, lineTotalCents: 898),
    ],
  );

  testWidgets('an unpriced nota prices itself on open and reports the saving', (tester) async {
    SharedPreferences.setMockInitialValues({
      'economia.location': jsonEncode(const AppLocation(
        lat: -23.31,
        lng: -51.16,
        cep: '86010000',
        city: 'Londrina',
        raio: 15,
      ).toJson()),
    });

    final setUp = await tester.runAsync(() async {
      final repo = ReceiptRepository(await newDatabaseFactoryMemory().openDatabase('receipt_test.db'));
      await repo.saveReceipt(receipt);
      return (repo, Prefs(await SharedPreferences.getInstance()));
    });
    final repo = setUp!.$1;

    // Held open, so the "prices in flight" state can be asserted rather than
    // raced past.
    final priceCall = Completer<String>();
    final api = EconomiaApi(ApiClient(
      client: MockClient((req) async => http.Response(await priceCall.future, 200)),
    ));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        receiptRepositoryProvider.overrideWithValue(repo),
        prefsProvider.overrideWithValue(setUp.$2),
        economiaApiProvider.overrideWithValue(api),
      ],
      child: MaterialApp(theme: buildTheme(), home: ReceiptScreen(accessKey: receipt.accessKey)),
    ));

    // Fixed pumps, not pumpAndSettle: the "comparando" spinner animates
    // forever, and settling it would advance the fake clock past the client's
    // own 45s request timeout.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // The nota is on screen with its prices still in flight — the report is
    // never a blank spinner over a receipt that is already readable.
    expect(find.text('LEITE ITALAC 1L'), findsOneWidget);
    expect(find.textContaining('Comparando preços'), findsOneWidget);

    priceCall.complete(
      '{"basis":"gtin","confidence":"high","cheapest":{"priceCents":398,"store":"CONDOR","km":2.4},'
      '"stores":[{"priceCents":398,"store":"CONDOR","cod":"7","datahora":"2026-07-20T10:00:00Z"}]}',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Dá pra economizar'), findsOneWidget);
    expect(find.textContaining('R\$ 1,02 (11%)'), findsOneWidget, reason: '51 cents × 2');
    expect(find.textContaining('CONDOR'), findsOneWidget);

    // Priced on disk, so re-opening it is offline and does not price again.
    final saved = await tester.runAsync(() => repo.getReceipt(receipt.accessKey));
    expect(saved!.enrichedAt, isNotNull);
    expect(saved.locationCep, '86010000');
    expect(saved.items.single.precos!.cheapest!.priceCents, 398);
    expect(await tester.runAsync(repo.listOffers), hasLength(1));
  });
}
