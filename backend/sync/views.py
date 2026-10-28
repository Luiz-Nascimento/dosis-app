from django.conf import settings
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.exceptions import APIException
from rest_framework.response import Response
from rest_framework.views import APIView

from core.schema import ErrorSerializer

from . import serializers as s
from .handlers import HANDLERS
from .service import process_batch

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
            "O app guarda cada registro local como **pendente** e, com Wi-Fi, envia até "
            "`max_batch_size` deles em um lote. Para cada registro a resposta diz `applied` (marque "
            "como **enviado**) ou `rejected` (dados inválidos: não reenvie sem corrigir). Lotes "
            "enviados fora do Wi-Fi são recusados com `412 wifi_required`."
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
