import 'dart:convert';

import 'package:dosis/core/api/api_client.dart';
import 'package:dosis/core/api/token_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(Object? body, [int status = 200]) => http.Response.bytes(
      body == null ? const [] : utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> sessionJson({String uid = 'u1', String idToken = 'token-1', String refresh = 'refresh-1'}) => {
      'uid': uid,
      'id_token': idToken,
      'refresh_token': refresh,
      'expires_in': 3600,
      'is_anonymous': true,
      'email': null,
      'name': null,
      'email_verified': false,
    };

/// ApiClient com servidor falso. [handler] recebe cada requisição.
ApiClient fakeClient(Future<http.Response> Function(http.Request request) handler, {AuthTokens? session}) {
  final store = MemoryTokenStore();
  if (session != null) store.write(session);
  return ApiClient(baseUrl: 'http://api.test/api/v1', httpClient: MockClient(handler), tokenStore: store);
}

Map<String, dynamic> body(http.Request request) => jsonDecode(request.body) as Map<String, dynamic>;
