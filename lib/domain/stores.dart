import '../data/models/precos.dart';

/// Folds a newly-seen store list into an existing one: dedupe by `cod`, keep
/// nearest-first.
///
/// Shared by Mercado (fold a scan's stores into the picker, union the seed
/// pages) and Lista (fold name-searched picks into the markets carrying a listed
/// item), which is why it lives here rather than in either feature. An offer
/// with no `cod` is dropped — the code is the store's identity, and two
/// codeless offers cannot be told apart.
List<Offer> mergeStores(List<Offer> list, List<Offer> incoming) {
  final byCod = {for (final s in list) if (s.cod != null) s.cod!: s};
  for (final s in incoming) {
    if (s.cod != null) byCod.putIfAbsent(s.cod!, () => s);
  }
  final merged = byCod.values.toList()
    ..sort((a, b) => (a.km ?? double.infinity).compareTo(b.km ?? double.infinity));
  return merged;
}
