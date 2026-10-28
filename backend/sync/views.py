from django.conf import settings
from drf_spectacular.utils import OpenApiParameter, PolymorphicProxySerializer, extend_schema, inline_serializer
from rest_framework import status
from rest_framework.exceptions import APIException, ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from core.permissions import IsAdmin
from core.resources import RecordNotFound, parse_query
from core.schema import ErrorSerializer

from . import audit, security
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
        consent = security.accept_consent(request.user.uid)
        audit.record(request.user.uid, audit.CONSENT_ACCEPTED, notice_version=consent["accepted_version"])
        return Response(s.SyncConsentSerializer(consent).data)

    @extend_schema(
        tags=[TAG],
        summary="Desativar a sincronização (revogar o aceite)",
        responses={204: None, 401: ErrorSerializer},
    )
    def delete(self, request):
        security.revoke_consent(request.user.uid)
        audit.record(request.user.uid, audit.CONSENT_REVOKED)
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
        audit.record(
            request.user.uid, audit.KEY_CREATED, device_id=payload.validated_data["device_id"], key_id=key["key_id"],
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
        data = None
        try:
            security.require_consent(uid)
            data = self._read_batch(uid, request.data)
            serializer = s.SyncBatchSerializer(data=data)
            serializer.is_valid(raise_exception=True)
            batch = serializer.validated_data
            if batch["network"] not in allowed_networks():
                raise WifiRequired()
        except APIException as exc:
            meta = data if isinstance(data, dict) else {}
            audit.record(
                uid, audit.REFUSED, error_code=_error_code(exc),
                **{k: _short(meta.get(k)) for k in ("batch_id", "device_id", "network")},
            )
            raise
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


EVENT_PARAMETERS = [
    OpenApiParameter("event", str, enum=[e for e, _ in audit.EVENT_CHOICES]),
    OpenApiParameter("batch_id", str),
    OpenApiParameter("limit", int, description="Padrão 100, máximo 500."),
]


class SyncEventsView(APIView):
    @extend_schema(
        tags=[TAG],
        summary="Eventos de sincronização do usuário",
        description="Auditoria: início, retomada, conclusão, falha e recusa de lotes, aceite do aviso e chaves.",
        parameters=EVENT_PARAMETERS,
        responses={
            200: inline_serializer("SyncEventList", {"results": s.SyncEventSerializer(many=True)}),
            401: ErrorSerializer,
        },
    )
    def get(self, request):
        query = parse_query(s.SyncEventQuerySerializer, request)
        events = audit.list_events(uid=request.user.uid, **query)
        return Response({"results": s.SyncEventSerializer(events, many=True).data})


class AdminSyncEventsView(APIView):
    permission_classes = [IsAdmin]

    @extend_schema(
        tags=["Monitoramento"],
        summary="Eventos de sincronização de todos os usuários",
        description="Exige a custom claim `admin` no token (manage.py set_admin).",
        parameters=[OpenApiParameter("uid", str), *EVENT_PARAMETERS],
        responses={
            200: inline_serializer("AdminSyncEventList", {"results": s.SyncEventSerializer(many=True)}),
            401: ErrorSerializer,
            403: ErrorSerializer,
        },
    )
    def get(self, request):
        events = audit.list_events(**parse_query(s.AdminSyncEventQuerySerializer, request))
        return Response({"results": s.SyncEventSerializer(events, many=True).data})


class AdminSyncSummaryView(APIView):
    permission_classes = [IsAdmin]

    @extend_schema(
        tags=["Monitoramento"],
        summary="Panorama da sincronização no período",
        description="Contagem por tipo de evento, falhas por código, registros aplicados e duração dos lotes.",
        parameters=[OpenApiParameter("hours", int, description="Janela em horas (padrão 24, máximo 720).")],
        responses={200: s.SyncSummarySerializer, 401: ErrorSerializer, 403: ErrorSerializer},
    )
    def get(self, request):
        hours = parse_query(s.SyncSummaryQuerySerializer, request)["hours"]
        return Response(s.SyncSummarySerializer(audit.summary(hours)).data)


def _error_code(exc: APIException) -> str:
    if isinstance(exc, ValidationError):
        return "validation_error"
    return getattr(exc.detail, "code", None) or exc.default_code


def _short(value):
    return value[:64] if isinstance(value, str) else None
