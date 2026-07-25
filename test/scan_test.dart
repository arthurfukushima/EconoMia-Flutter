import 'dart:convert';

import 'package:economia/core/api_client.dart';
import 'package:economia/data/economia_api.dart';
import 'package:economia/data/models/receipt.dart';
import 'package:economia/data/receipt_repository.dart';
import 'package:economia/features/scan/qr_payload.dart';
import 'package:economia/features/scan/scan_controller.dart';
import 'package:economia/features/scan/scan_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  group('parseQrPayload', () {
    test('reads the full SEFAZ QR URL', () {
      final key = '1' * 44;
      final parsed = parseQrPayload('https://www.fazenda.pr.gov.br/nfce/qrcode?p=$key|2|1|abcd1234');

      expect(parsed!.accessKey, key);
      expect(parsed.p, '$key|2|1|abcd1234');
    });

    test('accepts a bare p payload with no URL wrapper', () {
      final key = '2' * 44;
      expect(parseQrPayload('$key|2|1|deadbeef')!.accessKey, key);
    });

    test('accepts a bare 44-digit key, for the manual-paste dev path', () {
      final key = '3' * 44;
      final parsed = parseQrPayload(key);
      expect(parsed!.accessKey, key);
      expect(parsed.p, key);
    });

    test('percent-decodes the payload before reading the key', () {
      final key = '4' * 44;
      final parsed = parseQrPayload('x?p=$key%7C2%7C1%7Cabc');
      expect(parsed!.accessKey, key);
      expect(parsed.p, '$key|2|1|abc');
    });

    test('rejects anything that is not a 44-digit key', () {
      expect(parseQrPayload(null), isNull);
      expect(parseQrPayload(''), isNull);
      expect(parseQrPayload('7891234567890'), isNull, reason: 'a barcode, not a nota');
      expect(parseQrPayload('1' * 43), isNull, reason: 'one digit short');
    });
  });

  group('ScanController', () {
    late ReceiptRepository repo;

    setUp(() async {
      repo = ReceiptRepository(await newDatabaseFactoryMemory().openDatabase('test.db'));
    });

    (EconomiaApi, List<Uri>) apiReturning(String body, {int status = 200}) {
      final seen = <Uri>[];
      final api = EconomiaApi(ApiClient(
        client: MockClient((req) async {
          seen.add(req.url);
          return http.Response.bytes(utf8.encode(body), status);
        }),
      ));
      return (api, seen);
    }

    ProviderContainer makeContainer(EconomiaApi api) {
      final c = ProviderContainer(overrides: [
        economiaApiProvider.overrideWithValue(api),
        receiptRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('an 8-14 digit code routes to Produto, regardless of scan mode', () async {
      final (api, seen) = apiReturning('{}');
      final c = makeContainer(api);

      final result = await c.read(scanControllerProvider.notifier).submit('7891234567890', ScanMode.nota);

      expect(result!.target, ScanTarget.produto);
      expect(result.value, '7891234567890');
      expect(seen, isEmpty, reason: 'a barcode never hits /api/nfce');
    });

    test('a new nota is fetched and saved, keyed by its access key', () async {
      final key = '5' * 44;
      final (api, seen) = apiReturning(
        '{"accessKey":"$key","header":{"totalCents":1000},'
        '"items":[{"description":"ARROZ 5KG","lineTotalCents":1000}]}',
      );
      final c = makeContainer(api);

      final result = await c.read(scanControllerProvider.notifier).submit('x?p=$key|2|1|hash', ScanMode.nota);

      expect(result!.target, ScanTarget.receipt);
      expect(result.value, key);
      expect(seen.single.queryParameters['p'], '$key|2|1|hash');
      expect((await repo.getReceipt(key))!.header.totalCents, 1000);
      expect(c.read(scanBusyProvider), isFalse);
    });

    test('re-scanning a saved nota reads local and never re-hits the portal', () async {
      final key = '6' * 44;
      await repo.saveReceipt(Receipt(accessKey: key, header: const ReceiptHeader(totalCents: 500)));
      final (api, seen) = apiReturning('{}');
      final c = makeContainer(api);

      final result = await c.read(scanControllerProvider.notifier).submit('x?p=$key|2|1|hash', ScanMode.nota);

      expect(result!.value, key);
      expect(seen, isEmpty);
    });

    test('a portal failure surfaces its pt-BR message and clears busy', () async {
      final key = '7' * 44;
      final (api, _) = apiReturning('{"error":"portal_unavailable"}', status: 502);
      final c = makeContainer(api);

      final result = await c.read(scanControllerProvider.notifier).submit('x?p=$key|2|1|hash', ScanMode.nota);

      expect(result, isNull);
      expect(c.read(scanErrorProvider), contains('SEFAZ-PR'));
      expect(c.read(scanBusyProvider), isFalse);
    });

    test('garbage input gets a mode-specific pt-BR message, not an API call', () async {
      final (api, seen) = apiReturning('{}');
      final c = makeContainer(api);

      final result = await c.read(scanControllerProvider.notifier).submit('lixo', ScanMode.produto);

      expect(result, isNull);
      expect(c.read(scanErrorProvider), contains('código de barras'));
      expect(seen, isEmpty);
    });
  });
}
