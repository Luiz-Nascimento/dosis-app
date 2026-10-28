import 'dart:convert';
import 'dart:io' show gzip;

import 'package:cryptography/cryptography.dart';

import '../../core/api/api_client.dart';
import '../../core/ids.dart';
import '../models/enums.dart';
import '../models/json.dart';
import '../models/sync.dart';

/// Chave AES-256 combinada com o servidor para cifrar os lotes.
class SyncKey {
  const SyncKey({required this.keyId, required this.key});

  final String keyId;
  final List<int> key;
}

/// Onde a chave do sync fica guardada. No app use [SecureSyncKeyStore]
/// (`secure_storage.dart`, Android Keystore); nos testes, [MemorySyncKeyStore].
abstract class SyncKeyStore {
  Future<SyncKey?> read();
  Future<void> write(SyncKey key);
  Future<void> clear();
}

class MemorySyncKeyStore implements SyncKeyStore {
  SyncKey? _key;

  @override
  Future<SyncKey?> read() async => _key;

  @override
  Future<void> write(SyncKey key) async => _key = key;

  @override
  Future<void> clear() async => _key = null;
}

/// Sincronização da fila offline (`/sync/*`).
///
/// Fluxo: [policy] → [consent] (mostrar o aviso) → [acceptConsent] →
/// [pairDevice] (uma vez por aparelho) → [sendBatch] com Wi-Fi.
/// Se a resposta não chegar, reenvie o mesmo lote (mesmo `batchId`) ou veja
/// [batchStatus]: o que já entrou volta como `duplicate`.
class SyncService {
  SyncService(this.api, {SyncKeyStore? keyStore}) : keys = keyStore ?? MemorySyncKeyStore();

  static const _hkdfInfoFallback = 'dosis-sync-v1';

  final ApiClient api;
  final SyncKeyStore keys;
  final _x25519 = X25519();
  final _aes = AesGcm.with256bits();

  Future<SyncPolicy> policy() async => SyncPolicy.fromJson(await api.get('/sync/policy') as Json);

  /// Situação do aceite e o texto do aviso explícito.
  Future<SyncConsent> consent() async => SyncConsent.fromJson(await api.get('/sync/consent') as Json);

  /// Registra que o usuário viu e aceitou a versão [noticeVersion] do aviso.
  Future<SyncConsent> acceptConsent(String noticeVersion) async =>
      SyncConsent.fromJson(await api.post('/sync/consent', body: {'notice_version': noticeVersion}) as Json);

  /// Desativa a sincronização.
  Future<void> revokeConsent() => api.delete('/sync/consent');

  /// Combina a chave com o servidor (X25519 + HKDF-SHA256). Só a chave pública
  /// trafega; a chave AES fica em [keys].
  Future<SyncKey> pairDevice(String deviceId) async {
    final keyPair = await _x25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final json = await api.post('/sync/keys', body: {
      'device_id': deviceId,
      'client_public_key': encodeBase64Url(publicKey.bytes),
    }) as Json;

    final keyId = json['key_id'] as String;
    final shared = await _x25519.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: SimplePublicKey(decodeBase64Url(json['server_public_key'] as String), type: KeyPairType.x25519),
    );
    final derived = await Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: shared,
      nonce: utf8.encode(keyId),
      info: utf8.encode(json['hkdf_info'] as String? ?? _hkdfInfoFallback),
    );
    final key = SyncKey(keyId: keyId, key: await derived.extractBytes());
    await keys.write(key);
    return key;
  }

  /// Envia um lote da fila. Para cada registro, o resultado diz se pode sair
  /// da fila ([SyncBatchResult.sentMutationIds]).
  Future<SyncBatchResult> sendBatch({
    required String deviceId,
    required NetworkType network,
    required List<SyncRecord> records,
    String? batchId,
    bool encrypt = true,
  }) async {
    final batch = <String, Object?>{
      'batch_id': batchId ?? newId(),
      'device_id': deviceId,
      'network': network.apiValue,
      'records': records.map((r) => r.toJson()).toList(),
    };
    final body = encrypt ? await sealBatch(batch) : batch;
    return SyncBatchResult.fromJson(await api.post('/sync/batches', body: body) as Json);
  }

  /// `JSON → gzip → AES-256-GCM` no envelope esperado pelo backend.
  Future<Json> sealBatch(Map<String, Object?> batch) async {
    final key = await keys.read();
    if (key == null) throw StateError('Combine a chave com pairDevice() antes de sincronizar.');
    final session = await api.tokens.read();
    if (session == null) throw StateError('Faça login antes de sincronizar.');

    final nonce = _aes.newNonce();
    final box = await _aes.encrypt(
      gzip.encode(utf8.encode(jsonEncode(batch))),
      secretKey: SecretKey(key.key),
      nonce: nonce,
      aad: utf8.encode('dosis-sync-v1:${session.uid}:${key.keyId}'),
    );
    return {
      'key_id': key.keyId,
      'algorithm': 'A256GCM',
      'compression': 'gzip',
      'nonce': encodeBase64Url(nonce),
      'payload': encodeBase64Url([...box.cipherText, ...box.mac.bytes]),
    };
  }

  /// O que um lote gravou (use quando a resposta do envio não chegou).
  Future<SyncBatchStatus> batchStatus(String batchId) async =>
      SyncBatchStatus.fromJson(await api.get('/sync/batches/$batchId') as Json);

  /// Auditoria dos eventos de sincronização do usuário.
  Future<List<SyncEvent>> events({String? event, String? batchId, int? limit}) async {
    final json = await api.get('/sync/events', query: {'event': event, 'batch_id': batchId, 'limit': limit}) as Json;
    return (json['results'] as List).map((e) => SyncEvent.fromJson(e as Json)).toList();
  }
}

/// Monitoramento do sync (exige a custom claim `admin`): `/admin/sync/*`.
class MonitoringService {
  MonitoringService(this.api);

  final ApiClient api;

  Future<List<SyncEvent>> events({String? uid, String? event, String? batchId, int? limit}) async {
    final json = await api.get('/admin/sync/events', query: {
      'uid': uid,
      'event': event,
      'batch_id': batchId,
      'limit': limit,
    }) as Json;
    return (json['results'] as List).map((e) => SyncEvent.fromJson(e as Json)).toList();
  }

  Future<SyncSummary> summary({int hours = 24}) async =>
      SyncSummary.fromJson(await api.get('/admin/sync/summary', query: {'hours': hours}) as Json);
}

String encodeBase64Url(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

List<int> decodeBase64Url(String value) => base64Url.decode(base64Url.normalize(value));
