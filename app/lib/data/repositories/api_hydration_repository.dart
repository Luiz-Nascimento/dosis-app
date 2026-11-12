import '../../core/ids.dart';
import '../../domain/repositories/hydration_repository.dart';
import '../models/tracking.dart';
import '../services/tracking_services.dart';

class ApiHydrationRepository implements HydrationRepository {
  const ApiHydrationRepository(this._service);

  final HydrationService _service;

  /// O id nasce no app, como nas doses: um reenvio não duplica o registro.
  @override
  Future<HydrationLog> log({required int amountMl, DateTime? loggedAt}) =>
      _service.create(id: newId(), amountMl: amountMl, loggedAt: loggedAt);

  @override
  Future<List<HydrationLog>> list({DateTime? from, DateTime? to, int? limit}) =>
      _service.list(from: from, to: to, limit: limit);

  @override
  Future<void> remove(String id) => _service.delete(id);
}
