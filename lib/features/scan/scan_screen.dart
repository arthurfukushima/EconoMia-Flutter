import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/tokens.dart';
import 'scan_controller.dart';
import 'scan_mode.dart';

/// The camera in one symbology, plus the manual-paste fallback for a QR that
/// won't focus, a damaged nota, or a desk/dev workflow. Routing after a
/// decode is content-based — see [ScanController].
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, required this.mode});

  final ScanMode mode;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  MobileScannerController? _camera;
  final _manualController = TextEditingController();
  bool _manualOpen = false;

  // Decode-once: the camera keeps emitting frames of the same code while the
  // lookup for the last one is still in flight.
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    // Web has no reliable camera/permission story here, so it goes straight
    // to the manual-paste flow instead of standing up a scanner.
    if (!kIsWeb) {
      _camera = MobileScannerController(
        formats: widget.mode == ScanMode.nota
            ? [BarcodeFormat.qrCode]
            : [BarcodeFormat.ean13, BarcodeFormat.ean8],
      );
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_fired || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    _fired = true;
    _submit(raw).whenComplete(() => _fired = false);
  }

  Future<void> _submit(String raw) async {
    final result = await ref.read(scanControllerProvider.notifier).submit(raw, widget.mode);
    if (result == null || !mounted) return;
    switch (result.target) {
      case ScanTarget.receipt:
        context.pushReplacement('/notas/${result.value}');
      case ScanTarget.produto:
        context.pushReplacement('/produto/${result.value}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = theme.sa;
    final busy = ref.watch(scanBusyProvider);
    final error = ref.watch(scanErrorProvider);

    final placeholder = widget.mode == ScanMode.nota
        ? 'QR da nota (…?p=…) ou chave de 44 dígitos'
        : 'Código de barras (8–14 dígitos)';

    if (kIsWeb) {
      final hint = widget.mode == ScanMode.nota
          ? 'Cole o link do QR da nota fiscal (…?p=…) ou a chave de 44 dígitos.'
          : 'Digite o código de barras do produto.';
      return Scaffold(
        appBar: AppBar(title: const Text('Escanear')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(hint, style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted)),
                const SizedBox(height: 16),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(error, style: theme.textTheme.labelMedium!.copyWith(color: sa.danger)),
                  ),
                TextField(
                  controller: _manualController,
                  maxLines: 3,
                  enabled: !busy,
                  autofocus: true,
                  decoration: InputDecoration(hintText: placeholder, isDense: true),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (!busy && _manualController.text.trim().isNotEmpty) {
                      _submit(_manualController.text.trim());
                    }
                  },
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: !busy && _manualController.text.trim().isNotEmpty
                      ? () => _submit(_manualController.text.trim())
                      : null,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Consultar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hint = widget.mode == ScanMode.nota
        ? 'Aponte para o QR da nota fiscal.'
        : 'Aponte para o código de barras do produto.';

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Text(hint, style: theme.textTheme.bodyMedium!.copyWith(color: sa.muted)),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _camera!,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => const _CameraUnavailable(),
                ),
                if (busy)
                  ColoredBox(
                    color: const Color(0x99000000),
                    child: Center(child: CircularProgressIndicator(color: sa.amber)),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(error, style: theme.textTheme.labelMedium!.copyWith(color: sa.danger)),
                    ),
                  TextButton(
                    onPressed: () => setState(() => _manualOpen = !_manualOpen),
                    child: Text(_manualOpen ? 'Fechar' : 'Colar payload / chave / código manualmente'),
                  ),
                  if (_manualOpen) ...[
                    TextField(
                      controller: _manualController,
                      maxLines: 3,
                      enabled: !busy,
                      decoration: InputDecoration(hintText: placeholder, isDense: true),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: !busy && _manualController.text.trim().isNotEmpty
                          ? () => _submit(_manualController.text.trim())
                          : null,
                      child: const Text('Consultar'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Não foi possível abrir a câmera. Cole o código manualmente abaixo.',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
