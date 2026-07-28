/// Turns a scanned QR string into what `/api/nfce` needs.
///
/// QR content is a SEFAZ-PR URL: `…qrcode?p=<chave>|<versão>|<tpAmb>|<hash>`.
/// The 44-digit chave is field 0, but [p] must be the **whole** signed
/// payload — a bare chave passes this same length check but SEFAZ answers a
/// summary page with no items. Also accepts a raw `p` payload or a bare
/// 44-digit key, which is what the manual-paste fallback sends.
({String accessKey, String p})? parseQrPayload(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final idx = raw.indexOf('p=');
  final p = _safeDecode(idx == -1 ? raw : raw.substring(idx + 2));
  final accessKey = p.split('|').first.replaceAll(RegExp(r'\D'), '');
  return accessKey.length == 44 ? (accessKey: accessKey, p: p) : null;
}

String _safeDecode(String s) {
  try {
    return Uri.decodeComponent(s);
  } catch (_) {
    return s;
  }
}
