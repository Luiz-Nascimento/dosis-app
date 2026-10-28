import '../../core/api/api_client.dart';
import '../models/auth.dart';
import '../models/json.dart';

/// Status da API e documento de teste do Firestore (`/health`, `/diagnostics/firestore`).
class SystemService {
  SystemService(this.api);

  final ApiClient api;

  Future<HealthStatus> health() async => HealthStatus.fromJson(await api.get('/health', auth: false) as Json);

  /// Grava e lê de volta um documento de teste em `users/{uid}/diagnostics/firestore`.
  Future<Json> writeFirestoreCheck([String message = 'ping']) async =>
      await api.post('/diagnostics/firestore', body: {'message': message}) as Json;

  Future<Json> readFirestoreCheck() async => await api.get('/diagnostics/firestore') as Json;
}
