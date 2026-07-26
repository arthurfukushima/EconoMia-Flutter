import 'dart:math' as math;

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

  // Populated once the device's lenses are known — see _loadZoomLevels.
  List<_ZoomLevel> _zoomLevels = const [];
  int _zoomIndex = 0;

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
      _loadZoomLevels();
    }
  }

  // mobile_scanner only exposes three lens *categories* (wide/normal/zoom),
  // not the exact focal multiplier a phone's camera app shows — so this maps
  // onto the closest of those a given device reports, per CLAUDE.md's ask:
  // 0.6/1/3/5 on a triple-camera phone, 1/5 (digital only) on a single lens.
  Future<void> _loadZoomLevels() async {
    final camera = _camera;
    if (camera == null) return;
    Set<CameraLensType> supported;
    try {
      supported = await camera.getSupportedLenses(facing: CameraFacing.back);
    } catch (_) {
      supported = const {};
    }
    final levels = <_ZoomLevel>[
      if (supported.contains(CameraLensType.wide))
        const _ZoomLevel('0.6', CameraLensType.wide, 0),
      const _ZoomLevel('1', CameraLensType.normal, 0),
      if (supported.contains(CameraLensType.zoom)) ...[
        const _ZoomLevel('3', CameraLensType.zoom, 0),
        const _ZoomLevel('5', CameraLensType.zoom, 1),
      ] else if (!supported.contains(CameraLensType.wide))
        const _ZoomLevel('5', CameraLensType.normal, 1),
    ];
    if (!mounted) return;
    setState(() {
      _zoomLevels = levels;
      _zoomIndex = levels.indexWhere((l) => l.label == '1').clamp(0, levels.length - 1);
    });
  }

  Future<void> _selectZoom(int index) async {
    final camera = _camera;
    if (camera == null || index == _zoomIndex) return;
    final level = _zoomLevels[index];
    if (level.lensType != camera.value.cameraLensType) {
      await camera.switchCamera(
        SelectCamera(facingDirection: CameraFacing.back, lensType: level.lensType),
      );
    }
    await camera.setZoomScale(level.zoomScale);
    if (!mounted) return;
    setState(() => _zoomIndex = index);
  }

  // Flipping to the front camera and back drops whatever lens/zoom was
  // selected — the platform restarts on default lens — so the chip
  // highlight is reset to '1' rather than pointing at a stale selection.
  Future<void> _flipCamera() async {
    await _camera!.switchCamera();
    if (!mounted) return;
    setState(() => _zoomIndex = _zoomLevels.indexWhere((l) => l.label == '1').clamp(0, _zoomLevels.length - 1));
  }

  @override
  void dispose() {
    _camera?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  // A square for the QR nota flow, a wider band for the elongated EAN
  // barcodes on a product — both centred over the preview.
  Rect _frameRect(Size size) {
    final shortSide = math.min(size.width, size.height);
    final frameSize = widget.mode == ScanMode.nota
        ? Size.square(shortSide * 0.72)
        : Size(shortSide * 0.88, shortSide * 0.5);
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: frameSize.width,
      height: frameSize.height,
    );
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                final frame = _frameRect(size);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _camera!,
                      onDetect: _onDetect,
                      scanWindow: frame,
                      errorBuilder: (context, error) => const _CameraUnavailable(),
                    ),
                    IgnorePointer(
                      child: CustomPaint(
                        size: size,
                        painter: _ScanFrameOverlay(frame: frame, lineColor: sa.danger),
                      ),
                    ),
                    if (busy)
                      ColoredBox(
                        color: const Color(0x99000000),
                        child: Center(child: CircularProgressIndicator(color: sa.amber)),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        top: false,
                        child: _CameraControls(
                          camera: _camera!,
                          zoomLevels: _zoomLevels,
                          zoomIndex: _zoomIndex,
                          onZoomSelected: _selectZoom,
                          onFlip: _flipCamera,
                        ),
                      ),
                    ),
                  ],
                );
              },
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

/// One entry in the zoom chip row — a lens to switch to plus the digital
/// zoom scale within it. See _ScanScreenState._loadZoomLevels for how the
/// set of levels is derived from what the device actually reports.
class _ZoomLevel {
  const _ZoomLevel(this.label, this.lensType, this.zoomScale);

  final String label;
  final CameraLensType lensType;
  final double zoomScale;
}

/// Darkens everything outside [frame], outlines its corners, and draws a
/// centre reference line — the "point the cupom here" affordance.
class _ScanFrameOverlay extends CustomPainter {
  const _ScanFrameOverlay({required this.frame, required this.lineColor});

  final Rect frame;
  final Color lineColor;

  static const _cornerLength = 26.0;
  static const _cornerRadius = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final holePath = Path()..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(_cornerRadius)));
    final scrimPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      holePath,
    );
    canvas.drawPath(scrimPath, Paint()..color = const Color(0x99000000));

    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    void corner(Offset from, Offset h, Offset v) {
      canvas.drawLine(from, from + h, cornerPaint);
      canvas.drawLine(from, from + v, cornerPaint);
    }

    const l = _cornerLength;
    corner(frame.topLeft, const Offset(l, 0), const Offset(0, l));
    corner(frame.topRight, const Offset(-l, 0), const Offset(0, l));
    corner(frame.bottomLeft, const Offset(l, 0), const Offset(0, -l));
    corner(frame.bottomRight, const Offset(-l, 0), const Offset(0, -l));

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.85)
      ..strokeWidth = 2;
    final lineY = frame.center.dy;
    canvas.drawLine(Offset(frame.left + 10, lineY), Offset(frame.right - 10, lineY), linePaint);
  }

  @override
  bool shouldRepaint(covariant _ScanFrameOverlay oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.lineColor != lineColor;
}

/// Zoom chips plus flash/flip, floating over the bottom of the preview —
/// mirrors the native camera app controls the phone's own Camera app shows.
class _CameraControls extends StatelessWidget {
  const _CameraControls({
    required this.camera,
    required this.zoomLevels,
    required this.zoomIndex,
    required this.onZoomSelected,
    required this.onFlip,
  });

  final MobileScannerController camera;
  final List<_ZoomLevel> zoomLevels;
  final int zoomIndex;
  final ValueChanged<int> onZoomSelected;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: camera,
      builder: (context, state, child) {
        if (!state.isRunning) return const SizedBox.shrink();

        final showZoom = zoomLevels.length > 1 && state.cameraDirection == CameraFacing.back;
        final showFlip = (state.availableCameras ?? 2) >= 2;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showZoom) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < zoomLevels.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _ZoomChip(
                          label: zoomLevels[i].label,
                          active: i == zoomIndex,
                          onTap: () => onZoomSelected(i),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (state.torchState != TorchState.unavailable)
                    _CircleIconButton(
                      icon: state.torchState == TorchState.off ? Icons.flash_off : Icons.flash_on,
                      onTap: camera.toggleTorch,
                    )
                  else
                    const SizedBox(width: 44),
                  if (showFlip)
                    _CircleIconButton(icon: Icons.cameraswitch, onTap: onFlip)
                  else
                    const SizedBox(width: 44),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ZoomChip extends StatelessWidget {
  const _ZoomChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SaMotion.fast,
        width: active ? 40 : 32,
        height: active ? 40 : 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.white : const Color(0x66000000),
          border: Border.all(color: Colors.white54, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          '${label}x',
          style: TextStyle(
            color: active ? Colors.black : Colors.white,
            fontSize: active ? 13 : 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x66000000),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
