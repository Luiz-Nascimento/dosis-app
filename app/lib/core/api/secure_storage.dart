import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/services/sync_service.dart';
import 'token_store.dart';

const _storage = FlutterSecureStorage();

/// Tokens da sessão no armazenamento seguro do aparelho (Android Keystore).
class SecureTokenStore implements TokenStore {
  static const _key = 'dosis.auth_tokens';

  @override
  Future<AuthTokens?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return AuthTokens(
      uid: json['uid'] as String,
      idToken: json['id_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }

  @override
  Future<void> write(AuthTokens tokens) => _storage.write(
        key: _key,
        value: jsonEncode({'uid': tokens.uid, 'id_token': tokens.idToken, 'refresh_token': tokens.refreshToken}),
      );

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Chave do sync no armazenamento seguro do aparelho (Android Keystore).
class SecureSyncKeyStore implements SyncKeyStore {
  static const _key = 'dosis.sync_key';

  @override
  Future<SyncKey?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return SyncKey(keyId: json['key_id'] as String, key: base64Decode(json['key'] as String));
  }

  @override
  Future<void> write(SyncKey key) =>
      _storage.write(key: _key, value: jsonEncode({'key_id': key.keyId, 'key': base64Encode(key.key)}));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
