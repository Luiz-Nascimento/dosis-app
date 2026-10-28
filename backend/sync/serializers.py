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
RESULT_CHOICES = [("applied", "Aplicado"), ("rejected", "Recusado")]


class SyncRecordSerializer(serializers.Serializer):
    id = serializers.RegexField(
        rf"^{ID_PATTERN}$", help_text="Id do registro (UUID gerado no app). No perfil, use o uid."
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
        return records


class SyncRecordResultSerializer(serializers.Serializer):
    id = serializers.CharField()
    entity = serializers.CharField()
    op = serializers.CharField()
    status = serializers.ChoiceField(
        RESULT_CHOICES, help_text="applied: marque como enviado. rejected: não reenvie sem corrigir."
    )
    error = ErrorBodySerializer(allow_null=True)


class SyncBatchResultSerializer(serializers.Serializer):
    batch_id = serializers.CharField()
    received = serializers.IntegerField()
    applied = serializers.IntegerField()
    rejected = serializers.IntegerField()
    results = SyncRecordResultSerializer(many=True)


class SyncPolicySerializer(serializers.Serializer):
    wifi_only = serializers.BooleanField()
    allowed_networks = serializers.ListField(child=serializers.CharField())
    max_batch_size = serializers.IntegerField()
    entities = serializers.ListField(
        child=serializers.CharField(), help_text="Na ordem em que o app deve enviar os registros."
    )
