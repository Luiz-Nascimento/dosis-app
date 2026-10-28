import 'enums.dart';
import 'json.dart';

class Backup {
  const Backup({
    required this.id,
    required this.createdAt,
    required this.reason,
    required this.protected,
    required this.counts,
    required this.sizeBytes,
    required this.sha256,
  });

  factory Backup.fromJson(Json json) => Backup(
        id: json['id'] as String,
        createdAt: parseDateTime(json['created_at'])!,
        reason: json['reason'] as String,
        protected: json['protected'] as bool,
        counts: Map<String, int>.from(json['counts'] as Map),
        sizeBytes: json['size_bytes'] as int,
        sha256: json['sha256'] as String,
      );

  final String id;
  final DateTime createdAt;

  /// `manual` ou `pre_restore` (backup automático antes de restaurar).
  final String reason;

  /// Protegido por senha do usuário.
  final bool protected;

  /// Registros por coleção (routine_items, dose_logs, symptom_logs, hydration_logs).
  final Map<String, int> counts;
  final int sizeBytes;
  final String sha256;
}

class RestoreResult {
  const RestoreResult({required this.mode, required this.restored, required this.safetyBackupId});

  factory RestoreResult.fromJson(Json json) => RestoreResult(
        mode: json['mode'] == RestoreMode.replace.apiValue ? RestoreMode.replace : RestoreMode.merge,
        restored: Map<String, int>.from(json['restored'] as Map),
        safetyBackupId: json['safety_backup_id'] as String,
      );

  final RestoreMode mode;
  final Map<String, int> restored;

  /// Backup do estado anterior: restaure-o para desfazer.
  final String safetyBackupId;
}
