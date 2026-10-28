from django.conf import settings
from drf_spectacular.utils import OpenApiParameter, PolymorphicProxySerializer, extend_schema
from rest_framework import status
from rest_framework.exceptions import APIException, ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from core.resources import RecordNotFound
from core.schema import ErrorSerializer

from . import security
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
        description=(
            "O app lê antes de montar a fila: rede permitida, tamanho do lote, ordem das entidades, "
            "criptografia exigida e versão do aviso."
        ),
        responses={200: s.SyncPolicySerializer, 401: ErrorSerializer},
    )
    def get(self, request):
        return Response(s.SyncPolicySerializer({
            "wifi_only": settings.SYNC_WIFI_ONLY,
            "allowed_networks": allowed_networks(),
            "max_batch_size": settings.SYNC_MAX_BATCH_SIZE,
            "entities": list(HANDLERS),
            "encryption_required": settings.SYNC_REQUIRE_ENCRYPTION,
            "encryption": security.ALGORITHM,
            "key_agreement": security.KEY_AGREEMENT,
            "compression": "gzip",
            "max_payload_bytes": settings.SYNC_MAX_PAYLOAD_BYTES,
            "consent_version": security.NOTICE["version"],
        }).data)


class SyncConsentView(APIView):
    @extend_schema(
        tags=[TAG],
        summary="Aviso de sincronização e situação do aceite",
        responses={200: s.SyncConsentSerializer, 401: ErrorSerializer},
    )
    def get(self, request):
        return Response(s.SyncConsentSerializer(security.consent_status(request.user.uid)).data)

    @extend_schema(
        tags=[TAG],
        summary="Registrar que o usuário viu e aceitou o aviso",
        description="Envie a versão do aviso exibida. Se o texto mudou desde então, a versão não bate e o aceite é recusado.",
        request=s.SyncConsentRequestSerializer,
        responses={200: s.SyncConsentSerializer, 400: ErrorSerializer, 401: ErrorSerializer},
    )
    def post(self, request):
        payload = s.SyncConsentRequestSerializer(data=request.data)
        payload.is_valid(raise_exception=True)
        if payload.validated_data["notice_version"] != security.NOTICE["version"]:
            raise ValidationError({"notice_version": "O aviso mudou. Mostre a versão atual e peça o aceite de novo."})
        return Response(s.SyncConsentSerializer(security.accept_consent(request.user.uid)).data)

    @extend_schema(
        tags=[TAG],
        summary="Desativar a sincronização (revogar o aceite)",
        responses={204: None, 401: ErrorSerializer},
    )
    def delete(self, request):
        security.revoke_consent(request.user.uid)
        return Response(status=status.HTTP_204_NO_CONTENT)


class SyncKeyView(APIView):
    @extend_schema(
        tags=[TAG],
        summary="Combinar a chave de criptografia do aparelho",
        description=(
            "Acordo de chave X25519: o app envia só a chave pública. Os dois lados calculam o segredo "
            "compartilhado e derivam a chave AES-256 com HKDF-SHA256 (salt = key_id, info = hkdf_info). "
            "A chave nunca trafega pela rede. Guarde a chave e o key_id no Keystore do aparelho."
        ),
        request=s.SyncKeyRequestSerializer,
        responses={201: s.SyncKeySerializer, 400: ErrorSerializer, 401: ErrorSerializer},
    )
    def post(self, request):
        payload = s.SyncKeyRequestSerializer(data=request.data)
        payload.is_valid(raise_exception=True)
        key = security.create_sync_key(
            request.user.uid, payload.validated_data["device_id"], payload.validated_data["client_public_key"]
        )
        return Response(s.SyncKeySerializer(key).data, status=status.HTTP_201_CREATED)


class SyncBatchView(APIView):
    @extend_schema(
        tags=[TAG],
        summary="Enviar um lote da fila de sincronização",
        description=(
            "Pré-requisitos: aviso aceito (`428 sync_consent_required` se não) e Wi-Fi "
            "(`412 wifi_required`). O lote vai **comprimido e criptografado** no envelope "
            "(`SyncEnvelope`); em texto puro (`SyncBatch`) só é aceito com SYNC_REQUIRE_ENCRYPTION=False.\n\n"
            "Cada registro é gravado numa transação junto com o recibo do seu `mutation_id`: se a "
            "conexão cair no meio, o que entrou tem recibo e o resto não foi gravado. Reenvie o lote "
            "inteiro (mesmo `batch_id`): o que já entrou volta como `duplicate`."
        ),
        request=PolymorphicProxySerializer(
            component_name="SyncBatchRequest",
            serializers=[s.SyncEnvelopeSerializer, s.SyncBatchSerializer],
            resource_type_field_name=None,
        ),
        responses={
            200: s.SyncBatchResultSerializer,
            400: ErrorSerializer,
            401: ErrorSerializer,
            412: ErrorSerializer,
            413: ErrorSerializer,
            428: ErrorSerializer,
            503: ErrorSerializer,
        },
    )
    def post(self, request):
        uid = request.user.uid
        security.require_consent(uid)
        serializer = s.SyncBatchSerializer(data=self._read_batch(uid, request.data))
        serializer.is_valid(raise_exception=True)
        batch = serializer.validated_data
        if batch["network"] not in allowed_networks():
            raise WifiRequired()
        return Response(s.SyncBatchResultSerializer(process_batch(uid, batch)).data)

    @staticmethod
    def _read_batch(uid, data):
        if isinstance(data, dict) and "payload" in data:
            envelope = s.SyncEnvelopeSerializer(data=data)
            envelope.is_valid(raise_exception=True)
            return security.open_envelope(uid, envelope.validated_data)
        if settings.SYNC_REQUIRE_ENCRYPTION:
            raise security.EncryptionRequired()
        return data


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
