import 'dart:convert';
import 'dart:io' show gzip;

import 'package:cryptography/cryptography.dart';
import 'package:dosis/core/api/token_store.dart';
import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/models/sync.dart';
import 'package:dosis/data/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const session = AuthTokens(uid: 'user-1', idToken: 't', refreshToken: 'r');

/// Faz o papel do backend: acordo X25519, HKDF e abertura do envelope.
class FakeServer {
  final x25519 = X25519();
  List<int>? key;
  String keyId = 'key12345';
  Map<String, dynamic>? lastBatch;

  Future<Map<String, dynamic>> pair(Map<String, dynamic> request) async {
    final serverPair = await x25519.newKeyPair();
    final shared = await x25519.sharedSecretKey(
      keyPair: serverPair,
      remotePublicKey: SimplePublicKey(decodeBase64Url(request['client_public_key'] as String), type: KeyPairType.x25519),
    );
    final derived = await Hkdf(hmac: Hmac.sha256(), outputLength: 32)
        .deriveKey(secretKey: shared, nonce: utf8.encode(keyId), info: utf8.encode('dosis-sync-v1'));
    key = await derived.extractBytes();
    return {
      'key_id': keyId,
      'server_public_key': encodeBase64Url((await serverPair.extractPublicKey()).bytes),
      'algorithm': 'A256GCM',
      'key_agreement': 'X25519-HKDF-SHA256',
      'hkdf_info': 'dosis-sync-v1',
    };
  }

  Future<Map<String, dynamic>> open(Map<String, dynamic> envelope) async {
    final payload = decodeBase64Url(envelope['payload'] as String);
    final box = SecretBox(
      payload.sublist(0, payload.length - 16),
      nonce: decodeBase64Url(envelope['nonce'] as String),
      mac: Mac(payload.sublist(payload.length - 16)),
    );
    final clear = await AesGcm.with256bits().decrypt(
      box,
      secretKey: SecretKey(key!),
      aad: utf8.encode('dosis-sync-v1:${session.uid}:${envelope['key_id']}'),
    );
    return lastBatch = jsonDecode(utf8.decode(gzip.decode(clear))) as Map<String, dynamic>;
  }
}

void main() {
  test('combina a chave e cifra o lote no formato do backend', () async {
    final server = FakeServer();
    final api = fakeClient((request) async {
      if (request.url.path.endsWith('/sync/keys/')) return jsonResponse(await server.pair(body(request)), 201);
      final envelope = body(request);
      expect(envelope.keys, containsAll(['key_id', 'algorithm', 'compression', 'nonce', 'payload']));
      expect(envelope['algorithm'], 'A256GCM');
      final batch = await server.open(envelope);
      final record = (batch['records'] as List).single as Map<String, dynamic>;
      return jsonResponse({
        'batch_id': batch['batch_id'],
        'attempt': 1,
        'received': 1,
        'applied': 1,
        'duplicate': 0,
        'stale': 0,
        'rejected': 0,
        'results': [
          {'mutation_id': record['mutation_id'], 'id': record['id'], 'entity': record['entity'], 'op': 'upsert', 'status': 'applied', 'error': null},
        ],
      });
    }, session: session);

    final sync = SyncService(api);
    final key = await sync.pairDevice('pixel-7');
    expect(key.key, server.key);

    final record = SyncRecord(entity: SyncEntity.hydrationLogs, id: 'water123', data: {'amount_ml': 500});
    final result = await sync.sendBatch(deviceId: 'pixel-7', network: NetworkType.wifi, records: [record], batchId: 'batch123');

    expect(server.lastBatch!['batch_id'], 'batch123');
    expect(server.lastBatch!['network'], 'wifi');
    final sent = (server.lastBatch!['records'] as List).single as Map<String, dynamic>;
    expect(sent['data'], {'amount_ml': 500});
    expect(sent['client_updated_at'], endsWith('Z'));
    expect(result.sentMutationIds, [record.mutationId]);
  });

  test('não envia sem chave combinada', () async {
    final sync = SyncService(fakeClient((_) async => jsonResponse({}), session: session));
    expect(
      () => sync.sendBatch(deviceId: 'd', network: NetworkType.wifi, records: const []),
      throwsStateError,
    );
  });

  test('cada mudança ganha um mutation_id próprio', () {
    final a = SyncRecord(entity: SyncEntity.doseLogs, id: 'dose1234', data: const {});
    final b = SyncRecord(entity: SyncEntity.doseLogs, id: 'dose1234', data: const {});
    expect(a.mutationId, isNot(b.mutationId));
    expect(SyncRecord.delete(entity: SyncEntity.doseLogs, id: 'dose1234').toJson()['op'], 'delete');
  });
}
