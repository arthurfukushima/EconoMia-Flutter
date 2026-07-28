import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/receipt.dart';
import '../../data/receipt_repository.dart';

/// Every saved nota, newest first. autoDispose: History isn't kept alive off
/// screen, and a clear or a fresh save both just invalidate this.
final historyProvider = FutureProvider.autoDispose<List<Receipt>>(
  (ref) => ref.watch(receiptRepositoryProvider).listReceipts(),
);

final historyControllerProvider = NotifierProvider<HistoryController, void>(
  HistoryController.new,
);

class HistoryController extends Notifier<void> {
  @override
  void build() {}

  Future<void> clearAll() async {
    await ref.read(receiptRepositoryProvider).clearAll();
    ref.invalidate(historyProvider);
  }
}
