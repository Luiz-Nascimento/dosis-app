import '../../core/ids.dart';
import '../../domain/repositories/routine_repository.dart';
import '../models/tracking.dart';
import '../services/tracking_services.dart';

class ApiRoutineRepository implements RoutineRepository {
  const ApiRoutineRepository(this._service);

  final RoutineService _service;

  @override
  Future<List<RoutineItem>> list({bool? active}) => _service.list(active: active);

  /// Só o `product_id` basta: o backend completa o item com os dados do catálogo.
  /// O id nasce no app, como nas doses: reenviar não duplica o item.
  @override
  Future<RoutineItem> add({required String productId, List<String>? scheduleTimes}) =>
      _service.create(id: newId(), productId: productId, scheduleTimes: scheduleTimes);

  @override
  Future<void> remove(String id) => _service.delete(id);
}
