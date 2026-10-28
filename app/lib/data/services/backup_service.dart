import '../../core/api/api_client.dart';
import '../models/backup.dart';
import '../models/enums.dart';
import '../models/json.dart';

/// Backup criptografado e restauração (`/backups/`).
class BackupService {
  BackupService(this.api);

  final ApiClient api;

  Future<List<Backup>> list() async {
    final json = await api.get('/backups/') as Json;
    return (json['results'] as List).map((e) => Backup.fromJson(e as Json)).toList();
  }

  /// Sem [passphrase]: só restaura nesta conta. Com senha (8+ caracteres):
  /// nem o servidor abre sem ela e o arquivo pode ir para outra conta.
  /// Senha esquecida = backup perdido.
  Future<Backup> create({String? passphrase}) async =>
      Backup.fromJson(await api.post('/backups/', body: compact({'passphrase': passphrase})) as Json);

  Future<Backup> get(String id) async => Backup.fromJson(await api.get('/backups/$id/') as Json);

  Future<void> delete(String id) => api.delete('/backups/$id/');

  /// Arquivo do backup (continua cifrado). Salve como JSON para guardar/levar.
  Future<Json> download(String id) async => await api.get('/backups/$id/download/') as Json;

  /// Restaura um backup salvo. Antes, o servidor cria um backup do estado
  /// atual ([RestoreResult.safetyBackupId]) para dar para desfazer.
  Future<RestoreResult> restore(String id, {RestoreMode mode = RestoreMode.merge, String? passphrase}) async =>
      RestoreResult.fromJson(await api.post(
        '/backups/$id/restore/',
        body: compact({'mode': mode.apiValue, 'passphrase': passphrase}),
      ) as Json);

  /// Restaura a partir de um arquivo baixado em [download].
  Future<RestoreResult> restoreFile(Json file, {RestoreMode mode = RestoreMode.merge, String? passphrase}) async =>
      RestoreResult.fromJson(await api.post(
        '/backups/restore/',
        body: compact({'file': file, 'mode': mode.apiValue, 'passphrase': passphrase}),
      ) as Json);
}
