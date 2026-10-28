import '../../core/ids.dart';
import 'enums.dart';
import 'json.dart';

class SyncPolicy {
  const SyncPolicy({
    required this.wifiOnly,
    required this.allowedNetworks,
    required this.maxBatchSize,
    required this.entities,
    required this.encryptionRequired,
    required this.encryption,
    required this.keyAgreement,
    required this.compression,
    required this.maxPayloadBytes,
    required this.consentVersion,
  });

  factory SyncPolicy.fromJson(Json json) => SyncPolicy(
        wifiOnly: json['wifi_only'] as bool,
        allowedNetworks: stringList(json['allowed_networks']),
        maxBatchSize: json['max_batch_size'] as int,
        entities: stringList(json['entities']),
        encryptionRequired: json['encryption_required'] as bool,
        encryption: json['encryption'] as String,
        keyAgreement: json['key_agreement'] as String,
        compression: json['compression'] as String,
        maxPayloadBytes: json['max_payload_bytes'] as int,
        consentVersion: json['consent_version'] as String,
      );

  final bool wifiOnly;
  final List<String> allowedNetworks;
  final int maxBatchSize;

  /// Ordem de envio das entidades.
  final List<String> entities;
  final bool encryptionRequired;
  final String encryption;
  final String keyAgreement;
  final String compression;
  final int maxPayloadBytes;
  final String consentVersion;

  bool allows(NetworkType network) => allowedNetworks.contains(network.apiValue);
}

class SyncNotice {
  const SyncNotice({required this.version, required this.title, required this.text});

  factory SyncNotice.fromJson(Json json) => SyncNotice(
        version: json['version'] as String,
        title: json['title'] as String,
        text: json['text'] as String,
      );

  final String version;
  final String title;

  /// Texto do aviso explícito, exibido antes de ativar a sincronização.
  final String text;
}

class SyncConsent {
  const SyncConsent({required this.notice, required this.accepted, this.acceptedVersion, this.acceptedAt});

  factory SyncConsent.fromJson(Json json) => SyncConsent(
        notice: SyncNotice.fromJson(json['notice'] as Json),
        accepted: json['accepted'] as bool,
        acceptedVersion: json['accepted_version'] as String?,
        acceptedAt: parseDateTime(json['accepted_at']),
      );

  final SyncNotice notice;
  final bool accepted;
  final String? acceptedVersion;
  final DateTime? acceptedAt;
}

/// Uma mudança na fila do aparelho.
class SyncRecord {
  SyncRecord({
    required this.entity,
    required this.id,
    required this.data,
    this.op = SyncOp.upsert,
    String? mutationId,
    DateTime? clientUpdatedAt,
  })  : mutationId = mutationId ?? newId(),
        clientUpdatedAt = clientUpdatedAt ?? DateTime.now();

  /// Exclusão de um registro.
  SyncRecord.delete({required SyncEntity entity, required String id, String? mutationId, DateTime? clientUpdatedAt})
      : this(entity: entity, id: id, data: const {}, op: SyncOp.delete, mutationId: mutationId, clientUpdatedAt: clientUpdatedAt);

  /// Único por mudança: reenviar nunca grava duas vezes.
  final String mutationId;
  final SyncEntity entity;

  /// Id do registro (no perfil, o uid).
  final String id;
  final SyncOp op;
  final DateTime clientUpdatedAt;

  /// Mesmos campos do CRUD da entidade.
  final Json data;

  Json toJson() => {
        'mutation_id': mutationId,
        'id': id,
        'entity': entity.apiValue,
        'op': op.apiValue,
        'client_updated_at': isoDateTime(clientUpdatedAt),
        'data': data,
      };
}

class SyncRecordResult {
  const SyncRecordResult({
    required this.mutationId,
    required this.id,
    required this.entity,
    required this.op,
    required this.status,
    this.errorCode,
    this.errorMessage,
    this.errorDetails,
  });

  factory SyncRecordResult.fromJson(Json json) {
    final error = json['error'] as Json?;
    return SyncRecordResult(
      mutationId: json['mutation_id'] as String,
      id: json['id'] as String,
      entity: json['entity'] as String,
      op: json['op'] as String,
      status: SyncResultStatus.fromApi(json['status'] as String?),
      errorCode: error?['code'] as String?,
      errorMessage: error?['message'] as String?,
      errorDetails: error?['details'],
    );
  }

  final String mutationId;
  final String id;
  final String entity;
  final String op;
  final SyncResultStatus status;
  final String? errorCode;
  final String? errorMessage;
  final Object? errorDetails;
}

class SyncBatchResult {
  const SyncBatchResult({
    required this.batchId,
    required this.attempt,
    required this.received,
    required this.applied,
    required this.duplicate,
    required this.stale,
    required this.rejected,
    required this.results,
  });

  factory SyncBatchResult.fromJson(Json json) => SyncBatchResult(
        batchId: json['batch_id'] as String,
        attempt: json['attempt'] as int,
        received: json['received'] as int,
        applied: json['applied'] as int,
        duplicate: json['duplicate'] as int,
        stale: json['stale'] as int,
        rejected: json['rejected'] as int,
        results: (json['results'] as List).map((e) => SyncRecordResult.fromJson(e as Json)).toList(),
      );

  final String batchId;
  final int attempt;
  final int received;
  final int applied;
  final int duplicate;
  final int stale;
  final int rejected;
  final List<SyncRecordResult> results;

  /// Mutações que podem sair da fila (marcar como enviadas).
  Iterable<String> get sentMutationIds => results.where((r) => r.status.isSent).map((r) => r.mutationId);
}

class SyncMutationStatus {
  const SyncMutationStatus({
    required this.mutationId,
    required this.id,
    required this.entity,
    required this.op,
    required this.status,
    required this.processedAt,
  });

  factory SyncMutationStatus.fromJson(Json json) => SyncMutationStatus(
        mutationId: json['mutation_id'] as String,
        id: json['id'] as String,
        entity: json['entity'] as String,
        op: json['op'] as String,
        status: SyncResultStatus.fromApi(json['status'] as String?),
        processedAt: parseDateTime(json['processed_at'])!,
      );

  final String mutationId;
  final String id;
  final String entity;
  final String op;
  final SyncResultStatus status;
  final DateTime processedAt;
}

/// `GET /sync/batches/{id}`: o que entrou de um lote (retomada após queda).
class SyncBatchStatus {
  const SyncBatchStatus({
    required this.batchId,
    required this.status,
    required this.attempts,
    required this.received,
    required this.mutations,
    this.processed,
    this.startedAt,
    this.finishedAt,
  });

  factory SyncBatchStatus.fromJson(Json json) => SyncBatchStatus(
        batchId: json['batch_id'] as String,
        status: json['status'] as String,
        attempts: json['attempts'] as int,
        received: json['received'] as int,
        processed: json['processed'] as int?,
        startedAt: parseDateTime(json['started_at']),
        finishedAt: parseDateTime(json['finished_at']),
        mutations: (json['mutations'] as List).map((e) => SyncMutationStatus.fromJson(e as Json)).toList(),
      );

  final String batchId;

  /// `processing`, `interrupted` ou `completed`.
  final String status;
  final int attempts;
  final int received;
  final int? processed;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final List<SyncMutationStatus> mutations;
}

/// Evento de auditoria do sync.
class SyncEvent {
  const SyncEvent({required this.id, required this.uid, required this.event, required this.createdAt, required this.raw});

  factory SyncEvent.fromJson(Json json) => SyncEvent(
        id: json['id'] as String,
        uid: json['uid'] as String,
        event: json['event'] as String,
        createdAt: parseDateTime(json['created_at'])!,
        raw: json,
      );

  final String id;
  final String uid;

  /// `sync.started`, `sync.resumed`, `sync.completed`, `sync.failed`, `sync.refused`...
  final String event;
  final DateTime createdAt;

  /// Campos extras (batch_id, contagens, error_code, duration_ms...).
  final Json raw;

  String? get batchId => raw['batch_id'] as String?;
  String? get errorCode => raw['error_code'] as String?;
}

/// `GET /admin/sync/summary` (monitoramento).
class SyncSummary {
  const SyncSummary({
    required this.since,
    required this.events,
    required this.truncated,
    required this.users,
    required this.byEvent,
    required this.failuresByCode,
    required this.records,
    this.batchDurationMsP50,
    this.batchDurationMsMax,
  });

  factory SyncSummary.fromJson(Json json) => SyncSummary(
        since: parseDateTime(json['since'])!,
        events: json['events'] as int,
        truncated: json['truncated'] as bool,
        users: json['users'] as int,
        byEvent: Map<String, int>.from(json['by_event'] as Map),
        failuresByCode: Map<String, int>.from(json['failures_by_code'] as Map),
        records: Map<String, int>.from(json['records'] as Map),
        batchDurationMsP50: json['batch_duration_ms_p50'] as int?,
        batchDurationMsMax: json['batch_duration_ms_max'] as int?,
      );

  final DateTime since;
  final int events;
  final bool truncated;
  final int users;
  final Map<String, int> byEvent;
  final Map<String, int> failuresByCode;
  final Map<String, int> records;
  final int? batchDurationMsP50;
  final int? batchDurationMsMax;
}
