/// Weekly promo-day trends from accumulated price observations.
///
/// Pure arithmetic over `offers`, mined during receipt pricing (see
/// `data/enrichment.dart`) and read back via `ReceiptRepository.listOffers`.
///
/// A (chain, category) pair is flagged "cheaper on weekday W" only when that
/// weekday's median price is `marginPct` below the median of every *other*
/// weekday — not the overall median, since a heavily-observed cheap day would
/// drag the overall down and hide its own signal — and only when both sides
/// clear `minPerDay` observations. Thin data yields nothing, honestly, rather
/// than a fabricated "Wednesday!".
///
/// ponytail: per-user local accumulation, no server-side pooling — revisit
/// only if on-device data stays too sparse to ever clear the bar.
library;

import '../core/categoria.dart';
import '../core/text.dart';
import '../data/models/precos.dart';
import '../data/models/receipt.dart';

const _weekdays = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];

/// "numa Segunda" / "num Sábado" — the day a purchase was made on.
String numDiaSemana(int wd) => wd == 0 || wd == 6 ? 'num ${_weekdays[wd]}' : 'numa ${_weekdays[wd]}';

/// "às Quartas" / "aos Sábados" — the day a trend recommends instead.
String emDiaSemana(int wd) => wd == 0 || wd == 6 ? 'aos ${_weekdays[wd]}s' : 'às ${_weekdays[wd]}s';

/// Sunday=0..Saturday=6, matching [_weekdays]. Dart's own `DateTime.weekday`
/// is Monday=1..Sunday=7, so this is `% 7` away from it, not a copy of it.
int? _weekdayOf(String? datahora) {
  final d = DateTime.tryParse(datahora ?? '');
  return d == null ? null : d.weekday % 7;
}

/// The weekday (Sunday=0..Saturday=6) a receipt was bought on: the consulta's
/// own date first, falling back to when it was scanned. Null when neither
/// resolves.
///
/// `"DD/MM/YYYY HH:mm:ss"`, as the SEFAZ consulta prints it — parsed by hand
/// since it is neither ISO-8601 nor `DateTime`'s native format.
int? purchaseWeekday(Receipt receipt) {
  final purchasedAt = receipt.header.purchasedAt;
  final m = purchasedAt == null ? null : RegExp(r'(\d{2})/(\d{2})/(\d{4})').firstMatch(purchasedAt);
  final d = m != null
      ? DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!))
      : (receipt.createdAt == null ? null : DateTime.fromMillisecondsSinceEpoch(receipt.createdAt!));
  return d == null ? null : d.weekday % 7;
}

double _median(List<int> nums) {
  final s = [...nums]..sort();
  final m = s.length ~/ 2;
  return s.length.isOdd ? s[m].toDouble() : (s[m - 1] + s[m]) / 2;
}

/// Reduces a razão social to the one word that names the chain, e.g.
/// `"SUPERMERCADOS MUFFATO E CIA LTDA"` → `"MUFFATO"` — what lets two branches
/// of the same chain count as one store.
String? _chainKey(String? store) {
  final tokens = distinctiveStoreTokens(store);
  return tokens.isEmpty ? null : tokens.first;
}

String _titleCase(String s) => s.isEmpty ? s : s[0] + s.substring(1).toLowerCase();

typedef Trend = ({Categoria category, String? store, String chain, int weekday, int nObs, int deltaPct});

/// Cheapest weekday within one store×category's dated prices, or null if none
/// clears the bar. Both the flagged weekday and "every other weekday" need
/// `>= minPerDay` observations for the comparison to mean anything.
({int weekday, int nObs, int deltaPct})? _cheapWeekday(
  List<({int wd, int cents})> rows,
  int minPerDay,
  int marginPct,
) {
  if (rows.length < minPerDay) return null;
  final byWd = <int, List<int>>{};
  for (final r in rows) {
    (byWd[r.wd] ??= []).add(r.cents);
  }

  ({int weekday, int nObs, int deltaPct})? best;
  for (final entry in byWd.entries) {
    if (entry.value.length < minPerDay) continue;
    final others = [for (final r in rows) if (r.wd != entry.key) r.cents];
    if (others.length < minPerDay) continue;
    final deltaPct = ((1 - _median(entry.value) / _median(others)) * 100).round();
    if (deltaPct >= marginPct && (best == null || deltaPct > best.deltaPct)) {
      best = (weekday: entry.key, nObs: entry.value.length, deltaPct: deltaPct);
    }
  }
  return best;
}

/// Trends across every accumulated observation, one per (chain, category)
/// that clears the bar. Store-specific only: a promo day is only actionable
/// once it can be named, so region-wide pooling — which names no chain — is
/// dropped rather than shown. Strongest discount first.
List<Trend> cheapDayByCategory(
  List<PriceObservation> offers, {
  int minPerDay = 4,
  int marginPct = 8,
}) {
  final rows = <({int wd, int cents, String chain, Categoria category, String? store})>[];
  for (final o in offers) {
    final wd = _weekdayOf(o.datahora);
    final chain = _chainKey(o.store);
    if (wd == null || o.priceCents <= 0 || chain == null || o.category == Categoria.outros) continue;
    rows.add((wd: wd, cents: o.priceCents, chain: chain, category: o.category, store: o.store));
  }

  final trends = <Trend>[];
  for (final category in {for (final r in rows) r.category}) {
    final catRows = [for (final r in rows) if (r.category == category) r];
    for (final chain in {for (final r in catRows) r.chain}) {
      final best = _cheapWeekday(
        [for (final r in catRows) if (r.chain == chain) (wd: r.wd, cents: r.cents)],
        minPerDay,
        marginPct,
      );
      if (best != null) {
        trends.add((
          category: category,
          store: _titleCase(chain),
          chain: chain,
          weekday: best.weekday,
          nObs: best.nObs,
          deltaPct: best.deltaPct,
        ));
      }
    }
  }
  trends.sort((a, b) => b.deltaPct.compareTo(a.deltaPct));
  return trends;
}

/// The cheap-day trend for one category, preferring the store the user
/// actually bought at over a region-wide match.
Trend? cheapDayFor(List<Trend> trends, Categoria category, String? storeName) {
  final forCat = [for (final t in trends) if (t.category == category) t];
  if (forCat.isEmpty) return null;
  final chain = _chainKey(storeName);
  if (chain != null) {
    for (final t in forCat) {
      if (t.chain == chain) return t;
    }
  }
  return forCat.first;
}
