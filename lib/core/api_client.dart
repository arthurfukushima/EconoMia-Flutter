import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_config.dart';

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
  // The backend rejects a batch of offers naming another state as decoy data
  // fed to serverless egress IPs (see EconomiaApi._fetchMenorPrecoDirect) —
  // from the user's point of view this is the same "couldn't price it" story.
  'produtos_implausible': 'Falha ao consultar os preços da região.',
  'missing_local_or_query': 'Defina sua localização para comparar preços.',
  'network_failed': 'Sem conexão. Verifique a internet e tente de novo.',
  'bad_response': 'Resposta inesperada do servidor.',
};

/// GET/POST + decode, and not much else.
///
/// `/api/precos` needs a second call target: on a cache miss the backend
/// answers `{needsFetch: true}` rather than fetching Menor Preço itself
/// (Vercel's serverless egress IP gets fed fabricated decoy data there — see
/// EconomiaApi), so the device fetches the upstream directly and POSTs the
/// result back. [getJson]/[postJson] talk to our own backend and decode its
/// `{error: "<code>"}` convention; [getExternal] is the lower-level call used
/// for that one external host, which follows no such convention.
class ApiClient {
  /// [config] carries the host and the timeout; both default to the built-in
  /// [AppConfig.fallback] so a test can construct a client with nothing but a
  /// mock transport.
  ApiClient({http.Client? client, ApiConfig? config})
      : _client = client ?? http.Client(),
        _config = config ?? AppConfig.fallback.api;

  final http.Client _client;
  final ApiConfig _config;

  String get baseUrl => _config.baseUrl;

  /// Menor Preço is scraped live behind `/api/precos`, so a call can genuinely
  /// take tens of seconds. Long, but bounded — an unbounded request is a
  /// spinner that never stops.
  Duration get _timeout => _config.timeout;

  Future<Map<String, dynamic>> getJson(String path, [Map<String, String> query = const {}]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final res = await _request(() => _client.get(uri, headers: const {'User-Agent': 'EconoMia/1.0'}));
    return _decodeOurApi(res);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, String> query,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final res = await _request(() => _client.post(
          uri,
          headers: const {
            'User-Agent': 'EconoMia/1.0',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        ));
    return _decodeOurApi(res);
  }

  /// A raw GET to a host outside [baseUrl] — used only for the Menor Preço
  /// upstream fetch, which must come from the device's own IP rather than
  /// through our backend (see `EconomiaApi._fetchMenorPrecoDirect`). No
  /// custom headers: keeping this a CORS "simple request" is what lets it
  /// work from Flutter Web too, where a non-simple request would need a
  /// preflight this third-party host has no reason to answer.
  Future<http.Response> getExternal(Uri uri, {Duration timeout = const Duration(seconds: 30)}) async {
    try {
      return await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const ApiException('network_failed', detail: 'timeout');
    } on Exception catch (e) {
      throw ApiException('network_failed', detail: '$e');
    }
  }

  Future<http.Response> _request(Future<http.Response> Function() send) async {
    try {
      return await send().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('network_failed', detail: 'timeout');
    } on Exception catch (e) {
      throw ApiException('network_failed', detail: '$e');
    }
  }

  // `res.body` decodes with the charset from the response header and falls
  // back to latin-1 — which mangles "Paraná" and every accented store name.
  // The API is always UTF-8, so decode it as such.
  Map<String, dynamic> _decodeOurApi(http.Response res) {
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
