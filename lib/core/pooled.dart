import 'dart:math' as math;

/// Runs [task] over [items] with at most [concurrency] in flight, preserving
/// input order in the result.
///
/// This exists because Menor Preço rate-limits: firing one request per receipt
/// item at once earns 429s, and a 429 is an item that silently comes back
/// unpriced. The two call sites use different limits, both measured against the
/// real endpoint — **6** for receipt enrichment, **3** for shopping-list pricing
/// and store seeding (a whole list at once is gentler-or-nothing).
///
/// Workers pull from a shared cursor rather than the reference implementation's
/// fixed batches, so one slow request doesn't stall the five beside it.
Future<List<R>> pooled<T, R>(
  List<T> items,
  int concurrency,
  Future<R> Function(T item) task,
) async {
  final results = List<R?>.filled(items.length, null);
  var next = 0;

  Future<void> worker() async {
    while (true) {
      final i = next++;
      if (i >= items.length) return;
      results[i] = await task(items[i]);
    }
  }

  await Future.wait([
    for (var i = 0; i < math.min(concurrency, items.length); i++) worker(),
  ]);
  return [for (var i = 0; i < items.length; i++) results[i] as R];
}
