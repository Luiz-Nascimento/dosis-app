import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/repositories/fake_record_edit_repository.dart';
import 'package:dosis/data/repositories/fake_repositories.dart';
import 'package:dosis/domain/usecases/edit_day_records.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeRoutineRepository routine;
  late FakeDoseRepository doses;
  late FakeSymptomRepository symptoms;
  late SaveDayStack saveStack;
  late SaveDaySymptoms saveSymptoms;

  setUp(() {
    routine = FakeRoutineRepository();
    doses = FakeDoseRepository(routine);
    symptoms = FakeSymptomRepository();
    final edits = FakeRecordEditRepository(doses, symptoms);
    saveStack = SaveDayStack(edits, doses);
    saveSymptoms = SaveDaySymptoms(edits, symptoms);
  });

  Future<List<dynamic>> dayOfDoses() async {
    final all = await doses.list();
    final date = all.first.localDate;
    return all.where((d) => d.localDate == date).toList();
  }

  test('apaga a dose que saiu da lista e mantém a outra', () async {
    final original = (await dayOfDoses()).cast<dynamic>();
    final first = original.first;
    await saveStack(
      original: [for (final d in original) d],
      drafts: [DoseDraft(id: first.id as String, amount: first.amount as double, takenAt: first.takenAt as DateTime)],
    );
    final after = await doses.list();
    expect(after.where((d) => d.id == first.id), isNotEmpty);
    expect(after.where((d) => d.id == original.last.id), isEmpty);
  });

  test('atualiza a quantidade de uma dose', () async {
    final original = (await dayOfDoses()).cast<dynamic>();
    final first = original.first;
    await saveStack(
      original: [for (final d in original) d],
      drafts: [
        for (final d in original)
          DoseDraft(id: d.id as String, amount: d.id == first.id ? 7 : d.amount as double, takenAt: d.takenAt as DateTime),
      ],
    );
    final after = await doses.list();
    expect(after.firstWhere((d) => d.id == first.id).amount, 7);
  });

  test('cria uma dose nova no dia', () async {
    final item = (await routine.list()).first;
    final before = (await doses.list()).length;
    await saveStack(
      original: const [],
      drafts: [DoseDraft(item: item, amount: 5, takenAt: DateTime(2026, 11, 1, 9))],
    );
    expect((await doses.list()).length, before + 1);
  });

  test('recusa dose zerada', () {
    expect(
      () => saveStack(original: const [], drafts: [DoseDraft(amount: 0, takenAt: DateTime(2026, 11, 1, 9))]),
      throwsArgumentError,
    );
  });

  test('cria o registro de sintomas do dia ao meio-dia quando não existe', () async {
    await saveSymptoms(
      localDate: '2026-11-01',
      existing: const [],
      status: SymptomStatus.different,
      symptoms: [Symptom.pain],
    );
    final logs = await symptoms.list();
    expect(logs.length, 1);
    expect(logs.first.localDate, '2026-11-01');
    expect(logs.first.symptoms, [Symptom.pain]);
  });

  test('junta vários registros do dia em um só', () async {
    await symptoms.register(status: SymptomStatus.normal, loggedAt: DateTime(2026, 11, 1, 9));
    await symptoms.register(
      status: SymptomStatus.different,
      symptoms: [Symptom.nausea],
      loggedAt: DateTime(2026, 11, 1, 20),
    );
    final existing = await symptoms.list();
    await saveSymptoms(
      localDate: '2026-11-01',
      existing: existing,
      status: SymptomStatus.normal,
    );
    final after = await symptoms.list();
    expect(after.length, 1);
    expect(after.first.status, SymptomStatus.normal);
  });

  test('exige sintoma quando o status é "senti algo diferente"', () {
    expect(
      () => saveSymptoms(
        localDate: '2026-11-01',
        existing: const [],
        status: SymptomStatus.different,
      ),
      throwsArgumentError,
    );
  });
}