import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';

/// Edição e exclusão de registros já feitos (tela de detalhe do dia).
abstract interface class RecordEditRepository {
  /// Troca a dose e o horário. Com [item], troca também o produto da dose.
  Future<DoseLog> updateDose(
    String id, {
    required double amount,
    required DateTime takenAt,
    RoutineItem? item,
  });

  Future<void> deleteDose(String id);

  Future<SymptomLog> updateSymptoms(
    String id, {
    required SymptomStatus status,
    List<Symptom> symptoms = const [],
    String? otherDescription,
    String? notes,
  });

  Future<void> deleteSymptoms(String id);
}