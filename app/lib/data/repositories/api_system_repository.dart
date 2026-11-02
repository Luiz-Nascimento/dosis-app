import '../../domain/repositories/system_repository.dart';
import '../models/auth.dart';
import '../services/system_service.dart';

class ApiSystemRepository implements SystemRepository {
  const ApiSystemRepository(this._service);

  final SystemService _service;

  @override
  Future<HealthStatus> health() => _service.health();
}