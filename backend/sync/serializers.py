from django.conf import settings
from rest_framework import serializers

from core.resources import ID_PATTERN
from core.schema import ErrorBodySerializer

from .handlers import HANDLERS

NETWORK_CHOICES = [
    ("wifi", "Wi-Fi"),
    ("ethernet", "Cabo"),
    ("cellular", "Dados móveis"),
    ("none", "Sem conexão"),
    ("unknown", "Desconhecida"),
]
UNMETERED_NETWORKS = ("wifi", "ethernet")
OP_CHOICES = [("upsert", "Criar ou atualizar"), ("delete", "Apagar")]
RESULT_CHOICES = [
    ("applied", "Aplicado agora"),
    ("duplicate", "Já tinha sido aplicado antes"),
    ("stale", "Ignorado: o servidor tem uma versão mais recente"),
    ("rejected", "Recusado: dados inválidos"),
]
BATCH_STATUS_CHOICES = [
    ("processing", "Em processamento"),
    ("interrupted", "Interrompido"),
    ("completed", "Concluído"),
]


class SyncRecordSerializer(serializers.Serializer):
    mutation_id = serializers.RegexField(
        rf"^{ID_PATTERN}$",
        help_text="UUID único desta mudança na fila do aparelho. Reenviar o mesmo valor nunca grava duas vezes.",
    )
    id = serializers.RegexField(
        rf"^{ID_PATTERN}$", help_text="Id do registro (UUID gerado no app). No perfil, use o uid."
    )
    client_updated_at = serializers.DateTimeField(
        help_text="Quando a mudança foi feita no aparelho. Entre versões do mesmo registro, vale a mais recente."
    )
    entity = serializers.ChoiceField([(name, name) for name in HANDLERS])
    op = serializers.ChoiceField(OP_CHOICES, default="upsert")
    data = serializers.DictField(
        required=False, default=dict,
        help_text="Mesmos campos do CRUD da entidade. Em update basta mandar o que mudou.",
    )


class SyncBatchSerializer(serializers.Serializer):
    batch_id = serializers.RegexField(rf"^{ID_PATTERN}$", help_text="UUID do lote, gerado no app.")
    device_id = serializers.CharField(max_length=64)
    network = serializers.ChoiceField(NETWORK_CHOICES, help_text="Rede usada no envio, informada pelo app.")
    records = SyncRecordSerializer(many=True, allow_empty=False)

    def validate_records(self, records):
        limit = settings.SYNC_MAX_BATCH_SIZE
        if len(records) > limit:
            raise serializers.ValidationError(f"Envie no máximo {limit} registros por lote.")
        mutation_ids = [r["mutation_id"] for r in records]
        if len(set(mutation_ids)) != len(mutation_ids):
            raise serializers.ValidationError("mutation_id repetido no mesmo lote.")
        return records


class SyncRecordResultSerializer(serializers.Serializer):
    mutation_id = serializers.CharField()
    id = serializers.CharField()
    entity = serializers.CharField()
    op = serializers.CharField()
    status = serializers.ChoiceField(
        RESULT_CHOICES,
        help_text=(
            "applied/duplicate: marque como enviado. stale: marque como enviado e recarregue o registro "
            "do servidor. rejected: não reenvie sem corrigir."
        ),
    )
    error = ErrorBodySerializer(allow_null=True)


class SyncBatchResultSerializer(serializers.Serializer):
    batch_id = serializers.CharField()
    attempt = serializers.IntegerField(help_text="Quantas vezes este batch_id já foi enviado (retomadas).")
    received = serializers.IntegerField()
    applied = serializers.IntegerField()
    duplicate = serializers.IntegerField()
    stale = serializers.IntegerField()
    rejected = serializers.IntegerField()
    results = SyncRecordResultSerializer(many=True)


class SyncMutationStatusSerializer(serializers.Serializer):
    mutation_id = serializers.CharField()
    id = serializers.CharField()
    entity = serializers.CharField()
    op = serializers.CharField()
    status = serializers.ChoiceField(RESULT_CHOICES)
    processed_at = serializers.DateTimeField()


class SyncBatchStatusSerializer(serializers.Serializer):
    batch_id = serializers.CharField()
    status = serializers.ChoiceField(
        BATCH_STATUS_CHOICES,
        help_text="interrupted/processing após uma queda: reenvie o lote, o que já entrou volta como duplicate.",
    )
    attempts = serializers.IntegerField()
    received = serializers.IntegerField()
    processed = serializers.IntegerField(allow_null=True)
    started_at = serializers.DateTimeField()
    finished_at = serializers.DateTimeField(allow_null=True)
    mutations = SyncMutationStatusSerializer(
        many=True, help_text="Mutações gravadas por este lote. As que não aparecem aqui continuam pendentes."
    )


class SyncPolicySerializer(serializers.Serializer):
    wifi_only = serializers.BooleanField()
    allowed_networks = serializers.ListField(child=serializers.CharField())
    max_batch_size = serializers.IntegerField()
    entities = serializers.ListField(
        child=serializers.CharField(), help_text="Na ordem em que o app deve enviar os registros."
    )
