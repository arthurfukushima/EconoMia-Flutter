import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/money.dart';
import '../../data/economia_api.dart';
import '../../data/models/precos.dart';
import '../../data/prefs.dart';
import '../../theme/tokens.dart';
import '../../widgets/card_list.dart';
import '../../widgets/cat_chip.dart';
import '../../widgets/location_bar.dart';
import '../../widgets/offer_span.dart';
import '../../widgets/raw_data.dart';
import '../location/location_controller.dart';

/// "Buscar por nome" — a typed product name instead of a scanned barcode, the
/// description path of `/api/precos` (same one a receipt line or a
/// shopping-list item goes through). A vague term ("Leite") can turn up
/// several real products ([Precos.options]); a definite barcode match jumps
/// straight to `/produto/:gtin` so it gets the same nutrition lookup a
/// barcode scan does — a name search alone has no GTIN to look nutrition up
/// by.
class BuscaScreen extends ConsumerStatefulWidget {
  const BuscaScreen({super.key});

  @override
  ConsumerState<BuscaScreen> createState() => _BuscaScreenState();
}

class _BuscaScreenState extends ConsumerState<BuscaScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<String> _suggestions = const [];
  bool _busy = false;
  String? _error;
  Precos? _result;
  String? _resultQuery;
  String? _chosenKey;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // repaints the clear button
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final found = await ref.read(economiaApiProvider).fetchSuggestions(value.trim());
      if (!mounted) return;
      setState(() => _suggestions = found);
    });
  }

  Future<void> _submit(String term) async {
    final name = term.trim();
    if (name.isEmpty) return;
    _debounce?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _controller.text = name;
      _controller.selection = TextSelection.collapsed(offset: name.length);
      _suggestions = const [];
      _busy = true;
      _error = null;
      _result = null;
      _resultQuery = name;
      _chosenKey = null;
    });

    final location = ref.read(locationControllerProvider);
    if (location == null) {
      setState(() => _busy = false);
      return;
    }
    Precos? data;
    try {
      data = await ref.read(economiaApiProvider).lookupProductByName(name, location);
    } on ApiException {
      data = null;
    }
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _busy = false;
        _error = 'Falha ao buscar preços. Tente novamente.';
      });
      return;
    }
    await ref.read(prefsProvider).addProductSearchHistory(name);
    if (!mounted) return;
    // A definite barcode match is not really a choice ("real options" are
    // only ever sent when there's more than one candidate product) — jump
    // straight to Produto, which runs the nutrition lookup this screen can't.
    if (data.gtin != null && data.options.isEmpty) {
      setState(() => _busy = false);
      context.push('/produto/${data.gtin}');
      return;
    }
    setState(() {
      _busy = false;
      _result = data;
    });
  }

  void _selectOption(ProductOption option) {
    if (option.gtin != null) {
      context.push('/produto/${option.gtin}');
      return;
    }
    setState(() => _chosenKey = option.key);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final location = ref.watch(locationControllerProvider);
    final history = ref.read(prefsProvider).productSearchHistory;
    final term = _controller.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar produto')),
      body: Column(
        children: [
          const LocationBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'nome do produto (ex.: leite, arroz, toddy)',
                    isDense: true,
                    suffixIcon: term.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'limpar',
                            onPressed: () => setState(() {
                              _controller.clear();
                              _suggestions = const [];
                            }),
                          ),
                  ),
                  onChanged: _onChanged,
                  onSubmitted: _submit,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: term.isEmpty || _busy ? null : () => _submit(term),
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Buscar'),
                ),
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _SuggestionList(items: _suggestions, onTap: _submit),
                ] else if (history.isNotEmpty && _result == null && !_busy) ...[
                  const SizedBox(height: 16),
                  Text('Buscas recentes', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final h in history) ActionChip(label: Text(h), onPressed: () => _submit(h)),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                if (location == null)
                  Text(
                    'Informe seu CEP acima para comparar preços na sua região.',
                    style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
                  )
                else if (_error != null) ...[
                  Text(_error!, style: theme.textTheme.bodyMedium!.copyWith(color: sa.danger)),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => _submit(_resultQuery ?? term),
                    child: const Text('tentar de novo'),
                  ),
                ] else if (_result != null)
                  _ResultSection(
                    data: _result!,
                    chosenKey: _chosenKey,
                    onSelectOption: _selectOption,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.items, required this.onTap});

  final List<String> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return CardList(
      children: [
        for (final s in items)
          InkWell(
            onTap: () => onTap(s),
            child: Align(alignment: Alignment.centerLeft, child: Text(s, style: Theme.of(context).textTheme.bodyMedium)),
          ),
      ],
    );
  }
}

/// The looked-up product: the active candidate's price summary, plus a
/// switcher when the term matched more than one real product. Mirrors
/// [ProductOption]/`chosenKey` picking as `domain/lista.dart`'s
/// `activeOption` does for a shopping-list line — "no pick yet" defaults to
/// the most-offered candidate rather than showing nothing.
class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.data, required this.chosenKey, required this.onSelectOption});

  final Precos data;
  final String? chosenKey;
  final void Function(ProductOption option) onSelectOption;

  ProductOption? get _active {
    final options = data.options;
    if (options.isEmpty) return null;
    for (final o in options) {
      if (o.key == chosenKey) return o;
    }
    return options.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final active = _active;
    // Either the picked/default candidate's own summary, or (no options at
    // all — a single unambiguous produce/description match) the response
    // itself.
    final name = active?.name ?? data.name;
    final ncm = active?.ncm ?? data.ncm;
    final cheapest = active?.cheapest ?? data.cheapest;
    final stores = active?.stores ?? data.stores;
    final nStores = active?.nStores ?? data.nStores;
    final hasOffers = (cheapest != null) || stores.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 3), child: CatChip(description: name, ncm: ncm)),
            const SizedBox(width: 8),
            Expanded(child: Text(name ?? 'produto', style: theme.textTheme.titleMedium)),
          ],
        ),
        const SizedBox(height: 8),
        if (data.confidence == 'approx')
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('aprox. — combinação por descrição, não por código de barras', style: theme.textTheme.labelMedium!.copyWith(color: sa.muted)),
          ),
        if (hasOffers) ...[
          if (cheapest != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mais barato: ', style: theme.textTheme.bodyMedium),
                Expanded(child: OfferSpan(offer: cheapest)),
              ],
            ),
          const SizedBox(height: 4),
          Text(
            '$nStores ${nStores == 1 ? 'mercado' : 'mercados'} nesta região',
            style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
          ),
        ] else
          Text(
            'Sem preço por perto para "${data.name ?? 'este termo'}". Os preços cobrem cerca de duas '
            'semanas de notas fiscais na região — tente aumentar o raio acima.',
            style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
          ),
        if (data.options.length > 1) ...[
          const SizedBox(height: 14),
          Text('trocar produto (${data.options.length} opções)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          CardList(
            children: [
              for (final o in data.options)
                _OptionRow(option: o, selected: o.key == active?.key, onTap: () => onSelectOption(o)),
            ],
          ),
        ],
        if (stores.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Lojas próximas (${stores.length})', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          CardList(children: [for (final s in stores) StoreRow(offer: s)]),
        ],
        const SizedBox(height: 10),
        RawData(data: data.toJson()),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.option, required this.selected, required this.onTap});

  final ProductOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final price = option.cheapest?.priceCents;

    return Semantics(
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(child: Text(option.name ?? 'produto', style: theme.textTheme.bodyMedium)),
            const SizedBox(width: 8),
            Text(
              price == null ? '—' : formatBRL(price),
              style: theme.textTheme.bodyMedium!.copyWith(color: selected ? sa.green : sa.muted),
            ),
            if (selected) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.check_rounded, size: 16, color: sa.green)),
          ],
        ),
      ),
    );
  }
}
