import 'package:dosis/core/api/api_exception.dart';
import 'package:dosis/core/api/token_store.dart';
import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/repositories/api_dose_repository.dart';
import 'package:dosis/data/repositories/fake_repositories.dart';
import 'package:dosis/data/services/tracking_services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import '../services_test.dart' show doseJson;

const _session = AuthTokens(uid: 'u1', idToken: 't', refreshToken: 'r');

Map<String, dynamic> _conflict() => {
      'error': {'code': 'already_exists', 'message': 'Já existe um registro com este id.', 'details': null},
    };

void main() {
  group('ApiDoseRepository', () {
    test('envia o id da tentativa no POST', () async {
      final api = fakeClient((request) async {
        expect(body(request)['id'], 'tentativa1');
        return jsonResponse(doseJson({'id': 'tentativa1'}), 201);
      }, session: _session);

      final dose = await ApiDoseRepository(DoseService(api)).register(id: 'tentativa1', routineItemId: 'item1234');

      expect(dose.id, 'tentativa1');
    });

    test('envia o protocolo escolhido na tela no POST', () async {
      final api = fakeClient((request) async {
        expect(body(request)['protocol'], 'loading');
        return jsonResponse(doseJson({'protocol': 'loading'}), 201);
      }, session: _session);

      final dose = await ApiDoseRepository(DoseService(api))
          .register(id: 'tentativa1', routineItemId: 'item1234', protocol: Protocol.loading);

      expect(dose.protocol, Protocol.loading);
    });

    test('sem id, gera um novo a cada registro', () async {
      final ids = <String>[];
      final api = fakeClient((request) async {
        ids.add(body(request)['id'] as String);
        return jsonResponse(doseJson({}), 201);
      }, session: _session);
      final repository = ApiDoseRepository(DoseService(api));

      await repository.register(routineItemId: 'item1234');
      await repository.register(routineItemId: 'item1234');

      expect(ids.toSet(), hasLength(2));
    });

    test('reenvio que já tinha chegado ao servidor (409) devolve a dose gravada', () async {
      final calls = <String>[];
      final api = fakeClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.method == 'POST') return jsonResponse(_conflict(), 409);
        return jsonResponse(doseJson({'id': 'tentativa1'}));
      }, session: _session);

      final dose = await ApiDoseRepository(DoseService(api)).register(id: 'tentativa1', routineItemId: 'item1234');

      expect(dose.id, 'tentativa1');
      expect(calls, ['POST /api/v1/tracking/doses/', 'GET /api/v1/tracking/doses/tentativa1/']);
    });

    test('outros erros continuam chegando à tela', () async {
      final api = fakeClient(
        (request) async => jsonResponse({
          'error': {'code': 'validation_error', 'message': 'Dados inválidos.', 'details': null},
        }, 400),
        session: _session,
      );

      expect(
        ApiDoseRepository(DoseService(api)).register(id: 'tentativa1', routineItemId: 'item1234'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });
  });

  group('FakeDoseRepository', () {
    test('repetir o id não duplica a dose', () async {
      final routine = FakeRoutineRepository();
      final doses = FakeDoseRepository(routine);
      final item = (await routine.list()).first;
      final before = (await doses.list()).length;

      final first = await doses.register(id: 'tentativa1', routineItemId: item.id, amount: 5);
      final again = await doses.register(id: 'tentativa1', routineItemId: item.id, amount: 5);

      expect(again.id, first.id);
      expect(await doses.list(), hasLength(before + 1));
    });

    test('grava o protocolo escolhido; sem ele, vale o do item', () async {
      final routine = FakeRoutineRepository();
      final doses = FakeDoseRepository(routine);
      final item = (await routine.list()).first;

      final chosen = await doses.register(routineItemId: item.id, amount: 20, protocol: Protocol.loading);
      final fromItem = await doses.register(routineItemId: item.id, amount: 5);

      expect(chosen.protocol, Protocol.loading);
      expect(fromItem.protocol, item.protocol);
    });
  });
}
