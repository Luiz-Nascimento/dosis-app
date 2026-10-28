import 'dart:io';

import 'package:dosis/core/api/api_exception.dart';
import 'package:dosis/core/api/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const session = AuthTokens(uid: 'u1', idToken: 'velho', refreshToken: 'refresh-1');

void main() {
  test('envia o token Bearer e o JSON', () async {
    late String auth;
    final api = fakeClient((request) async {
      auth = request.headers['Authorization']!;
      expect(request.url.toString(), 'http://api.test/api/v1/hydration');
      expect(body(request), {'amount_ml': 500});
      return jsonResponse({'ok': true}, 201);
    }, session: session);

    expect(await api.post('/hydration', body: {'amount_ml': 500}), {'ok': true});
    expect(auth, 'Bearer velho');
  });

  test('ignora parâmetros nulos e formata datas na query', () async {
    final api = fakeClient((request) async {
      expect(request.url.queryParameters, {'limit': '10', 'since': '2026-09-20T11:00:00.000Z'});
      return jsonResponse({'results': []});
    });
    await api.get('/x', query: {'limit': 10, 'kind': null, 'since': DateTime.utc(2026, 9, 20, 11)}, auth: false);
  });

  test('converte o erro da API em ApiException', () async {
    final api = fakeClient((request) async => jsonResponse({
          'error': {
            'code': 'validation_error',
            'message': 'Dados inválidos.',
            'details': {'password': ['A senha precisa ter pelo menos um número.']},
          },
        }, 400));

    final error = await api.post('/auth/register', body: {}, auth: false).then<ApiException?>((_) => null,
        onError: (Object e) => e as ApiException);
    expect(error!.code, 'validation_error');
    expect(error.isValidationError, isTrue);
    expect(error.fieldErrors['password'], ['A senha precisa ter pelo menos um número.']);
  });

  test('falha de rede vira network_error', () async {
    final api = fakeClient((request) async => throw const SocketException('sem rede'));
    expect(
      () => api.get('/health', auth: false),
      throwsA(isA<ApiException>().having((e) => e.isNetworkError, 'isNetworkError', isTrue)),
    );
  });

  test('renova o token no 401 e repete a chamada', () async {
    final calls = <String>[];
    final api = fakeClient((request) async {
      calls.add('${request.url.path} ${request.headers['Authorization'] ?? '-'}');
      if (request.url.path.endsWith('/auth/refresh/')) {
        expect(body(request), {'refresh_token': 'refresh-1'});
        return jsonResponse(sessionJson(idToken: 'novo', refresh: 'refresh-2'));
      }
      if (request.headers['Authorization'] == 'Bearer velho') {
        return jsonResponse({'error': {'code': 'invalid_token', 'message': 'Token expirado.'}}, 401);
      }
      return jsonResponse({'uid': 'u1'});
    }, session: session);

    expect(await api.get('/auth/me'), {'uid': 'u1'});
    expect(calls, ['/api/v1/auth/me Bearer velho', '/api/v1/auth/refresh/ -', '/api/v1/auth/me Bearer novo']);
    expect((await api.tokens.read())!.refreshToken, 'refresh-2');
  });

  test('refresh recusado limpa a sessão', () async {
    final api = fakeClient((request) async =>
        jsonResponse({'error': {'code': 'invalid_token', 'message': 'Faça login novamente.'}}, 401), session: session);

    await expectLater(api.get('/auth/me'), throwsA(isA<ApiException>()));
    expect(await api.tokens.read(), isNull);
  });
}
