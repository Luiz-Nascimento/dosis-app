import '../../data/models/enums.dart';
import '../../data/models/tracking.dart';

/// Registros de "Como se sente hoje?".
abstract interface class SymptomRepository {
  Future<SymptomLog> register({
    required SymptomStatus status,
    List<Symptom> symptoms = const [],
    String? otherDescription,
    String? notes,
    DateTime? loggedAt,
  });

  /// Linha do tempo, mais recentes primeiro.
  Future<List<SymptomLog>> list({DateTime? from, DateTime? to, int? limit});
}
