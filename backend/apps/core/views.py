from __future__ import annotations

from datetime import datetime, timezone

from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import serializers
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.firebase import firebase_mode
from apps.core.store import get_store, user_doc


class HealthView(APIView):
    authentication_classes: list = []
    permission_classes = [AllowAny]

    @extend_schema(
        tags=["Sistema"],
        summary="Status da API",
        responses=inline_serializer(
            "Health",
            {"status": serializers.CharField(), "firebase_mode": serializers.CharField()},
        ),
    )
    def get(self, request):
        return Response({"status": "ok", "firebase_mode": firebase_mode()})


class FirestoreCheckInputSerializer(serializers.Serializer):
    message = serializers.CharField(max_length=200, default="ping")


class FirestoreCheckSerializer(serializers.Serializer):
    path = serializers.CharField()
    data = serializers.DictField(allow_null=True)


class FirestoreCheckView(APIView):
    """Grava e lê um documento de teste na árvore do próprio usuário.

    Serve para conferir a configuração do Firebase: o caminho é sempre montado
    a partir do uid do token, então um usuário nunca alcança dados de outro.
    """

    @extend_schema(tags=["Sistema"], summary="Lê o documento de teste do usuário", responses=FirestoreCheckSerializer)
    def get(self, request):
        path = user_doc(request.user.uid, "diagnostics", "firestore")
        return Response({"path": path, "data": get_store().get(path)})

    @extend_schema(
        tags=["Sistema"],
        summary="Grava e lê de volta um documento de teste",
        request=FirestoreCheckInputSerializer,
        responses=FirestoreCheckSerializer,
    )
    def post(self, request):
        payload = FirestoreCheckInputSerializer(data=request.data)
        payload.is_valid(raise_exception=True)
        path = user_doc(request.user.uid, "diagnostics", "firestore")
        store = get_store()
        store.set(path, {"message": payload.validated_data["message"], "written_at": datetime.now(timezone.utc)})
        return Response({"path": path, "data": store.get(path)})
