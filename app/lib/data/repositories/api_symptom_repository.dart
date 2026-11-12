import '../../core/ids.dart';
import '../../domain/repositories/symptom_repository.dart';
import '../models/enums.dart';
import '../models/tracking.dart';
import '../services/tracking_services.dart';

class ApiSymptomRepository implements SymptomRepository {
  const ApiSymptomRepository(this._service);

  final SymptomService _service;

  /// O id nasce no app, como nas doses: um reenvio não duplica o registro.
  @override
  Future<SymptomLog> register({
    required SymptomStatus status,
    List<Symptom> symptoms = const [],
    String? otherDescription,
    String? notes,
    DateTime? loggedAt,
  }) =>
      _service.create(
        id: newId(),
        status: status,
        symptoms: symptoms,
        otherDescription: otherDescription,
        notes: notes,
        loggedAt: loggedAt,
      );

  @override
  Future<List<SymptomLog>> list({DateTime? from, DateTime? to, int? limit}) =>
      _service.list(from: from, to: to, limit: limit);
}
