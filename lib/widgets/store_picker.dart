import 'dart:async';

import 'package:flutter/material.dart';

import '../core/text.dart';
import '../data/models/precos.dart';
import '../theme/tokens.dart';

/// "Super Muffato · Centro (1,2 km)" — one store on one line, with whatever
/// parts the API actually sent.
String storeLabel(Offer s) {
  final parts = [s.store ?? 'Loja', if ((s.bairro ?? '').isNotEmpty) s.bairro!];
  var label = parts.join(' · ');
  if (s.km != null) label += ' (${s.km!.toStringAsFixed(1).replaceAll('.', ',')} km)';
  return label;
}

/// What came back from the picker. `null` from [showStorePicker] means the sheet
/// was dismissed with no choice; a result whose [store] is null is the explicit
/// "no particular market" pick — two different things the caller must not
/// conflate.
typedef StorePick = ({Offer? store});

/// The shared market picker: the stores the caller already knows about, plus a
/// debounced live name-search for one it doesn't.
///
/// The search exists because Menor Preço has no store directory — the only way
/// to reach a market that no listed product happened to surface is to search a
/// term and keep the establishments that come back.
///
/// Used by Mercado ("você está em") and Lista ("preços em"), which differ only
/// in [title], [noneLabel] and where their store list comes from.
Future<StorePick?> showStorePicker(
  BuildContext context, {
  required List<Offer> stores,
  required String? selectedCod,
  required String title,
  required Future<List<Offer>> Function(String term) onSearch,
  bool loading = false,
  String? noneLabel,
}) =>
    showModalBottomSheet<StorePick>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _StorePickerSheet(
        stores: stores,
        selectedCod: selectedCod,
        title: title,
        onSearch: onSearch,
        loading: loading,
        noneLabel: noneLabel,
      ),
    );

/// The tap target that opens the picker, showing the current choice.
class StorePickerRow extends StatelessWidget {
  const StorePickerRow({
    super.key,
    required this.prefix,
    required this.label,
    required this.onTap,
  });

  /// "🏪 Você está em: ", "🏪 Preços em: ".
  final String prefix;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return Material(
      color: sa.paper2,
      borderRadius: SaRadius.smAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: SaRadius.smAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(prefix, style: theme.textTheme.labelMedium!.copyWith(color: sa.muted)),
              Expanded(
                child: Text(label, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
              ),
              Icon(Icons.expand_more_rounded, color: sa.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorePickerSheet extends StatefulWidget {
  const _StorePickerSheet({
    required this.stores,
    required this.selectedCod,
    required this.title,
    required this.onSearch,
    required this.loading,
    required this.noneLabel,
  });

  final List<Offer> stores;
  final String? selectedCod;
  final String title;
  final Future<List<Offer>> Function(String term) onSearch;

  /// The known stores are still being fetched — the difference between "no
  /// markets here" and "not asked yet".
  final bool loading;

  /// When given, a first row that clears the selection.
  final String? noneLabel;

  @override
  State<_StorePickerSheet> createState() => _StorePickerSheetState();
}

class _StorePickerSheetState extends State<_StorePickerSheet> {
  var _query = '';
  List<Offer> _remote = const [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    setState(() => _query = v);
    _debounce?.cancel();
    final term = v.trim();
    if (term.length < 2) {
      setState(() {
        _remote = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final found = await widget.onSearch(term);
      if (!mounted) return;
      setState(() {
        _remote = found;
        _searching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final q = norm(_query);
    final localCods = {for (final s in widget.stores) if (s.cod != null) s.cod!};
    final filtered = q.isEmpty
        ? widget.stores
        : [for (final s in widget.stores) if (norm('${s.store ?? ''} ${s.bairro ?? ''}').contains(q)) s];
    final remoteExtra = [
      for (final s in _remote)
        if (s.cod != null && !localCods.contains(s.cod)) s,
    ];
    final empty = filtered.isEmpty && remoteExtra.isEmpty;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(hintText: 'buscar mercado…'),
              onChanged: _onQueryChanged,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (widget.noneLabel != null && q.isEmpty)
                    _StoreOptionTile(
                      label: widget.noneLabel!,
                      selected: widget.selectedCod == null,
                      onTap: () => Navigator.pop(context, (store: null)),
                    ),
                  for (final s in filtered)
                    _StoreOptionTile(
                      label: storeLabel(s),
                      selected: s.cod == widget.selectedCod,
                      onTap: () => Navigator.pop(context, (store: s)),
                    ),
                  for (final s in remoteExtra)
                    _StoreOptionTile(
                      label: storeLabel(s),
                      selected: false,
                      onTap: () => Navigator.pop(context, (store: s)),
                    ),
                  if (_searching)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('buscando mercados…', style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted)),
                    ),
                  if (!_searching && empty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        widget.loading ? 'carregando mercados…' : 'nenhum mercado encontrado',
                        style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreOptionTile extends StatelessWidget {
  const _StoreOptionTile({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    return ListTile(
      title: Text(label, style: theme.textTheme.bodyMedium),
      trailing: selected ? Icon(Icons.check_rounded, color: sa.amber) : null,
      onTap: onTap,
    );
  }
}
