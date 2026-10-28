"""Endpoints de autenticação. Todos encapsulam o Firebase Auth."""
from __future__ import annotations

from dataclasses import asdict

from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.core.auth import get_auth_provider
from apps.core.schema import ErrorSerializer

from . import serializers as s
from .services import delete_account, sync_user_document

TAG = "Autenticação"


class PublicAuthView(APIView):
    authentication_classes: list = []
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"


def _validated(serializer_class, request) -> dict:
    serializer = serializer_class(data=request.data)
    serializer.is_valid(raise_exception=True)
    return serializer.validated_data


def _session_response(session, http_status=status.HTTP_200_OK) -> Response:
    return Response(s.AuthSessionSerializer(asdict(session)).data, status=http_status)


class AnonymousView(PublicAuthView):
    @extend_schema(
        tags=[TAG],
        summary="Entrar anonimamente",
        description="Cria uma conta anônima no Firebase. Os dados podem ser vinculados a um e-mail depois (/api/v1/auth/link/).",
        request=None,
        responses={201: s.AuthSessionSerializer, 429: ErrorSerializer},
    )
    def post(self, request):
        session = get_auth_provider().sign_in_anonymously()
        sync_user_document(session)
        return _session_response(session, status.HTTP_201_CREATED)


class RegisterView(PublicAuthView):
    @extend_schema(
        tags=[TAG],
        summary="Criar conta com e-mail e senha",
        description="Cria a conta e envia o e-mail de confirmação. Senha: 8+ caracteres, uma letra e um número.",
        request=s.RegisterSerializer,
        responses={201: s.AuthSessionSerializer, 400: ErrorSerializer, 409: ErrorSerializer},
    )
    def post(self, request):
        data = _validated(s.RegisterSerializer, request)
        session = get_auth_provider().sign_up(data["email"], data["password"], data["name"])
        sync_user_document(session, accepted_terms=True)
        return _session_response(session, status.HTTP_201_CREATED)


class LoginView(PublicAuthView):
    @extend_schema(
        tags=[TAG],
        summary="Entrar com e-mail e senha",
        request=s.LoginSerializer,
        responses={200: s.AuthSessionSerializer, 401: ErrorSerializer},
    )
    def post(self, request):
        data = _validated(s.LoginSerializer, request)
        session = get_auth_provider().sign_in(data["email"], data["password"])
        return _session_response(session)


class RefreshView(PublicAuthView):
    @extend_schema(
        tags=[TAG],
        summary="Renovar o id_token",
        request=s.RefreshSerializer,
        responses={200: s.AuthSessionSerializer, 401: ErrorSerializer},
    )
    def post(self, request):
        data = _validated(s.RefreshSerializer, request)
        return _session_response(get_auth_provider().refresh(data["refresh_token"]))


class PasswordResetView(PublicAuthView):
    @extend_schema(
        tags=[TAG],
        summary="Enviar link de recuperação de senha",
        description="Sempre responde 202, exista ou não a conta, para não revelar e-mails cadastrados.",
        request=s.EmailSerializer,
        responses={202: None},
    )
    def post(self, request):
        data = _validated(s.EmailSerializer, request)
        get_auth_provider().send_password_reset(data["email"])
        return Response(status=status.HTTP_202_ACCEPTED)


class PasswordResetConfirmView(PublicAuthView):
    @extend_schema(
        tags=[TAG],
        summary="Definir nova senha a partir do link",
        request=s.PasswordResetConfirmSerializer,
        responses={204: None, 400: ErrorSerializer},
    )
    def post(self, request):
        data = _validated(s.PasswordResetConfirmSerializer, request)
        get_auth_provider().confirm_password_reset(data["oob_code"], data["new_password"])
        return Response(status=status.HTTP_204_NO_CONTENT)


class VerifyEmailConfirmView(PublicAuthView):
    @extend_schema(
        tags=[TAG],
        summary="Confirmar e-mail a partir do link",
        description="Depois de confirmar, chame /api/v1/auth/refresh/ para receber um token com email_verified=true.",
        request=s.OobCodeSerializer,
        responses={204: None, 400: ErrorSerializer},
    )
    def post(self, request):
        data = _validated(s.OobCodeSerializer, request)
        get_auth_provider().confirm_email_verification(data["oob_code"])
        return Response(status=status.HTTP_204_NO_CONTENT)


class VerifyEmailView(APIView):
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    @extend_schema(
        tags=[TAG],
        summary="Reenviar e-mail de confirmação",
        request=None,
        responses={202: None, 401: ErrorSerializer},
    )
    def post(self, request):
        get_auth_provider().send_email_verification(request.auth)
        return Response(status=status.HTTP_202_ACCEPTED)


class LinkAccountView(APIView):
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    @extend_schema(
        tags=[TAG],
        summary="Vincular conta anônima a e-mail e senha",
        description="Mantém o mesmo uid, então nenhum registro feito no modo anônimo se perde.",
        request=s.LinkAccountSerializer,
        responses={200: s.AuthSessionSerializer, 400: ErrorSerializer, 409: ErrorSerializer},
    )
    def post(self, request):
        data = _validated(s.LinkAccountSerializer, request)
        session = get_auth_provider().link_email(
            request.auth, data["email"], data["password"], data.get("name") or None
        )
        sync_user_document(session, accepted_terms=True)
        return _session_response(session)


class MeView(APIView):
    @extend_schema(
        tags=[TAG],
        summary="Dados da conta autenticada",
        responses={200: s.MeSerializer, 401: ErrorSerializer},
    )
    def get(self, request):
        user = request.user
        return Response(s.MeSerializer({
            "uid": user.uid,
            "email": user.email,
            "name": user.name,
            "is_anonymous": user.is_anonymous,
            "email_verified": user.email_verified,
        }).data)

    @extend_schema(
        tags=[TAG],
        summary="Excluir conta e todos os dados",
        description="Exclusão definitiva (LGPD): apaga a árvore users/{uid} no Firestore e a conta no Firebase Auth.",
        responses={204: None, 401: ErrorSerializer},
    )
    def delete(self, request):
        delete_account(request.user.uid)
        return Response(status=status.HTTP_204_NO_CONTENT)
