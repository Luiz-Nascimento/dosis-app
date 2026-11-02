import '../../data/models/auth.dart';

/// Status do servidor. Usado pela tela de diagnóstico enquanto as telas finais não existem.
abstract interface class SystemRepository {
  Future<HealthStatus> health();
}