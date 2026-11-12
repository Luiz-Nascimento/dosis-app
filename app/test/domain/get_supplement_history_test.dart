import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/models/tracking.dart';
import 'package:dosis/data/repositories/fake_catalog_repository.dart';
import 'package:dosis/domain/repositories/dose_repository.dart';
import 'package:dosis/domain/usecases/get_supplement_history.dart';
import 'package:flutter_test/flutter_test.dart';

class _Doses implements DoseRepository {
  _Doses(this.logs);

  final List<DoseLog> logs;
  int? lastLimit;

  @override
  Future<List<DoseLog>> list({DateTime? from, DateTime? to, String? routineItemId, int? limit}) async {
    lastLimit = limit;
    return logs;
  }

  @override
  Future<DoseLog> register({required String routineItemId, double? amount, DateTime? takenAt, String? notes}) =>
      throw UnimplementedError();
}

DoseLog _dose(String name, double amount, DateTime at, {String? productId, DoseUnit unit = DoseUnit.g}) => DoseLog(
      id: '$name-${at.microsecondsSinceEpoch}',
      productId: productId,
      name: name,
      kind: ProductKind.supplement,
      protocol: Protocol.continuous,
      amount: amount,
      unit: unit,
      takenAt: at,
      localDate: '',
    );

void main() {
  final now = DateTime(2026, 11, 12, 20);

  Future<List<SupplementHistory>> history(List<DoseLog> logs, {int days = 7}) =>
      GetSupplementHistory(_Doses(logs), FakeCatalogRepository())(days: days, now: now);

  test('agrupa por suplemento e soma as doses de cada dia', () async {
    final result = await history([
      _dose('Creatina', 3, DateTime(2026, 11, 12, 8), productId: 'creatina'),
      _dose('Creatina', 2, DateTime(2026, 11, 12, 18), productId: 'creatina'),
      _dose('Creatina', 5, DateTime(2026, 11, 10, 8), productId: 'creatina'),
      _dose('Whey Protein', 30, DateTime(2026, 11, 11, 12), productId: 'whey-protein'),
    ]);

    expect(result.map((h) => h.name), ['Creatina', 'Whey Protein']);
    final creatina = result.first;
    expect(creatina.days, hasLength(7));
    expect(creatina.days.first.day, DateTime(2026, 11, 6));
    expect(creatina.days.last.total, 5); // 3 + 2 no dia 12
    expect(creatina.days.last.count, 2);
    expect(creatina.days[4].total, 5); // dia 10
    expect(creatina.days[5].total, 0); // dia 11 sem dose
    expect(creatina.total, 10);
    expect(creatina.daysTaken, 2);
    expect(creatina.averagePerDayTaken, 5);
    expect(creatina.logs.first.takenAt, DateTime(2026, 11, 12, 18));
  });

  test('traz a faixa diária do catálogo e conta os dias acima dela', () async {
    final result = await history([
      _dose('Creatina', 5, DateTime(2026, 11, 12, 8), productId: 'creatina'),
      _dose('Creatina', 5, DateTime(2026, 11, 12, 20), productId: 'creatina'),
      _dose('Creatina', 5, DateTime(2026, 11, 11, 8), productId: 'creatina'),
    ]);

    expect(result.single.referenceMin, 3);
    expect(result.single.referenceMax, 5);
    expect(result.single.daysAboveReference, 1); // só o dia 12 (10 g)
  });

  test('faixa por tomada (whey) e itens fora do catálogo não têm linha de referência', () async {
    final result = await history([
      _dose('Whey Protein', 60, DateTime(2026, 11, 12, 12), productId: 'whey-protein'),
      _dose('Cafeína', 200, DateTime(2026, 11, 12, 7), unit: DoseUnit.mg),
    ]);

    expect(result.every((h) => h.referenceMax == null), isTrue);
    expect(result.every((h) => h.daysAboveReference == 0), isTrue);
  });

  test('converte registros em mg para a unidade do registro mais recente', () async {
    final result = await history([
      _dose('Creatina', 3, DateTime(2026, 11, 12, 18), productId: 'creatina'),
      _dose('Creatina', 2000, DateTime(2026, 11, 12, 8), productId: 'creatina', unit: DoseUnit.mg),
    ]);

    expect(result.single.unit, DoseUnit.g);
    expect(result.single.days.last.total, 5);
  });

  test('ignora doses fora do período e pede o máximo de registros à API', () async {
    final doses = _Doses([
      _dose('Creatina', 5, DateTime(2026, 11, 5, 8), productId: 'creatina'), // 8 dias atrás
    ]);

    final result = await GetSupplementHistory(doses, FakeCatalogRepository())(days: 7, now: now);

    expect(result, isEmpty);
    expect(doses.lastLimit, 500);
  });

  test('recusa período sem dias', () {
    expect(() => history(const [], days: 0), throwsArgumentError);
  });
}
