import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/repositories/fake_repositories.dart';
import 'package:dosis/domain/usecases/build_weekly_symptom_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 12/11/2026 é uma quinta-feira: a semana vai de segunda 09/11 a domingo 15/11.
  final now = DateTime(2026, 11, 12, 20);
  late FakeSymptomRepository symptoms;

  setUp(() => symptoms = FakeSymptomRepository());

  Future<void> log(DateTime at, [List<Symptom> list = const [], String? notes]) => symptoms.register(
        status: list.isEmpty ? SymptomStatus.normal : SymptomStatus.different,
        symptoms: list,
        notes: notes,
        loggedAt: at,
      );

  Future<WeeklySymptomReport> report({int weekOffset = 0}) =>
      BuildWeeklySymptomReport(symptoms)(weekOffset: weekOffset, now: now);

  test('a semana vai de segunda a domingo', () async {
    final result = await report();

    expect(result.weekStart, DateTime(2026, 11, 9));
    expect(result.weekEnd, DateTime(2026, 11, 15));
    expect(result.days, hasLength(7));
    expect(result.daysWithEntry, 0);
    expect(result.frequencies, isEmpty);
  });

  test('conta dias com registro, dias normais e dias com sintomas', () async {
    await log(DateTime(2026, 11, 9, 20)); // seg: normal
    await log(DateTime(2026, 11, 10, 9), [Symptom.nausea]); // ter: náusea
    await log(DateTime(2026, 11, 10, 21), [Symptom.fatigue]); // ter de novo: conta um dia só
    await log(DateTime(2026, 11, 12, 8), [Symptom.nausea], 'Depois do pré-treino');

    final result = await report();

    expect(result.daysWithEntry, 3);
    expect(result.daysNormal, 1);
    expect(result.daysWithSymptoms, 2);
    expect(result.days[1].entries, 2);
    expect(result.days[1].symptoms, {Symptom.nausea, Symptom.fatigue});
    expect(result.entries, hasLength(4));
    expect(result.entries.first.notes, 'Depois do pré-treino');
  });

  test('frequência por sintoma em dias, do mais frequente ao menos, comparada com a semana anterior', () async {
    await log(DateTime(2026, 11, 10, 9), [Symptom.nausea, Symptom.fatigue]);
    await log(DateTime(2026, 11, 11, 9), [Symptom.nausea]);
    await log(DateTime(2026, 11, 3, 9), [Symptom.fatigue]); // semana anterior
    await log(DateTime(2026, 11, 4, 9), [Symptom.fatigue]); // semana anterior
    await log(DateTime(2026, 11, 5, 9), [Symptom.dizziness]); // semana anterior

    final result = await report();

    expect(result.frequencies.map((f) => (f.symptom, f.days, f.previousDays)), [
      (Symptom.nausea, 2, 0),
      (Symptom.fatigue, 1, 2),
    ]);
    expect(result.previousDaysWithSymptoms, 3);
    expect(result.changeFromPreviousWeek, -1);
  });

  test('weekOffset -1 mostra a semana anterior e não mistura os registros desta', () async {
    await log(DateTime(2026, 11, 10, 9), [Symptom.nausea]);
    await log(DateTime(2026, 11, 3, 9), [Symptom.fatigue]);

    final result = await report(weekOffset: -1);

    expect(result.weekStart, DateTime(2026, 11, 2));
    expect(result.frequencies.single.symptom, Symptom.fatigue);
    expect(result.entries, hasLength(1));
  });

  test('recusa semanas futuras', () {
    expect(() => report(weekOffset: 1), throwsArgumentError);
  });
}
