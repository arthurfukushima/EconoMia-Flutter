import 'package:freezed_annotation/freezed_annotation.dart';

import 'precos.dart';

part 'receipt.freezed.dart';
part 'receipt.g.dart';

/// The store and totals block of an NFC-e, as parsed from the SEFAZ-PR consulta.
/// Every field is optional because it is scraped from an HTML page whose layout
/// we do not control — a missing CNPJ must not cost the user their items.
@freezed
abstract class ReceiptHeader with _$ReceiptHeader {
  const factory ReceiptHeader({
    String? cnpj,
    String? storeName,
    String? city,
    String? address,

    /// `"DD/MM/YYYY HH:mm:ss"`, exactly as the consulta prints it.
    String? purchasedAt,

    /// "Valor a pagar", never the first total on the page (that one is the item
    /// count) and never the pre-discount subtotal.
    @Default(0) int totalCents,
  }) = _ReceiptHeader;

  factory ReceiptHeader.fromJson(Map<String, dynamic> json) =>
      _$ReceiptHeaderFromJson(json);
}

/// One line of the receipt, plus whatever pricing was later stamped onto it.
@freezed
abstract class ReceiptItem with _$ReceiptItem {
  const factory ReceiptItem({
    required String description,

    /// Null for weighed/PLU lines and anything the consulta marks "SEM GTIN".
    String? gtin,
    @Default(1.0) double qty,

    /// `UN`, `KG`, … The per-UN vs per-KG distinction is the produce
    /// false-match trap, so this travels with the item everywhere.
    String? unit,
    @Default(0) int unitPriceCents,
    @Default(0) int lineTotalCents,

    /// Cheapest-nearby result. Null means **uncompared** — the price lookup
    /// failed or found nothing — which is a state the report shows honestly
    /// rather than treating as "no savings available".
    Precos? precos,

    /// Fiscal NCM, stamped from the matched product during enrichment so
    /// classification is deterministic on re-open.
    String? ncm,
  }) = _ReceiptItem;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) =>
      _$ReceiptItemFromJson(json);
}

/// A scanned nota, from `/api/nfce` and then from disk forever after.
///
/// Saved receipts open and render with no network at all; pricing is skipped
/// when [enrichedAt] is set and re-run when the user's CEP has moved away from
/// [locationCep].
@freezed
abstract class Receipt with _$Receipt {
  const factory Receipt({
    /// The 44-digit chave de acesso. Also the record key in the `receipts`
    /// store, which is what makes re-scanning the same nota idempotent.
    required String accessKey,
    @Default(ReceiptHeader()) ReceiptHeader header,
    @Default(<ReceiptItem>[]) List<ReceiptItem> items,

    /// Epoch ms, stamped on first save. History sorts on it, newest first.
    int? createdAt,

    /// Epoch ms of the last successful pricing pass; null while unpriced.
    int? enrichedAt,

    /// The CEP the prices were fetched for. A different CEP now means the
    /// savings figure is about somewhere the user no longer is.
    String? locationCep,
  }) = _Receipt;

  factory Receipt.fromJson(Map<String, dynamic> json) => _$ReceiptFromJson(json);
}
