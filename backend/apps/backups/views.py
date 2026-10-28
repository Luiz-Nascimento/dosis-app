from drf_spectacular.utils import OpenApiParameter, extend_schema, inline_serializer
from rest_framework import status
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.core.resources import RecordNotFound
from apps.core.schema import ErrorSerializer

from . import serializers as s
from . import service

TAG = "Backup"
BACKUP_ID = OpenApiParameter("backup_id", str, OpenApiParameter.PATH)


def _validated(serializer_class, request) -> dict:
    serializer = serializer_class(data=request.data)
    serializer.is_valid(raise_exception=True)
    return serializer.validated_data


class BackupThrottled(APIView):
    # Backup e restauração são operações pesadas (e o scrypt é lento de propósito).
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "backup"


class BackupListView(BackupThrottled):
    def get_throttles(self):
        # Listar é leve; só criar backup entra no limite.
        return super().get_throttles() if self.request.method == "POST" else []

    @extend_schema(
        tags=[TAG],
        summary="Listar backups", operation_id="backups_list",
        responses={200: inline_serializer("BackupList", {"results": s.BackupSerializer(many=True)}), 401: ErrorSerializer},
    )
    def get(self, request):
        return Response({"results": s.BackupSerializer(service.list_backups(request.user.uid), many=True).data})

    @extend_schema(
        tags=[TAG],
        summary="Criar backup criptografado", operation_id="backups_create",
        description=(
            "Junta perfil, rotina, doses, sintomas e água, comprime (gzip) e criptografa (AES-256-GCM). "
            "Sem senha, usa a chave do servidor (só restaura nesta conta). Com senha (scrypt), só abre "
            "com ela. São mantidos os backups mais recentes (BACKUP_MAX_PER_USER)."
        ),
        request=s.BackupCreateSerializer,
        responses={201: s.BackupSerializer, 400: ErrorSerializer, 401: ErrorSerializer, 429: ErrorSerializer},
    )
    def post(self, request):
        data = _validated(s.BackupCreateSerializer, request)
        backup = service.create_backup(request.user.uid, data.get("passphrase"))
        return Response(s.BackupSerializer(backup).data, status=status.HTTP_201_CREATED)


class BackupDetailView(APIView):
    @extend_schema(
        tags=[TAG], summary="Detalhar backup", operation_id="backups_retrieve", parameters=[BACKUP_ID],
        responses={200: s.BackupSerializer, 404: ErrorSerializer},
    )
    def get(self, request, backup_id):
        backup = service.get_backup(request.user.uid, backup_id)
        if backup is None:
            raise RecordNotFound("Backup não encontrado.")
        return Response(s.BackupSerializer(backup).data)

    @extend_schema(
        tags=[TAG], summary="Excluir backup", operation_id="backups_destroy", parameters=[BACKUP_ID],
        responses={204: None, 404: ErrorSerializer},
    )
    def delete(self, request, backup_id):
        if not service.delete_backup(request.user.uid, backup_id):
            raise RecordNotFound("Backup não encontrado.")
        return Response(status=status.HTTP_204_NO_CONTENT)


class BackupDownloadView(APIView):
    @extend_schema(
        tags=[TAG],
        summary="Baixar o arquivo do backup", operation_id="backups_download",
        description="O arquivo continua criptografado. Guarde-o para levar os dados ou restaurar depois.",
        parameters=[BACKUP_ID],
        responses={200: s.BackupFileSerializer, 404: ErrorSerializer},
    )
    def get(self, request, backup_id):
        file = service.load_file(request.user.uid, backup_id)
        if file is None:
            raise RecordNotFound("Backup não encontrado.")
        response = Response(s.BackupFileSerializer(file).data)
        response["Content-Disposition"] = f'attachment; filename="dosis-backup-{backup_id}.json"'
        return response


class BackupRestoreView(BackupThrottled):
    @extend_schema(
        tags=[TAG],
        summary="Restaurar um backup salvo", operation_id="backups_restore",
        description=(
            "`merge` atualiza os registros do backup e mantém os outros; `replace` deixa só os do backup. "
            "Antes de restaurar é criado um backup automático do estado atual (`safety_backup_id`)."
        ),
        parameters=[BACKUP_ID],
        request=s.RestoreSerializer,
        responses={200: s.RestoreResultSerializer, 400: ErrorSerializer, 404: ErrorSerializer, 429: ErrorSerializer},
    )
    def post(self, request, backup_id):
        data = _validated(s.RestoreSerializer, request)
        file = service.load_file(request.user.uid, backup_id)
        if file is None:
            raise RecordNotFound("Backup não encontrado.")
        result = service.restore(request.user.uid, file, data["mode"], data.get("passphrase"))
        return Response(s.RestoreResultSerializer(result).data)


class BackupRestoreFileView(BackupThrottled):
    @extend_schema(
        tags=[TAG],
        summary="Restaurar a partir de um arquivo baixado", operation_id="backups_restore_file",
        description=(
            "Envie o conteúdo do arquivo de /api/v1/backups/{id}/download/. Backup com senha pode ser restaurado em qualquer "
            "conta; backup sem senha, só na conta que o criou."
        ),
        request=s.RestoreFileSerializer,
        responses={200: s.RestoreResultSerializer, 400: ErrorSerializer, 429: ErrorSerializer},
    )
    def post(self, request):
        data = _validated(s.RestoreFileSerializer, request)
        result = service.restore(request.user.uid, data["file"], data["mode"], data.get("passphrase"))
        return Response(s.RestoreResultSerializer(result).data)
