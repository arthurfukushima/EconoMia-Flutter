import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/api_client.dart';
import '../../data/economia_api.dart';
import '../../data/receipt_repository.dart';
import 'qr_payload.dart';
import 'scan_mode.dart';

/// Where a decoded scan leads.
enum ScanTarget { receipt, produto }

class ScanResult {
  const ScanResult(this.target, this.value);

  final ScanTarget target;

  /// The access key for [ScanTarget.receipt], the barcode for
  /// [ScanTarget.produto].
  final String value;
}

/// A scan/paste in flight.
final scanBusyProvider = StateProvider<bool>((ref) => false);

/// The last "couldn't make sense of this" message, pt-BR, cleared at the
/// start of every new attempt. Distinct from [ApiException]: nothing here has
/// a backend code, it's a client-side read of what was scanned.
final scanErrorProvider = StateProvider<String?>((ref) => null);

final scanControllerProvider = NotifierProvider<ScanController, void>(ScanController.new);

/// Turns whatever the camera or the manual-paste fallback produced into
/// somewhere to go.
///
/// Routing is content-based, never mode-based: a 44-digit chave always means
/// Receipt and an 8–14 digit code always means Produto, regardless of which
/// mode the chooser opened — so a mis-tap still lands correctly.
class ScanController extends Notifier<void> {
  @override
  void build() {}

  Future<ScanResult?> submit(String raw, ScanMode mode) async {
    ref.read(scanErrorProvider.notifier).state = null;

    final parsed = parseQrPayload(raw);
    if (parsed == null) {
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (RegExp(r'^\d{8,14}$').hasMatch(digits)) {
        return ScanResult(ScanTarget.produto, digits);
      }
      ref.read(scanErrorProvider.notifier).state = mode == ScanMode.nota
          ? 'Não reconheci o QR da nota. Aponte para o QR ou cole a chave de 44 dígitos.'
          : 'Não reconheci o código de barras. Aponte para o código ou digite-o.';
      return null;
    }

    ref.read(scanBusyProvider.notifier).state = true;
    try {
      final repo = ref.read(receiptRepositoryProvider);
      // Re-scanning a saved nota reads local and never re-hits the portal.
      var receipt = await repo.getReceipt(parsed.accessKey);
      receipt ??= await repo.saveReceipt(
        await ref.read(economiaApiProvider).fetchReceipt(parsed.p),
      );
      return ScanResult(ScanTarget.receipt, receipt.accessKey);
    } on ApiException catch (e) {
      ref.read(scanErrorProvider.notifier).state = e.mensagem;
      return null;
    } finally {
      ref.read(scanBusyProvider.notifier).state = false;
    }
  }
}
