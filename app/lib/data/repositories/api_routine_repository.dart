import '../../domain/repositories/routine_repository.dart';
import '../models/tracking.dart';
import '../services/tracking_services.dart';

class ApiRoutineRepository implements RoutineRepository {
  const ApiRoutineRepository(this._service);

  final RoutineService _service;

  @override
  Future<List<RoutineItem>> list({bool? active}) => _service.list(active: active);
}