import '../core/api/api_client.dart';
import '../core/api/secure_storage.dart';
import 'services/auth_service.dart';
import 'services/backup_service.dart';
import 'services/catalog_service.dart';
import 'services/profile_service.dart';
import 'services/sync_service.dart';
import 'services/system_service.dart';
import 'services/tracking_services.dart';

/// Ponto único de acesso a todos os endpoints do backend.
///
/// ```dart
/// final api = DosisApi.secure();
/// await api.auth.signInAnonymously();
/// final creatina = await api.routine.create(productId: 'creatina');
/// await api.doses.register(routineItemId: creatina.id);
/// ```
class DosisApi {
  DosisApi({ApiClient? client, this.syncKeyStore}) : client = client ?? ApiClient();

  /// Tokens e chave do sync guardados no Android Keystore.
  factory DosisApi.secure({String? baseUrl}) => DosisApi(
        client: ApiClient(baseUrl: baseUrl, tokenStore: SecureTokenStore()),
        syncKeyStore: SecureSyncKeyStore(),
      );

  final ApiClient client;

  /// Onde fica a chave do sync (padrão: em memória).
  final SyncKeyStore? syncKeyStore;

  late final SystemService system = SystemService(client);
  late final AuthService auth = AuthService(client);
  late final ProfileService profile = ProfileService(client);
  late final CatalogService catalog = CatalogService(client);
  late final ArticleService articles = ArticleService(client);
  late final RoutineService routine = RoutineService(client);
  late final DoseService doses = DoseService(client);
  late final SymptomService symptoms = SymptomService(client);
  late final HydrationService hydration = HydrationService(client);
  late final SyncService sync = SyncService(client, keyStore: syncKeyStore);
  late final BackupService backups = BackupService(client);
  late final MonitoringService monitoring = MonitoringService(client);
}
