import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// Cliente HTTP da API do Dosis.
///
/// * Envia `Authorization: Bearer <id_token>` automaticamente.
/// * Se o token expirar (401), renova com o refresh token e repete a chamada uma vez.
/// * Converte erros da API em [ApiException] e falhas de rede em `network_error`.
class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    TokenStore? tokenStore,
    this.timeout = ApiConfig.timeout,
  })  : baseUrl = _trimSlash(baseUrl ?? ApiConfig.baseUrl),
        _http = httpClient ?? http.Client(),
        tokens = tokenStore ?? MemoryTokenStore();

  final String baseUrl;
  final Duration timeout;
  final TokenStore tokens;
  final http.Client _http;
  Completer<void>? _refreshing;

  Future<dynamic> get(String path, {Map<String, Object?>? query, bool auth = true}) =>
      _request('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _request('POST', path, body: body, auth: auth);

  Future<dynamic> patch(String path, {Object? body}) => _request('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _request('DELETE', path);

  /// Guarda os tokens de uma resposta de login/cadastro/refresh.
  Future<void> saveSession(Map<String, dynamic> session) => tokens.write(AuthTokens(
        uid: session['uid'] as String,
        idToken: session['id_token'] as String,
        refreshToken: session['refresh_token'] as String,
      ));

  Future<bool> get hasSession async => (await tokens.read()) != null;

  void close() => _http.close();

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    bool auth = true,
    bool retry = true,
  }) async {
    final session = auth ? await tokens.read() : null;
    final response = await _send(method, path, query: query, body: body, idToken: session?.idToken);

    if (response.statusCode == 401 && auth && retry && session != null) {
      await _refresh(session);
      return _request(method, path, query: query, body: body, auth: auth, retry: false);
    }
    if (response.statusCode >= 400) throw _toException(response);
    if (response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    String? idToken,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query == null
          ? null
          : {
              for (final entry in query.entries)
                if (entry.value != null) entry.key: _queryValue(entry.value),
            },
    );
    final request = http.Request(method, uri)..headers['Accept'] = 'application/json';
    if (idToken != null) request.headers['Authorization'] = 'Bearer $idToken';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      final streamed = await _http.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } on SocketException catch (e) {
      throw ApiException.network(e);
    } on TimeoutException catch (e) {
      throw ApiException.network(e);
    } on http.ClientException catch (e) {
      throw ApiException.network(e);
    }
  }

  /// Renova o id_token. Chamadas simultâneas esperam a mesma renovação.
  Future<void> _refresh(AuthTokens session) async {
    final running = _refreshing;
    if (running != null) return running.future;
    final completer = _refreshing = Completer<void>();
    completer.future.ignore(); // quem chamou recebe o erro pelo rethrow abaixo
    try {
      final response = await _send('POST', '/auth/refresh/', body: {'refresh_token': session.refreshToken});
      if (response.statusCode >= 400) {
        await tokens.clear();
        throw _toException(response);
      }
      await saveSession(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
      completer.complete();
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _refreshing = null;
    }
  }

  static ApiException _toException(http.Response response) {
    try {
      final error = (jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>)['error']
          as Map<String, dynamic>;
      return ApiException(
        statusCode: response.statusCode,
        code: error['code'] as String? ?? 'error',
        message: error['message'] as String? ?? 'Erro inesperado.',
        details: error['details'],
      );
    } catch (_) {
      return ApiException(
        statusCode: response.statusCode,
        code: 'http_${response.statusCode}',
        message: 'Erro inesperado no servidor (${response.statusCode}).',
      );
    }
  }

  static String _queryValue(Object? value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value.toString();
  }

  static String _trimSlash(String url) => url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
