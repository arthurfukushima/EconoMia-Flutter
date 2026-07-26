import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/receipt_repository.dart';
import '../../domain/insights.dart';
import '../../domain/tendencias.dart';
import '../receipt/receipt_controller.dart' show offersProvider;

/// Every scanned note, rolled into the figure Home's hero shows. autoDispose:
/// Home isn't kept alive off screen, so a fresh scan just invalidates this.
final homeInsightsProvider = FutureProvider.autoDispose<Insights>((ref) async {
  final receipts = await ref.watch(receiptRepositoryProvider).listReceipts();
  return aggregate(receipts);
});

/// Weekday trends for Dica da Mia — same accumulated offers the receipt day
/// tip reads, so this shares that provider's cache rather than re-fetching.
final homeTrendsProvider = Provider.autoDispose<AsyncValue<List<Trend>>>((ref) {
  return ref.watch(offersProvider).whenData((offers) => offers.isEmpty ? const [] : cheapDayByCategory(offers));
});
