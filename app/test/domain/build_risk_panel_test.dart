import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/models/tracking.dart';
import 'package:dosis/data/repositories/fake_catalog_repository.dart';
import 'package:dosis/data/repositories/fake_repositories.dart';
import 'package:dosis/domain/repositories/dose_repository.dart';
import 'package:dosis/domain/usecases/build_risk_panel.dart';
import 'package:flutter_test/flutter_test.dart';

class _Doses implements DoseRepository {
  _Doses(this.logs);

  final List<DoseLog> logs;

  @override
  Future<List<DoseLog>> list({DateTime? from, DateTime? to, String? routineItemId, int? limit}) async => logs;

  @override
  Future<DoseLog> register({required String routineItemId, double? amount, DateTime? takenAt, String? notes}) =>
      throw UnimplementedError();
}

DoseLog _dose(
  String name,
  double amount,
  DateTime at, {
  String? productId,
  DoseUnit unit = DoseUnit.g,
  ProductKind kind = ProductKind.supplement,
}) =>
    DoseLog(
      id: '$name-${at.microsecondsSinceEpoch}',
      productId: productId,
      name: name,
      kind: kind,
      protocol: Protocol.continuous,
      amount: amount,
      unit: unit,
      takenAt: at,
      localDate: '',
    );

void main() {
  final now = DateTime(2026, 11, 12, 20);
  late FakeSymptomRepository symptoms;

  setUp(() => symptoms = FakeSymptomRepository());

  Future<RiskPanel> panel(List<DoseLog> doses) =>
      BuildRiskPanel(_Doses(doses), FakeCatalogRepository(), symptoms)(now: now);

  test('sem registros: nenhum indicador de dose e nível ok', () async {
    final result = await panel(const []);

    expect(result.doses, isEmpty);
    expect(result.level, RiskLevel.ok);
    expect(result.symptoms.title, contains('nenhum registro'));
    expect(result.from, DateTime(2026, 11, 6));
    expect(result.to, DateTime(2026, 11, 12));
  });

  test('creatina dentro da faixa diária fica ok', () async {
    final result = await panel([
      _dose('Creatina', 5, DateTime(2026, 11, 12, 8), productId: 'creatina'),
      _dose('Creatina', 3, DateTime(2026, 11, 11, 8), productId: 'creatina'),
    ]);

    expect(result.doses.single.level, RiskLevel.ok);
    expect(result.doses.single.title, contains('dentro da faixa'));
    expect(result.doses.single.detail, contains('2 de 7 dias'));
  });

  test('faixa por dia soma as doses: 5 g + 5 g no mesmo dia conta como dia acima', () async {
    final result = await panel([
      _dose('Creatina', 5, DateTime(2026, 11, 12, 8), productId: 'creatina'),
      _dose('Creatina', 5, DateTime(2026, 11, 12, 19), productId: 'creatina'),
      _dose('Creatina', 5, DateTime(2026, 11, 11, 8), productId: 'creatina'),
    ]);

    final indicator = result.doses.single;
    expect(indicator.level, RiskLevel.attention);
    expect(indicator.title, contains('acima da faixa em 1 de 7 dias'));
    expect(indicator.detail, contains('10 g'));
    expect(indicator.caution, contains('rins'));
    expect(indicator.sourcesFormatted, 'ISSN');
    expect(result.level, RiskLevel.attention);
  });

  test('faixa por tomada (whey): conta os dias com alguma dose acima, sem somar', () async {
    final result = await panel([
      _dose('Whey Protein', 30, DateTime(2026, 11, 12, 8), productId: 'whey-protein'),
      _dose('Whey Protein', 30, DateTime(2026, 11, 12, 19), productId: 'whey-protein'), // 60 g no dia, mas 30 por tomada
      _dose('Whey Protein', 60, DateTime(2026, 11, 10, 12), productId: 'whey-protein'),
    ]);

    expect(result.doses.single.title, contains('acima da faixa em 1 de 7 dias'));
    expect(result.doses.single.detail, contains('Maior dose: 60 g'));
  });

  test('anabolizante sempre pede acompanhamento médico e vem primeiro', () async {
    final result = await panel([
      _dose('Creatina', 5, DateTime(2026, 11, 12, 8), productId: 'creatina'),
      _dose('Testosterona', 100, DateTime(2026, 11, 11, 8),
          productId: 'testosterona', unit: DoseUnit.mg, kind: ProductKind.anabolic),
    ]);

    expect(result.level, RiskLevel.medical);
    expect(result.doses.first.title, contains('Testosterona'));
    expect(result.doses.first.level, RiskLevel.medical);
    expect(result.doses.first.sourcesFormatted, contains('CFM'));
  });

  test('produto fora do catálogo e doses fora dos 7 dias não geram alerta', () async {
    final result = await panel([
      _dose('Cafeína', 900, DateTime(2026, 11, 12, 8), unit: DoseUnit.mg),
      _dose('Creatina', 50, DateTime(2026, 11, 1, 8), productId: 'creatina'),
    ]);

    expect(result.doses.single.title, contains('sem faixa de referência'));
    expect(result.level, RiskLevel.ok);
  });

  group('sintomas', () {
    test('só registros "Normal": ok', () async {
      await symptoms.register(status: SymptomStatus.normal, loggedAt: DateTime(2026, 11, 12, 9));

      expect((await panel(const [])).symptoms.title, contains('nada de diferente'));
    });

    test('um dia isolado é informação; três dias ou mais pedem atenção', () async {
      await symptoms.register(
          status: SymptomStatus.different, symptoms: [Symptom.nausea], loggedAt: DateTime(2026, 11, 12, 9));
      expect((await panel(const [])).symptoms.level, RiskLevel.ok);

      await symptoms.register(
          status: SymptomStatus.different, symptoms: [Symptom.fatigue], loggedAt: DateTime(2026, 11, 11, 9));
      await symptoms.register(
          status: SymptomStatus.different, symptoms: [Symptom.nausea], loggedAt: DateTime(2026, 11, 10, 9));
      final result = await panel(const []);

      expect(result.symptoms.level, RiskLevel.attention);
      expect(result.symptoms.title, 'Sintomas em 3 de 7 dias');
      expect(result.symptoms.detail, contains('náusea'));
    });

    test('palpitação pede atenção mesmo em um dia só', () async {
      await symptoms.register(
          status: SymptomStatus.different, symptoms: [Symptom.palpitation], loggedAt: DateTime(2026, 11, 12, 9));

      final result = await panel(const []);

      expect(result.symptoms.level, RiskLevel.attention);
      expect(result.symptoms.title, contains('palpitação em 1 dia'));
      expect(result.symptoms.detail, contains('avaliação médica'));
    });

    test('sintoma com anabolizante em uso orienta levar ao médico', () async {
      await symptoms.register(
          status: SymptomStatus.different, symptoms: [Symptom.acne], loggedAt: DateTime(2026, 11, 12, 9));

      final result = await panel([
        _dose('Nandrolona', 50, DateTime(2026, 11, 11, 8),
            productId: 'nandrolona', unit: DoseUnit.mg, kind: ProductKind.anabolic),
      ]);

      expect(result.symptoms.level, RiskLevel.attention);
      expect(result.symptoms.detail, contains('leve esses registros ao seu médico'));
    });
  });
}
