import '../../domain/repositories/record_edit_repository.dart';
import '../models/enums.dart';
import '../models/tracking.dart';
import 'fake_repositories.dart';

/// Edição em memória, para `USE_API=false` e para os testes.
class FakeRecordEditRepository implements RecordEditRepository {
  FakeRecordEditRepository(this._doses, this._symptoms);

  final FakeDoseRepository _doses;
  final FakeSymptomRepository _symptoms;

  @override
  Future<DoseLog> updateDose(
    String id, {
    required double amount,
    required DateTime takenAt,
    RoutineItem? item,
  }) async =>
      _doses.replaceLog(id, amount: amount, takenAt: takenAt, item: item);

  @override
  Future<void> deleteDose(String id) async => _doses.removeLog(id);

  @override
  Future<SymptomLog> updateSymptoms(
    String id, {
    required SymptomStatus status,
    List<Symptom> symptoms = const [],
    String? otherDescription,
    String? notes,
  }) async =>
      _symptoms.replaceLog(
        id,
        status: status,
        symptoms: symptoms,
        otherDescription: otherDescription,
        notes: notes,
      );

  @override
  Future<void> deleteSymptoms(String id) async => _symptoms.removeLog(id);
}