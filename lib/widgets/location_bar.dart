import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_location.dart';
import '../features/location/location_controller.dart';
import '../theme/tokens.dart';

const _raios = [1, 5, 10, 15, 25, 50];

/// CEP + GPS + raio, docked above the tab content. Two states, per the
/// honesty rule for a setting nothing downstream can work without: an unset
/// form (CEP field, "usar minha localização") and a compact summary (📍
/// label, raio picker, "usar GPS", "alterar").
class LocationBar extends ConsumerStatefulWidget {
  const LocationBar({super.key});

  @override
  ConsumerState<LocationBar> createState() => _LocationBarState();
}

class _LocationBarState extends ConsumerState<LocationBar> {
  final _cepController = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _cepController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cepController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _cepController.text.replaceAll(RegExp(r'\D'), '').length == 8;

  Future<void> _submitCep() async {
    await ref.read(locationControllerProvider.notifier).setCep(_cepController.text);
    _cepController.clear();
    if (mounted && ref.read(locationControllerProvider) != null) setState(() => _editing = false);
  }

  Future<void> _useGps() async {
    await ref.read(locationControllerProvider.notifier).useGps();
    if (mounted && ref.read(locationControllerProvider) != null) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final location = ref.watch(locationControllerProvider);
    final busy = ref.watch(locationBusyProvider);
    final error = ref.watch(locationErrorProvider);
    final showForm = location == null || _editing;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: sa.paper,
        border: Border(bottom: BorderSide(color: sa.stroke, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          showForm ? _form(theme, busy) : _summary(theme, location, busy),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(error.mensagem, style: theme.textTheme.labelMedium!.copyWith(color: sa.danger)),
            ),
        ],
      ),
    );
  }

  Widget _form(ThemeData theme, bool busy) {
    final sa = theme.sa;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _cepController,
                enabled: !busy,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: const InputDecoration(labelText: 'Seu CEP', hintText: '00000-000', isDense: true),
                onSubmitted: (_) {
                  if (_canSubmit && !busy) _submitCep();
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _canSubmit && !busy ? _submitCep : null,
              child: busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: sa.ink),
                    )
                  : const Text('Usar'),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: busy ? null : _useGps,
          icon: const Icon(Icons.my_location_rounded, size: 16),
          label: const Text('usar minha localização'),
        ),
      ],
    );
  }

  Widget _summary(ThemeData theme, AppLocation location, bool busy) {
    final sa = theme.sa;
    final label = [
      if (location.cep != null && location.cep!.isNotEmpty) _formatCep(location.cep!),
      if (location.city != null && location.city!.isNotEmpty) location.city!,
    ].join(' · ');

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: sa.paper2,
            borderRadius: SaRadius.pill,
            border: Border.all(color: sa.stroke, width: 1.5),
          ),
          child: Text(
            '📍 ${label.isEmpty ? 'localização atual' : label}${location.precise ? ' (GPS)' : ''}',
            style: theme.textTheme.labelMedium,
          ),
        ),
        DropdownButton<int>(
          value: location.raio,
          underline: const SizedBox(),
          isDense: true,
          items: [for (final k in _raios) DropdownMenuItem(value: k, child: Text('$k km'))],
          onChanged: busy ? null : (v) => v == null ? null : ref.read(locationControllerProvider.notifier).setRaio(v),
        ),
        TextButton(onPressed: busy ? null : _useGps, child: const Text('usar GPS')),
        TextButton(onPressed: () => setState(() => _editing = true), child: const Text('alterar')),
      ],
    );
  }
}

String _formatCep(String cep) {
  final d = cep.replaceAll(RegExp(r'\D'), '');
  return d.length == 8 ? '${d.substring(0, 5)}-${d.substring(5)}' : d;
}
