import '../../domain/repositories/record_edit_repository.dart';
import '../models/enums.dart';
import '../models/json.dart';
import '../models/tracking.dart';
import '../services/tracking_services.dart';

/// Edição dos registros na API (`PATCH` e `DELETE`).
class ApiRecordEditRepository implements RecordEditRepository {
  const ApiRecordEditRepository(this._doses, this._symptoms);

  final DoseService _doses;
  final SymptomService _symptoms;

  @override
  Future<DoseLog> updateDose(
    String id, {
    required double amount,
    required DateTime takenAt,
    RoutineItem? item,
  }) =>
      _doses.update(id, {
        'amount': amount,
        'taken_at': isoDateTime(takenAt),
        if (item != null) ...{
          'routine_item_id': item.id,
          'product_id': item.productId,
          'name': item.name,
          'kind': item.kind.apiValue,
          'unit': item.doseUnit.apiValue,
          'protocol': item.protocol.apiValue,
        },
      });

  @override
  Future<void> deleteDose(String id) => _doses.delete(id);

  @override
  Future<SymptomLog> updateSymptoms(
    String id, {
    required SymptomStatus status,
    List<Symptom> symptoms = const [],
    String? otherDescription,
    String? notes,
  }) =>
      _symptoms.update(id, {
        'status': status.apiValue,
        'symptoms': symptoms.map((s) => s.apiValue).toList(),
        'other_description': otherDescription,
        'notes': notes,
      });

  @override
  Future<void> deleteSymptoms(String id) => _symptoms.delete(id);
}