// Teste de ponta a ponta contra o backend Django rodando de verdade.
//
//   cd backend && python manage.py runserver 127.0.0.1:8000
//   cd app && DOSIS_API_URL=http://127.0.0.1:8000/api/v1 flutter test test/integration
//
// Sem DOSIS_API_URL ele é pulado.
import 'dart:io';

import 'package:dosis/core/api/api_client.dart';
import 'package:dosis/core/api/api_exception.dart';
import 'package:dosis/core/ids.dart';
import 'package:dosis/data/dosis_api.dart';
import 'package:dosis/data/models/enums.dart';
import 'package:dosis/data/models/sync.dart';
import 'package:dosis/data/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

final String? baseUrl = Platform.environment['DOSIS_API_URL'];

void main() {
  late DosisApi api;

  setUp(() => api = DosisApi(client: ApiClient(baseUrl: baseUrl), syncKeyStore: MemorySyncKeyStore()));

  test('todos os grupos de endpoints, do login à exclusão da conta', () async {
    expect((await api.system.health()).status, 'ok');

    // Autenticação e perfil
    final session = await api.auth.signInAnonymously();
    expect(session.isAnonymous, isTrue);
    expect((await api.system.writeFirestoreCheck('olá'))['data']['message'], 'olá');
    final profile = await api.profile.update(weightKg: 76, heightCm: 178, goal: Goal.hypertrophy);
    expect(profile.weightKg, 76);

    // Catálogo e artigos
    final products = await api.catalog.listProducts(search: 'creatina');
    final creatina = await api.catalog.getProduct(products.results.single.id);
    expect(creatina.rangeFor(Protocol.continuous)!.max, 5);
    final articles = await api.articles.list(tag: 'creatina');
    expect((await api.articles.get(articles.results.first.id)).body, contains('creatina'));

    // Rotina, doses, sintomas e água
    final item = await api.routine.create(productId: creatina.id, scheduleTimes: ['08:00']);
    final dose = await api.doses.register(routineItemId: item.id);
    expect(dose.amount, 3);
    final today = dose.takenAt.toLocal();
    expect((await api.doses.list(from: today, to: today)).map((d) => d.id), contains(dose.id));
    await api.symptoms.create(status: SymptomStatus.different, symptoms: [Symptom.fatigue], notes: 'Treino pesado');
    await api.hydration.create(amountMl: 500);
    expect((await api.routine.list(active: true)).single.name, 'Creatina monohidratada');
    await api.doses.update(dose.id, {'amount': 5});
    expect((await api.doses.get(dose.id)).amount, 5);

    // Sincronização cifrada (X25519 + HKDF + gzip + AES-GCM, como no backend)
    final consent = await api.sync.consent();
    await expectLater(
      api.sync.sendBatch(deviceId: 'pixel-7', network: NetworkType.wifi, records: const []),
      throwsStateError, // ainda sem chave
    );
    await api.sync.acceptConsent(consent.notice.version);
    await api.sync.pairDevice('pixel-7');
    final waterId = newId();
    final records = [
      SyncRecord(entity: SyncEntity.hydrationLogs, id: waterId, data: {'amount_ml': 300}),
      SyncRecord(entity: SyncEntity.doseLogs, id: newId(), data: {'routine_item_id': item.id}),
    ];
    final batchId = newId();
    final sent = await api.sync.sendBatch(deviceId: 'pixel-7', network: NetworkType.wifi, records: records, batchId: batchId);
    expect(sent.applied, 2);
    final again = await api.sync.sendBatch(deviceId: 'pixel-7', network: NetworkType.wifi, records: records, batchId: batchId);
    expect(again.duplicate, 2);
    expect((await api.hydration.get(waterId)).amountMl, 300);
    expect((await api.sync.batchStatus(batchId)).mutations, hasLength(2));
    expect((await api.sync.events(batchId: batchId)).first.event, 'sync.completed');
    await expectLater(
      api.sync.sendBatch(deviceId: 'pixel-7', network: NetworkType.cellular, records: records),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'wifi_required')),
    );

    // Backup com senha, download e restauração do arquivo
    final backup = await api.backups.create(passphrase: 'minha-senha-forte');
    expect(backup.counts['dose_logs'], 2);
    final file = await api.backups.download(backup.id);
    await api.hydration.delete(waterId);
    final restored = await api.backups.restoreFile(file, passphrase: 'minha-senha-forte');
    expect(restored.restored['hydration_logs'], 2);
    expect((await api.hydration.get(waterId)).amountMl, 300);
    expect((await api.backups.list()).length, 2); // o manual + o de segurança

    // Vincular a conta anônima a e-mail mantém tudo
    final email = 'teste-${newId().substring(0, 8)}@dosis.app';
    final linked = await api.auth.linkAccount(email: email, password: 'senha1234', acceptTerms: true, name: 'Rafael');
    expect(linked.uid, session.uid);
    expect((await api.auth.me()).email, email);
    expect((await api.doses.list()).length, 2);

    // Exclusão definitiva (LGPD)
    await api.auth.deleteAccount();
    expect(await api.auth.isSignedIn, isFalse);
  }, skip: baseUrl == null ? 'Defina DOSIS_API_URL para rodar contra o backend.' : false);
}
