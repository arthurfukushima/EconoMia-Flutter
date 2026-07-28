import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

import 'models/precos.dart';
import 'models/receipt.dart';

/// Overridden in `main()` once the database is open — a repository is useless
/// asynchronously and every screen wants it synchronously.
final receiptRepositoryProvider = Provider<ReceiptRepository>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

/// Opens the app database — one file on IO (no schema, no migration step),
/// IndexedDB on web since there is no filesystem to hand path_provider.
Future<Database> openAppDatabase() async {
  if (kIsWeb) {
    return databaseFactoryWeb.openDatabase('economia.db');
  }
  final dir = await getApplicationDocumentsDirectory();
  return databaseFactoryIo.openDatabase('${dir.path}/economia.db');
}

final _receipts = stringMapStoreFactory.store('receipts');
final _offers = stringMapStoreFactory.store('offers');

/// Two keyed document collections, both read whole.
///
/// A document store rather than SQL because that is genuinely the access
/// pattern: History sorts every receipt, Tendências scans every offer, and
/// there is not one join or filtered query between them.
class ReceiptRepository {
  ReceiptRepository(this.db);

  final Database db;

  Future<Receipt?> getReceipt(String accessKey) async {
    final row = await _receipts.record(accessKey).get(db);
    return row == null ? null : Receipt.fromJson(row);
  }

  /// Keyed by chave de acesso, so re-scanning a nota overwrites it instead of
  /// duplicating it — and reading it back is what keeps a re-scan off the SEFAZ
  /// portal entirely.
  Future<Receipt> saveReceipt(Receipt receipt) async {
    final stamped = receipt.createdAt == null
        ? receipt.copyWith(createdAt: DateTime.now().millisecondsSinceEpoch)
        : receipt;
    await _receipts.record(stamped.accessKey).put(db, stamped.toJson());
    return stamped;
  }

  /// Newest first.
  Future<List<Receipt>> listReceipts() async {
    final rows = await _receipts.find(
      db,
      finder: Finder(sortOrders: [SortOrder('createdAt', false)]),
    );
    return [for (final row in rows) Receipt.fromJson(row.value)];
  }

  /// Wipes both stores. The offers are mined from the receipts, so keeping them
  /// after a history clear would leave trends the user can no longer trace back
  /// to anything.
  Future<void> clearAll() => db.transaction((txn) async {
        await _receipts.delete(txn);
        await _offers.delete(txn);
      });

  /// Accumulates dated price sightings for weekday-trend detection.
  ///
  /// A priceless or undated observation is dropped at the door — it can only
  /// dilute a median. The record key is content-derived, so re-scanning the
  /// same receipt overwrites rather than double-counting that day.
  Future<void> saveOffers(List<PriceObservation> observations) async {
    final rows = observations
        .where((o) => o.priceCents > 0 && o.datahora.isNotEmpty)
        .toList();
    if (rows.isEmpty) return;
    await db.transaction((txn) async {
      for (final o in rows) {
        await _offers.record(o.key).put(txn, o.toJson());
      }
    });
  }

  Future<List<PriceObservation>> listOffers() async => [
        for (final row in await _offers.find(db))
          PriceObservation.fromJson(row.value),
      ];
}
