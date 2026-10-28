import '../../core/api/api_client.dart';
import '../models/auth.dart';
import '../models/json.dart';

/// Autenticação (Firebase Auth encapsulado pelo backend): `/auth/*`.
///
/// Os métodos que abrem sessão já guardam os tokens no [ApiClient]; as
/// demais chamadas passam a sair autenticadas.
class AuthService {
  AuthService(this.api);

  final ApiClient api;

  Future<bool> get isSignedIn => api.hasSession;

  /// Entra sem cadastro (dados podem ser vinculados a um e-mail depois).
  Future<AuthSession> signInAnonymously() => _session(api.post('/auth/anonymous', auth: false));

  /// Cadastro. Senha: 8+ caracteres, uma letra e um número. Envia e-mail de confirmação.
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required bool acceptTerms,
  }) =>
      _session(api.post('/auth/register', auth: false, body: {
        'name': name,
        'email': email,
        'password': password,
        'accept_terms': acceptTerms,
      }));

  Future<AuthSession> login({required String email, required String password}) =>
      _session(api.post('/auth/login', auth: false, body: {'email': email, 'password': password}));

  /// Renova o id_token manualmente (ex.: depois de confirmar o e-mail).
  /// O [ApiClient] já renova sozinho quando recebe 401.
  Future<AuthSession> refresh() async {
    final tokens = await api.tokens.read();
    if (tokens == null) throw StateError('Nenhuma sessão para renovar.');
    return _session(api.post('/auth/refresh', auth: false, body: {'refresh_token': tokens.refreshToken}));
  }

  /// Converte a conta anônima em conta com e-mail, mantendo o mesmo uid e os registros.
  Future<AuthSession> linkAccount({
    required String email,
    required String password,
    required bool acceptTerms,
    String? name,
  }) =>
      _session(api.post('/auth/link', body: compact({
        'name': name,
        'email': email,
        'password': password,
        'accept_terms': acceptTerms,
      })));

  Future<Account> me() async => Account.fromJson(await api.get('/auth/me') as Json);

  /// Reenvia o e-mail de confirmação ("Reenviar e-mail").
  Future<void> resendEmailVerification() => api.post('/auth/verify-email');

  /// Confirma o e-mail com o `oobCode` do link. Depois chame [refresh].
  Future<void> confirmEmail(String oobCode) =>
      api.post('/auth/verify-email/confirm', auth: false, body: {'oob_code': oobCode});

  /// "Esqueci minha senha". Sempre conclui, exista ou não a conta.
  Future<void> requestPasswordReset(String email) =>
      api.post('/auth/password-reset', auth: false, body: {'email': email});

  /// "Nova senha" a partir do `oobCode` do link.
  Future<void> confirmPasswordReset({required String oobCode, required String newPassword}) => api.post(
        '/auth/password-reset/confirm',
        auth: false,
        body: {'oob_code': oobCode, 'new_password': newPassword},
      );

  /// Exclui a conta e todos os dados (LGPD). Não tem volta.
  Future<void> deleteAccount() async {
    await api.delete('/auth/me');
    await api.tokens.clear();
  }

  Future<void> signOut() => api.tokens.clear();

  Future<AuthSession> _session(Future<dynamic> request) async {
    final json = await request as Json;
    await api.saveSession(json);
    return AuthSession.fromJson(json);
  }
}
