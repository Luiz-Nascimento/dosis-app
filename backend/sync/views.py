from django.conf import settings
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import status
from rest_framework.exceptions import APIException
from rest_framework.response import Response
from rest_framework.views import APIView

from core.resources import RecordNotFound
from core.schema import ErrorSerializer

from . import serializers as s
from .handlers import HANDLERS
from .service import get_batch, process_batch

TAG = "Sincronização"


class WifiRequired(APIException):
    status_code = status.HTTP_412_PRECONDITION_FAILED
    default_code = "wifi_required"
    default_detail = "A sincronização só acontece em Wi-Fi. Os registros continuam salvos no aparelho."


def allowed_networks() -> list[str]:
    return list(s.UNMETERED_NETWORKS) if settings.SYNC_WIFI_ONLY else [n for n, _ in s.NETWORK_CHOICES]


class SyncPolicyView(APIView):
    @extend_schema(
        tags=[TAG],
        summary="Regras da sincronização",
        description="O app lê antes de montar a fila: rede permitida, tamanho do lote e ordem das entidades.",
        responses={200: s.SyncPolicySerializer, 401: ErrorSerializer},
    )
    def get(self, request):
        return Response(s.SyncPolicySerializer({
            "wifi_only": settings.SYNC_WIFI_ONLY,
            "allowed_networks": allowed_networks(),
            "max_batch_size": settings.SYNC_MAX_BATCH_SIZE,
            "entities": list(HANDLERS),
        }).data)


class SyncBatchView(APIView):
    @extend_schema(
        tags=[TAG],
        summary="Enviar um lote da fila de sincronização",
        description=(
            "O app guarda cada mudança local como **pendente** e, com Wi-Fi, envia até "
            "`max_batch_size` delas em um lote. Cada registro é gravado numa transação junto com o "
            "recibo do seu `mutation_id`: se a conexão cair no meio, o que entrou tem recibo e o resto "
            "não foi gravado. Reenvie o lote inteiro (mesmo `batch_id`): o que já entrou volta como "
            "`duplicate`. Lotes fora do Wi-Fi são recusados com `412 wifi_required`."
        ),
        request=s.SyncBatchSerializer,
        responses={
            200: s.SyncBatchResultSerializer,
            400: ErrorSerializer,
            401: ErrorSerializer,
            412: ErrorSerializer,
            503: ErrorSerializer,
        },
    )
    def post(self, request):
        serializer = s.SyncBatchSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        batch = serializer.validated_data
        if batch["network"] not in allowed_networks():
            raise WifiRequired()
        return Response(s.SyncBatchResultSerializer(process_batch(request.user.uid, batch)).data)


class SyncBatchStatusView(APIView):
    @extend_schema(
        tags=[TAG],
        summary="Situação de um lote (retomada após queda)",
        description=(
            "Lista as mutações que o lote gravou. Use quando a resposta do POST não chegou: o que "
            "estiver aqui está **enviado**, o resto continua **pendente**."
        ),
        parameters=[OpenApiParameter("batch_id", str, OpenApiParameter.PATH)],
        responses={200: s.SyncBatchStatusSerializer, 401: ErrorSerializer, 404: ErrorSerializer},
    )
    def get(self, request, batch_id):
        batch = get_batch(request.user.uid, batch_id)
        if batch is None:
            raise RecordNotFound("Lote não encontrado.")
        return Response(s.SyncBatchStatusSerializer(batch).data)
