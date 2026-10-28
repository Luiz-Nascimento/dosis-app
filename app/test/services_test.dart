import 'package:dosis/core/api/token_store.dart';
import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/services/auth_service.dart';
import 'package:dosis/data/services/catalog_service.dart';
import 'package:dosis/data/services/profile_service.dart';
import 'package:dosis/data/services/tracking_services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const session = AuthTokens(uid: 'u1', idToken: 't', refreshToken: 'r');

Map<String, dynamic> doseJson(Map<String, dynamic> overrides) => {
      'id': 'dose1234',
      'routine_item_id': 'item1234',
      'product_id': 'creatina',
      'name': 'Creatina monohidratada',
      'kind': 'supplement',
      'protocol': 'continuous',
      'amount': 3.0,
      'unit': 'g',
      'taken_at': '2026-09-20T08:00:00-03:00',
      'local_date': '2026-09-20',
      'notes': null,
      'created_at': '2026-09-20T08:00:01-03:00',
      'updated_at': '2026-09-20T08:00:01-03:00',
      ...overrides,
    };

void main() {
  test('login anônimo guarda a sessão', () async {
    final api = fakeClient((request) async {
      expect(request.headers.containsKey('Authorization'), isFalse);
      return jsonResponse(sessionJson(uid: 'abc'), 201);
    });
    final result = await AuthService(api).signInAnonymously();
    expect(result.isAnonymous, isTrue);
    expect((await api.tokens.read())!.uid, 'abc');
  });

  test('registrar dose só com o item da rotina (3 toques)', () async {
    final api = fakeClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/doses');
      expect(body(request), {'routine_item_id': 'item1234'});
      return jsonResponse(doseJson({}), 201);
    }, session: session);

    final dose = await DoseService(api).register(routineItemId: 'item1234');
    expect(dose.name, 'Creatina monohidratada');
    expect(dose.amount, 3);
    expect(dose.unit, DoseUnit.g);
    expect(dose.takenAt, DateTime.utc(2026, 9, 20, 11));
  });

  test('lista doses do dia de um item', () async {
    final api = fakeClient((request) async {
      expect(request.url.queryParameters, {
        'date_from': '2026-09-20',
        'date_to': '2026-09-20',
        'routine_item_id': 'item1234',
      });
      return jsonResponse({'results': [doseJson({})]});
    }, session: session);
    final day = DateTime(2026, 9, 20);
    final doses = await DoseService(api).list(from: day, to: day, routineItemId: 'item1234');
    expect(doses.single.localDate, '2026-09-20');
  });

  test('stack de hoje usa active=true', () async {
    final api = fakeClient((request) async {
      expect(request.url.queryParameters, {'active': 'true'});
      return jsonResponse({'results': []});
    }, session: session);
    expect(await RoutineService(api).list(active: true), isEmpty);
  });

  test('sintomas vão com os valores da API', () async {
    final api = fakeClient((request) async {
      expect(body(request), {
        'status': 'different',
        'symptoms': ['dizziness', 'other'],
        'other_description': 'Visão turva',
      });
      return jsonResponse({
        'id': 's1234567',
        'status': 'different',
        'symptoms': ['dizziness', 'other'],
        'other_description': 'Visão turva',
        'notes': null,
        'logged_at': '2026-09-20T21:00:00-03:00',
        'local_date': '2026-09-20',
      }, 201);
    }, session: session);
    final log = await SymptomService(api).create(
      status: SymptomStatus.different,
      symptoms: [Symptom.dizziness, Symptom.other],
      otherDescription: 'Visão turva',
    );
    expect(log.symptoms, [Symptom.dizziness, Symptom.other]);
  });

  test('perfil manda só os campos alterados', () async {
    final api = fakeClient((request) async {
      expect(request.method, 'PATCH');
      expect(body(request), {
        'weight_kg': 76.0,
        'goal': 'hypertrophy',
        'notifications': {'dose_reminders': false},
      });
      return jsonResponse({
        'uid': 'u1',
        'is_anonymous': true,
        'email': null,
        'name': null,
        'weight_kg': 76.0,
        'goal': 'hypertrophy',
        'notifications': {'dose_reminders': false, 'symptom_reminder': true},
      });
    }, session: session);
    final profile = await ProfileService(api).update(weightKg: 76, goal: Goal.hypertrophy, doseReminders: false);
    expect(profile.goal, Goal.hypertrophy);
    expect(profile.notifications.doseReminders, isFalse);
  });

  test('catálogo traz faixas de dose para o alerta', () async {
    final api = fakeClient((request) async {
      expect(request.url.queryParameters, {'search': 'creatina', 'page': '1', 'page_size': '20'});
      return jsonResponse({
        'count': 1,
        'page': 1,
        'page_size': 20,
        'results': [
          {
            'id': 'creatina',
            'name': 'Creatina monohidratada',
            'kind': 'supplement',
            'default_unit': 'g',
            'default_dose': 3,
            'caution': '...',
            'requires_medical_supervision': false,
            'sources': [],
            'dose_ranges': [
              {
                'protocol': 'continuous',
                'per': 'day',
                'min': 3,
                'max': 5,
                'unit': 'g',
                'note': 'Manutenção',
                'sources': [
                  {'id': 'issn', 'name': 'ISSN', 'citation': 'Kreider 2017', 'url': 'https://doi.org/x'},
                ],
              },
            ],
          },
        ],
      });
    }, session: session);
    final page = await CatalogService(api).listProducts(search: 'creatina');
    final range = page.results.single.rangeFor(Protocol.continuous)!;
    expect(range.isAbove(20), isTrue);
    expect(range.sources.single.name, 'ISSN');
    expect(page.hasNextPage, isFalse);
  });
}
