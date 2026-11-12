import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/repositories/fake_repositories.dart';
import 'package:dosis/domain/usecases/register_symptoms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeSymptomRepository repository;
  late RegisterSymptoms register;

  setUp(() {
    repository = FakeSymptomRepository();
    register = RegisterSymptoms(repository);
  });

  test('"Normal" grava status normal sem sintomas', () async {
    final log = await register(normal: true);

    expect(log.status, SymptomStatus.normal);
    expect(log.symptoms, isEmpty);
    expect(await repository.list(), hasLength(1));
  });

  test('sintomas marcados gravam status "different" com a observação', () async {
    final log = await register(normal: false, symptoms: {Symptom.nausea, Symptom.dizziness}, notes: ' depois do pré-treino ');

    expect(log.status, SymptomStatus.different);
    expect(log.symptoms, containsAll([Symptom.nausea, Symptom.dizziness]));
    expect(log.notes, 'depois do pré-treino');
    expect(log.otherDescription, isNull);
  });

  test('"Outro" usa a observação como descrição', () async {
    final log = await register(normal: false, symptoms: {Symptom.other}, notes: 'Formigamento nas mãos');

    expect(log.otherDescription, 'Formigamento nas mãos');
    expect(log.notes, isNull);
  });

  test('recusa sem gravar: nada marcado, "Outro" sem descrição, ou Normal + sintoma', () async {
    expect(() => register(normal: false), throwsArgumentError);
    expect(() => register(normal: false, symptoms: {Symptom.other}, notes: '  '), throwsArgumentError);
    expect(() => register(normal: true, symptoms: {Symptom.pain}), throwsArgumentError);
    expect(await repository.list(), isEmpty);
  });
}
