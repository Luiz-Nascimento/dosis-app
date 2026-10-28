import '../../core/api/api_client.dart';
import '../models/auth.dart';
import '../models/json.dart';

/// Status da API e documento de teste do Firestore (`/system/health/`, `/system/diagnostics/firestore/`).
class SystemService {
  SystemService(this.api);

  final ApiClient api;

  Future<HealthStatus> health() async => HealthStatus.fromJson(await api.get('/system/health/', auth: false) as Json);

  /// Grava e lê de volta um documento de teste em `users/{uid}/diagnostics/firestore`.
  Future<Json> writeFirestoreCheck([String message = 'ping']) async =>
      await api.post('/system/diagnostics/firestore/', body: {'message': message}) as Json;

  Future<Json> readFirestoreCheck() async => await api.get('/system/diagnostics/firestore/') as Json;
}
