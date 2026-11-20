import '../../core/api/api_exception.dart';
import '../../core/ids.dart';
import '../../domain/repositories/dose_repository.dart';
import '../models/enums.dart';
import '../models/tracking.dart';
import '../services/tracking_services.dart';

class ApiDoseRepository implements DoseRepository {
  const ApiDoseRepository(this._service);

  final DoseService _service;

  /// O id nasce no app e identifica a tentativa. Se a primeira chamada chegou ao
  /// servidor mas a resposta se perdeu (timeout, queda de rede), repetir com o
  /// mesmo [id] faz o servidor responder 409; nesse caso a dose já existe e é
  /// devolvida, sem gravar outra.
  @override
  Future<DoseLog> register({
    String? id,
    required String routineItemId,
    double? amount,
    Protocol? protocol,
    DateTime? takenAt,
    String? notes,
  }) async {
    final doseId = id ?? newId();
    try {
      return await _service.register(
        id: doseId,
        routineItemId: routineItemId,
        amount: amount,
        protocol: protocol,
        takenAt: takenAt,
        notes: notes,
      );
    } on ApiException catch (error) {
      if (error.statusCode != 409) rethrow;
      return _service.get(doseId);
    }
  }

  @override
  Future<List<DoseLog>> list({DateTime? from, DateTime? to, String? routineItemId, int? limit}) =>
      _service.list(from: from, to: to, routineItemId: routineItemId, limit: limit);
}
