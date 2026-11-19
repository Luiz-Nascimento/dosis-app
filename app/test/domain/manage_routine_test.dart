import 'package:dosis/core/api/token_store.dart';
import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/repositories/api_catalog_repository.dart';
import 'package:dosis/data/repositories/api_routine_repository.dart';
import 'package:dosis/data/repositories/fake_catalog_repository.dart';
import 'package:dosis/data/repositories/fake_repositories.dart';
import 'package:dosis/data/services/catalog_service.dart';
import 'package:dosis/data/services/tracking_services.dart';
import 'package:dosis/domain/usecases/manage_routine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const _session = AuthTokens(uid: 'u1', idToken: 't', refreshToken: 'r');

Map<String, dynamic> _routineItemJson(String id, String productId, String name) => {
      'id': id,
      'product_id': productId,
      'name': name,
      'brand': null,
      'kind': 'supplement',
      'protocol': 'continuous',
      'dose_amount': 1000.0,
      'dose_unit': 'mg',
      'schedule_times': <String>[],
      'start_date': null,
      'end_date': null,
      'active': true,
      'notes': null,
    };

void main() {
  group('AddToRoutine', () {
    test('adiciona o produto com os dados do catálogo', () async {
      final routine = FakeRoutineRepository();

      final item = await AddToRoutine(routine)(productId: 'omega-3');

      expect(item.name, 'Ômega 3');
      expect(item.doseAmount, 1000);
      expect(item.doseUnit, DoseUnit.mg);
      expect(item.active, isTrue);
      expect((await routine.list(active: true)).map((i) => i.id), contains(item.id));
    });

    test('recusa produto que já está na rotina', () async {
      final routine = FakeRoutineRepository(); // já começa com creatina

      expect(
        () => AddToRoutine(routine)(productId: 'creatina'),
        throwsA(isA<RoutineException>().having((e) => e.message, 'message', contains('já está na sua rotina'))),
      );
    });

    test('recusa id vazio', () async {
      expect(() => AddToRoutine(FakeRoutineRepository())(productId: ' '), throwsA(isA<RoutineException>()));
    });
  });

  test('RemoveFromRoutine tira o item do stack', () async {
    final routine = FakeRoutineRepository();
    final item = await AddToRoutine(routine)(productId: 'bcaa');

    await RemoveFromRoutine(routine)(item.id);

    expect((await routine.list()).map((i) => i.id), isNot(contains(item.id)));
  });

  group('FakeCatalogRepository.search', () {
    final catalog = FakeCatalogRepository();

    test('busca ignora acentos e maiúsculas', () async {
      final result = await catalog.search(query: 'OMEGA');
      expect(result.results.map((p) => p.id), ['omega-3']);
    });

    test('filtra pelo tipo', () async {
      final result = await catalog.search(kind: ProductKind.anabolic, pageSize: 10);
      expect(result.results, isNotEmpty);
      expect(result.results.every((p) => p.kind == ProductKind.anabolic), isTrue);
    });

    test('pagina os resultados', () async {
      final first = await catalog.search(kind: ProductKind.supplement, pageSize: 4);
      final second = await catalog.search(kind: ProductKind.supplement, page: 2, pageSize: 4);

      expect(first.count, 6);
      expect(first.results, hasLength(4));
      expect(second.results, hasLength(2));
      expect(second.results.map((p) => p.id), isNot(anyElement(isIn(first.results.map((p) => p.id)))));
    });
  });

  group('API', () {
    test('adicionar à rotina manda só o id e o product_id', () async {
      final api = fakeClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/tracking/routine-items/');
        final sent = body(request);
        expect(sent.keys, unorderedEquals(['id', 'product_id']));
        expect(sent['product_id'], 'omega-3');
        return jsonResponse(_routineItemJson(sent['id'] as String, 'omega-3', 'Ômega 3'), 201);
      }, session: _session);

      final item = await ApiRoutineRepository(RoutineService(api)).add(productId: 'omega-3');
      expect(item.name, 'Ômega 3');
    });

    test('remover da rotina usa DELETE no item', () async {
      final api = fakeClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/tracking/routine-items/item1234/');
        return jsonResponse(null, 204);
      }, session: _session);

      await ApiRoutineRepository(RoutineService(api)).remove('item1234');
    });

    test('busca no catálogo repassa tipo, texto e página', () async {
      final api = fakeClient((request) async {
        expect(request.url.path, '/api/v1/catalog/products/');
        expect(request.url.queryParameters, {'kind': 'supplement', 'search': 'omega', 'page': '2', 'page_size': '4'});
        return jsonResponse({'count': 0, 'page': 2, 'page_size': 4, 'results': <Object>[]});
      }, session: _session);

      final result = await ApiCatalogRepository(CatalogService(api))
          .search(kind: ProductKind.supplement, query: '  omega ', page: 2);
      expect(result.count, 0);
    });
  });
}
