import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/api_client.dart';
import '../../core/money.dart';
import '../../data/economia_api.dart';
import '../../data/models/nutrition.dart';
import '../../data/models/precos.dart';
import '../../data/off_api.dart';
import '../../data/prefs.dart';
import '../../domain/savings.dart';
import '../../domain/stores.dart';
import '../../theme/tokens.dart';
import '../../widgets/card_list.dart';
import '../../widgets/cat_chip.dart';
import '../../widgets/location_bar.dart';
import '../../widgets/nutrition_panel.dart';
import '../../widgets/offer_span.dart';
import '../../widgets/raw_data.dart';
import '../../widgets/store_picker.dart';
import '../location/location_controller.dart';
import 'mercado_controller.dart';

/// One trip's scan: the barcode and its price lookup.
class _CheckedEntry {
  _CheckedEntry({required this.id, required this.gtin, required this.data});
  final String id;
  final String gtin;
  final Precos data;
}

/// "Which market am I in?" — scan the shelves and see whether the price here
/// beats what's nearby (Menor Preço data). The store picker is seeded before
/// the first scan and remembered across app restarts; each scan re-arms the
/// embedded camera rather than leaving the screen.
class MercadoScreen extends ConsumerStatefulWidget {
  const MercadoScreen({super.key});

  @override
  ConsumerState<MercadoScreen> createState() => _MercadoScreenState();
}

class _MercadoScreenState extends ConsumerState<MercadoScreen> {
  MobileScannerController? _camera;
  final _manualController = TextEditingController();
  bool _manualOpen = false;
  bool _fired = false;

  List<Offer> _scannedStores = const [];
  String? _codStr;
  String? _savedCod;
  final List<_CheckedEntry> _checked = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Web has no reliable camera/permission story here, so it goes straight
    // to the manual-paste flow instead of standing up a scanner.
    if (!kIsWeb) {
      _camera = MobileScannerController(formats: [BarcodeFormat.ean13, BarcodeFormat.ean8]);
    }
    _manualController.addListener(() => setState(() {}));
    _savedCod = ref.read(prefsProvider).currentStore;
  }

  @override
  void dispose() {
    _camera?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _selectStore(String? cod, {Offer? store}) {
    setState(() {
      _codStr = cod;
      if (store != null) _scannedStores = mergeStores(_scannedStores, [store]);
    });
    ref.read(prefsProvider).setCurrentStore(cod);
  }

  Future<void> _openStorePicker(List<Offer> stores, bool seeding) async {
    final location = ref.read(locationControllerProvider);
    final picked = await showStorePicker(
      context,
      stores: stores,
      selectedCod: _codStr,
      title: 'Você está em',
      loading: seeding,
      onSearch: (term) => location == null
          ? Future.value(const <Offer>[])
          : ref.read(economiaApiProvider).searchStores(term, location),
    );
    final store = picked?.store;
    if (store != null) _selectStore(store.cod, store: store);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_fired || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    _fired = true;
    _submit(raw).whenComplete(() => _fired = false);
  }

  Future<void> _submit(String raw) async {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{8,14}$').hasMatch(digits)) {
      setState(() => _error = 'Código inválido: aponte para um código de barras de produto.');
      return;
    }
    final location = ref.read(locationControllerProvider);
    if (location == null) return;

    setState(() {
      _error = null;
      _busy = true;
    });
    Precos? data;
    try {
      data = await ref.read(economiaApiProvider).lookupProduct(digits, location);
    } on ApiException {
      data = null;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (data == null) {
        _error = 'Falha ao buscar preços. Tente novamente.';
        return;
      }
      _scannedStores = mergeStores(_scannedStores, data.stores);
      _checked.insert(
        0,
        _CheckedEntry(id: '$digits-${DateTime.now().microsecondsSinceEpoch}', gtin: digits, data: data),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final location = ref.watch(locationControllerProvider);
    final seedAsync = ref.watch(mercadoSeedProvider);
    final seeding = seedAsync.isLoading;
    final stores = mergeStores(seedAsync.value ?? const [], _scannedStores);
    final effectiveCod =
        _codStr ?? (location == null ? null : defaultStoreCod(location, stores, _savedCod));
    Offer? here;
    for (final s in stores) {
      if (s.cod == effectiveCod) {
        here = s;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('No mercado')),
      body: Column(
        children: [
          const LocationBar(),
          Expanded(
            child: location == null
                ? const _Banner(text: 'Informe seu CEP acima para comparar preços.')
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                    children: [
                      StorePickerRow(
                        prefix: '🏪 Você está em: ',
                        label: here != null
                            ? storeLabel(here)
                            : seeding
                                ? 'carregando mercados…'
                                : stores.isEmpty
                                    ? 'toque para buscar o mercado'
                                    : 'selecione o mercado',
                        onTap: () => _openStorePicker(stores, seeding),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: theme.textTheme.labelMedium!.copyWith(color: sa.danger)),
                      ],
                      if (_checked.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _TripSummary(checked: _checked, cod: effectiveCod, here: here),
                      ],
                      const SizedBox(height: 14),
                      _Scanner(
                        camera: _camera,
                        busy: _busy,
                        onDetect: _onDetect,
                        manualOpen: _manualOpen,
                        manualController: _manualController,
                        onToggleManual: () => setState(() => _manualOpen = !_manualOpen),
                        onManualSubmit: () => _submit(_manualController.text.trim()),
                      ),
                      const SizedBox(height: 18),
                      if (_checked.isEmpty)
                        Text(
                          'Escaneie os produtos das prateleiras para comparar o preço daqui com o '
                          'de outros mercados.',
                          style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
                        )
                      else ...[
                        Text('Conferidos (${_checked.length})', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        CardList(
                          children: [
                            for (final e in _checked) _ResultCard(entry: e, cod: effectiveCod),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Preços de notas fiscais recentes na sua região (Menor Preço / Nota Paraná).',
                          style: theme.textTheme.labelMedium!.copyWith(color: sa.muted),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Region price range as "R$X" or "R$X – R$Y".
String _rangeText(PriceRange range) => range.minCents == range.maxCents
    ? formatBRL(range.minCents)
    : '${formatBRL(range.minCents)} – ${formatBRL(range.maxCents)}';

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium!.copyWith(color: theme.sa.muted),
        ),
      ),
    );
  }
}


/// How much this trip's scans would cost less at another market.
class _TripSummary extends StatelessWidget {
  const _TripSummary({required this.checked, required this.cod, required this.here});

  final List<_CheckedEntry> checked;
  final String? cod;
  final Offer? here;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    var tripSavings = 0;
    var overCount = 0;
    for (final e in checked) {
      final cmp = compareHere(e.data, cod);
      if (cmp.status == CompareStatus.cheaperElsewhere) {
        tripSavings += cmp.savingsCents;
        overCount++;
      }
    }
    final count = checked.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sa.paper,
        borderRadius: SaRadius.mdAll,
        border: Border.all(color: sa.stroke, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(text: '$count ', style: theme.textTheme.titleSmall),
                TextSpan(text: count == 1 ? 'item conferido' : 'itens conferidos'),
                if (here != null) TextSpan(text: ' em ${here!.store ?? 'loja'}'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (tripSavings > 0)
            Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'Comprando em outro mercado você economiza '),
                  TextSpan(
                    text: formatBRL(tripSavings),
                    style: theme.textTheme.titleSmall!.copyWith(color: sa.green),
                  ),
                  TextSpan(text: ' em $overCount ${overCount == 1 ? "item" : "itens"}'),
                ],
              ),
            )
          else
            Text(
              'Nenhum item sai mais barato em outro mercado por perto. 👍',
              style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
            ),
        ],
      ),
    );
  }
}

/// The embedded camera (EAN-8/13) plus the manual-paste fallback, re-armed
/// after every scan rather than leaving the screen.
class _Scanner extends StatelessWidget {
  const _Scanner({
    required this.camera,
    required this.busy,
    required this.onDetect,
    required this.manualOpen,
    required this.manualController,
    required this.onToggleManual,
    required this.onManualSubmit,
  });

  final MobileScannerController? camera;
  final bool busy;
  final void Function(BarcodeCapture) onDetect;
  final bool manualOpen;
  final TextEditingController manualController;
  final VoidCallback onToggleManual;
  final VoidCallback onManualSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;

    if (camera == null) {
      // Web: no camera, so the manual field is the only way in.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Digite o código de barras do produto.',
            style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: manualController,
            enabled: !busy,
            decoration: const InputDecoration(hintText: 'Código de barras (8–14 dígitos)', isDense: true),
            onSubmitted: (_) {
              if (!busy && manualController.text.trim().isNotEmpty) onManualSubmit();
            },
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: !busy && manualController.text.trim().isNotEmpty ? onManualSubmit : null,
            child: busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Consultar'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Aponte para o código de barras do produto.',
          style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: SaRadius.mdAll,
          child: SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(controller: camera!, onDetect: onDetect),
                if (busy)
                  ColoredBox(
                    color: const Color(0x99000000),
                    child: Center(child: CircularProgressIndicator(color: sa.amber)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onToggleManual,
          child: Text(manualOpen ? 'Fechar' : 'Colar código manualmente'),
        ),
        if (manualOpen) ...[
          TextField(
            controller: manualController,
            enabled: !busy,
            decoration: const InputDecoration(hintText: 'Código de barras (8–14 dígitos)', isDense: true),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: !busy && manualController.text.trim().isNotEmpty ? onManualSubmit : null,
            child: const Text('Consultar'),
          ),
        ],
      ],
    );
  }
}

/// One scanned product judged against the current market — recomputed here
/// so changing the store picker re-judges the whole list.
class _ResultCard extends ConsumerWidget {
  const _ResultCard({required this.entry, required this.cod});

  final _CheckedEntry entry;
  final String? cod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final data = entry.data;
    final cmp = compareHere(data, cod);
    // Independent of the price lookup — a miss (still loading, or genuinely
    // absent from Open Food Facts) means no nutrition row, not an error.
    final nutri = ref.watch(nutritionProvider(entry.gtin)).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: CatChip(description: data.name, ncm: data.ncm),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(data.name ?? 'Código ${entry.gtin}', style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _priceLine(theme, sa, cmp, data.range),
        if (cmp.status == CompareStatus.hereCheapest)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('✓ melhor preço', style: theme.textTheme.labelMedium!.copyWith(color: sa.green)),
          ),
        if (cmp.status == CompareStatus.cheaperElsewhere)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '+${formatBRL(cmp.savingsCents)} aqui',
              style: theme.textTheme.labelMedium!.copyWith(color: sa.danger),
            ),
          ),
        if (nutri != null) ...[
          const SizedBox(height: 6),
          _NutritionCollapse(n: nutri),
        ],
        const SizedBox(height: 6),
        RawData(data: data.toJson()),
      ],
    );
  }

  /// The four honest states [compareHere] can reach, in the same order as
  /// [CompareStatus].
  Widget _priceLine(ThemeData theme, SaColors sa, CompareResult cmp, PriceRange? range) {
    final body = theme.textTheme.labelMedium!;
    return switch (cmp.status) {
      CompareStatus.hereCheapest => Text.rich(
          TextSpan(
            style: body,
            children: [
              const TextSpan(text: 'aqui '),
              TextSpan(text: formatBRL(cmp.here!.priceCents), style: body.copyWith(color: sa.green)),
              if (range != null)
                TextSpan(text: ' · região ${_rangeText(range)}', style: body.copyWith(color: sa.muted)),
            ],
          ),
        ),
      CompareStatus.cheaperElsewhere => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: body,
                children: [
                  const TextSpan(text: 'aqui '),
                  TextSpan(text: formatBRL(cmp.here!.priceCents), style: body.copyWith(color: sa.danger)),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('mais barato: ', style: body),
                Expanded(child: OfferSpan(offer: cmp.cheaper!)),
              ],
            ),
          ],
        ),
      CompareStatus.notCarried => cmp.cheapest != null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('este mercado não está no comparador · mais barato: ', style: body.copyWith(color: sa.muted)),
                Expanded(child: OfferSpan(offer: cmp.cheapest!)),
              ],
            )
          : Text('sem preço por perto para este item', style: body.copyWith(color: sa.muted)),
      CompareStatus.noOffers =>
        Text('sem preço por perto para o código ${entry.gtin}', style: body.copyWith(color: sa.muted)),
    };
  }
}

/// Nutrition, tucked behind a collapsible here — unlike Produto, where it's
/// always visible, a busy shelf-scanning list keeps it out of the way until
/// asked for.
class _NutritionCollapse extends StatelessWidget {
  const _NutritionCollapse({required this.n});

  final Nutrition n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text('Informação nutricional', style: theme.textTheme.labelLarge),
        children: [Align(alignment: Alignment.centerLeft, child: NutritionBody(n: n))],
      ),
    );
  }
}
