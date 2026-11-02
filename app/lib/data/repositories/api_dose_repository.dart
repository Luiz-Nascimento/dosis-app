import '../../core/ids.dart';
import '../../domain/repositories/dose_repository.dart';
import '../models/tracking.dart';
import '../services/tracking_services.dart';

class ApiDoseRepository implements DoseRepository {
  const ApiDoseRepository(this._service);

  final DoseService _service;

  /// O id nasce no app: se o envio for repetido, o servidor responde 409 em vez de duplicar a dose.
  @override
  Future<DoseLog> register({
    required String routineItemId,
    double? amount,
    DateTime? takenAt,
    String? notes,
  }) =>
      _service.register(
        id: newId(),
        routineItemId: routineItemId,
        amount: amount,
        takenAt: takenAt,
        notes: notes,
      );

  @override
  Future<List<DoseLog>> list({DateTime? from, DateTime? to, String? routineItemId, int? limit}) =>
      _service.list(from: from, to: to, routineItemId: routineItemId, limit: limit);
}