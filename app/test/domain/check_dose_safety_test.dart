import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/models/tracking.dart';
import 'package:dosis/data/repositories/fake_catalog_repository.dart';
import 'package:dosis/domain/repositories/dose_repository.dart';
import 'package:dosis/domain/usecases/check_dose_safety.dart';
import 'package:flutter_test/flutter_test.dart';

/// Doses já registradas, para testar a soma do dia.
class _DoseHistory implements DoseRepository {
  _DoseHistory([this.logs = const []]);

  final List<DoseLog> logs;

  @override
  Future<List<DoseLog>> list({DateTime? from, DateTime? to, String? routineItemId, int? limit}) async =>
      logs.where((l) => (from == null || !l.takenAt.isBefore(from)) && (to == null || !l.takenAt.isAfter(to))).toList();

  @override
  Future<DoseLog> register({required String routineItemId, double? amount, DateTime? takenAt, String? notes}) =>
      throw UnimplementedError();
}

RoutineItem _item(String id, String name, {String? productId, ProductKind kind = ProductKind.supplement, DoseUnit unit = DoseUnit.g}) =>
    RoutineItem(
      id: id,
      productId: productId,
      name: name,
      kind: kind,
      protocol: Protocol.continuous,
      doseUnit: unit,
      scheduleTimes: const [],
      active: true,
    );

DoseLog _taken(String productId, double amount, DateTime at, {DoseUnit unit = DoseUnit.g}) => DoseLog(
      id: 'd-$productId-${at.millisecondsSinceEpoch}',
      routineItemId: 'r-$productId',
      productId: productId,
      name: productId,
      kind: ProductKind.supplement,
      protocol: Protocol.continuous,
      amount: amount,
      unit: unit,
      takenAt: at,
      localDate: '',
    );

void main() {
  final today = DateTime(2026, 11, 12, 18);
  final creatina = _item('r-creatina', 'Creatina', productId: 'creatina');
  final whey = _item('r-whey', 'Whey Protein', productId: 'whey-protein');

  CheckDoseSafety check([List<DoseLog> history = const []]) =>
      CheckDoseSafety(FakeCatalogRepository(), _DoseHistory(history));

  group('Creatina (faixa por dia)', () {
    test('5 g sem outras doses no dia fica dentro da faixa de 3 a 5 g', () async {
      final result = await check()(item: creatina, amount: 5, protocol: Protocol.continuous, takenAt: today);

      expect(result.alert, DoseAlert.none);
      expect(result.totalToday, 5);
    });

    test('soma as doses do dia: 5 g de manhã + 5 g agora = 10 g, alerta', () async {
      final history = [_taken('creatina', 5, DateTime(2026, 11, 12, 8))];

      final result = await check(history)(item: creatina, amount: 5, protocol: Protocol.continuous, takenAt: today);

      expect(result.isAboveRange, isTrue);
      expect(result.totalToday, 10);
      expect(result.message, contains('Somando as doses de hoje'));
      expect(result.message, contains('3 a 5 g por dia'));
      expect(result.caution, contains('rins'));
      expect(result.sourcesFormatted, 'ISSN');
    });

    test('doses de ontem não entram na soma de hoje', () async {
      final history = [_taken('creatina', 5, DateTime(2026, 11, 11, 8))];

      final result = await check(history)(item: creatina, amount: 5, protocol: Protocol.continuous, takenAt: today);

      expect(result.alert, DoseAlert.none);
    });

    test('doses de outro produto não entram na soma', () async {
      final history = [_taken('whey-protein', 30, DateTime(2026, 11, 12, 8))];

      final result = await check(history)(item: creatina, amount: 5, protocol: Protocol.continuous, takenAt: today);

      expect(result.alert, DoseAlert.none);
    });

    test('saturação aceita até 25 g e alerta acima disso', () async {
      final ok = await check()(item: creatina, amount: 20, protocol: Protocol.loading, takenAt: today);
      final high = await check()(item: creatina, amount: 30, protocol: Protocol.loading, takenAt: today);

      expect(ok.alert, DoseAlert.none);
      expect(high.isAboveRange, isTrue);
      expect(high.range!.max, 25);
      expect(high.message, contains('saturação'));
    });

    test('converte mg para g (6000 mg = 6 g, acima de 5 g)', () async {
      final creatinaMg = _item('r-creatina', 'Creatina', productId: 'creatina', unit: DoseUnit.mg);

      final result = await check()(item: creatinaMg, amount: 6000, protocol: Protocol.continuous, takenAt: today);

      expect(result.isAboveRange, isTrue);
      expect(result.totalToday, 6);
    });
  });

  group('Whey (faixa por tomada)', () {
    test('60 g numa tomada passa da faixa de 20 a 40 g', () async {
      final result = await check()(item: whey, amount: 60, protocol: Protocol.continuous, takenAt: today);

      expect(result.isAboveRange, isTrue);
      expect(result.message, contains('por tomada'));
    });

    test('duas tomadas de 30 g no dia não somam (a faixa é por tomada)', () async {
      final history = [_taken('whey-protein', 30, DateTime(2026, 11, 12, 8))];

      final result = await check(history)(item: whey, amount: 30, protocol: Protocol.continuous, takenAt: today);

      expect(result.alert, DoseAlert.none);
    });
  });

  group('Anabolizantes', () {
    test('sempre pedem acompanhamento médico, com as fontes do catálogo', () async {
      final testosterona = _item('r-t', 'Testosterona', productId: 'testosterona', kind: ProductKind.anabolic, unit: DoseUnit.mg);

      final result = await check()(item: testosterona, amount: 1, protocol: Protocol.cycle, takenAt: today);

      expect(result.requiresMedicalSupervision, isTrue);
      expect(result.caution, contains('prescrição'));
      expect(result.sourcesFormatted, contains('CFM'));
    });

    test('anabolizante cadastrado à mão (fora do catálogo) também avisa', () async {
      final outro = _item('r-x', 'Estanozolol', kind: ProductKind.anabolic, unit: DoseUnit.mg);

      final result = await check()(item: outro, amount: 1, protocol: Protocol.cycle, takenAt: today);

      expect(result.requiresMedicalSupervision, isTrue);
      expect(result.caution, anabolicFallbackCaution);
    });
  });

  group('Sem como comparar', () {
    test('produto fora do catálogo não gera alerta', () async {
      final result = await check()(item: _item('r-x', 'Cafeína'), amount: 999, protocol: Protocol.continuous, takenAt: today);

      expect(result.alert, DoseAlert.none);
    });

    test('unidade que não converte (cápsulas x gramas) não gera alerta', () async {
      final caps = _item('r-c', 'Creatina', productId: 'creatina', unit: DoseUnit.caps);

      final result = await check()(item: caps, amount: 50, protocol: Protocol.continuous, takenAt: today);

      expect(result.alert, DoseAlert.none);
    });
  });

  test('convertDose converte g, mg e mcg e recusa o resto', () {
    expect(convertDose(1, DoseUnit.g, DoseUnit.mg), 1000);
    expect(convertDose(500, DoseUnit.mcg, DoseUnit.mg), 0.5);
    expect(convertDose(2, DoseUnit.caps, DoseUnit.g), isNull);
  });
}
