/// Tokens da sessão no Firebase Auth (emitidos pelo backend).
class AuthTokens {
  const AuthTokens({required this.uid, required this.idToken, required this.refreshToken});

  final String uid;
  final String idToken;
  final String refreshToken;
}

/// Onde os tokens ficam guardados. No app use [SecureTokenStore]
/// (`secure_storage.dart`); nos testes, [MemoryTokenStore].
abstract class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

class MemoryTokenStore implements TokenStore {
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
