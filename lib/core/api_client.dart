import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// The deployed serverless functions. This app is a **client**: NFC-e parsing
/// and price scraping live behind these three endpoints and are never
/// re-implemented in Dart.
const kApiBase = 'https://econo-mia.vercel.app';

/// A failed call, carrying the backend's `snake_case` code rather than a
/// message — the code is what tests and control flow branch on, and [mensagem]
/// is the single place it becomes pt-BR the user can read.
class ApiException implements Exception {
  const ApiException(this.code, {this.detail, this.status});

  /// `invalid_cep`, `portal_unavailable`, … The backend answers every failure
  /// as `{error: "<snake_case>"}`; the geo codes are minted client-side by the
  /// location layer so that one map covers every error the user can see.
  final String code;

  /// Upstream detail, for logs. Never shown.
  final String? detail;

  /// HTTP status, when the failure was an HTTP one.
  final int? status;

  String get mensagem =>
      _mensagens[code] ??
      'Erro ao processar: ${code.length > 80 ? code.substring(0, 80) : code}';

  @override
  String toString() => 'ApiException($code${status == null ? '' : ' $status'}${detail == null ? '' : ': $detail'})';
}

/// Every error code the user can reach, in pt-BR. Carried over from the
/// reference implementation, with one adaptation: its "your browser doesn't
/// support location" string is meaningless on a phone, so `geo_unsupported`
/// speaks about the device instead.
const _mensagens = <String, String>{
  'invalid_access_key': 'Chave de acesso inválida.',
  'portal_unavailable': 'SEFAZ-PR indisponível no momento. Tente novamente.',
  'portal_fetch_failed': 'Falha ao consultar a SEFAZ-PR.',
  'no_items_parsed': 'Não foi possível ler os itens desta nota.',
  'invalid_cep': 'CEP inválido (8 dígitos).',
  'cep_no_coords': 'Não encontramos as coordenadas desse CEP. Tente um CEP próximo.',
  'cep_lookup_failed': 'Falha ao consultar o CEP.',
  'cep_failed': 'Falha ao consultar o CEP.',
  'coords_no_place': 'Não identificamos o endereço da sua localização.',
  'geo_denied': 'Permissão de localização negada. Use o CEP ou libere o acesso.',
  'geo_unsupported': 'Este aparelho não informa a localização. Use o CEP.',
  'geo_failed': 'Não foi possível obter sua localização. Tente de novo ou use o CEP.',
  'menorpreco_failed': 'Falha ao consultar os preços da região.',
  'missing_local_or_query': 'Defina sua localização para comparar preços.',
  'network_failed': 'Sem conexão. Verifique a internet e tente de novo.',
  'bad_response': 'Resposta inesperada do servidor.',
};

/// GET + decode, and nothing else. There are three endpoints, all GET, all
/// returning JSON — no interceptors, no retry policy, no multipart, which is
/// why this is `http` and a dozen lines rather than a full HTTP stack.
class ApiClient {
  ApiClient({http.Client? client, this.baseUrl = kApiBase})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// Menor Preço is scraped live behind `/api/precos`, so a call can genuinely
  /// take tens of seconds. Long, but bounded — an unbounded request is a
  /// spinner that never stops.
  static const _timeout = Duration(seconds: 45);

  Future<Map<String, dynamic>> getJson(String path, [Map<String, String> query = const {}]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);

    final http.Response res;
    try {
      res = await _client
          .get(uri, headers: const {'User-Agent': 'EconoMia/1.0'})
          .timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('network_failed', detail: 'timeout');
    } on Exception catch (e) {
      throw ApiException('network_failed', detail: '$e');
    }

    // `res.body` decodes with the charset from the response header and falls
    // back to latin-1 — which mangles "Paraná" and every accented store name.
    // The API is always UTF-8, so decode it as such.
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('bad_response', status: res.statusCode);
    }

    if (res.statusCode != 200) {
      throw ApiException(
        body['error'] as String? ?? 'request_failed_${res.statusCode}',
        detail: body['detail'] as String?,
        status: res.statusCode,
      );
    }
    return body;
  }

  void close() => _client.close();
}
