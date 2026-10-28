"""Contrato dos provedores de autenticação.

O Firebase Auth é a fonte de verdade das contas. O backend encapsula as
operações (anônimo, cadastro, login, refresh, verificação de e-mail,
recuperação de senha e vínculo de conta anônima) para que o app e o Swagger
falem só com o Django. ``FirebaseAuthProvider`` chama a API REST do Firebase
Auth; ``MockAuthProvider`` simula o mesmo contrato sem credenciais.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any

from rest_framework import status
from rest_framework.exceptions import APIException


class AuthError(APIException):
    status_code = status.HTTP_400_BAD_REQUEST
    default_code = "auth_error"
    default_detail = "Não foi possível concluir a autenticação."


class InvalidCredentials(AuthError):
    status_code = status.HTTP_401_UNAUTHORIZED
    default_code = "invalid_credentials"
    default_detail = "E-mail ou senha incorretos."


class InvalidToken(AuthError):
    status_code = status.HTTP_401_UNAUTHORIZED
    default_code = "invalid_token"
    default_detail = "Token inválido ou expirado. Faça login novamente."


class EmailAlreadyInUse(AuthError):
    status_code = status.HTTP_409_CONFLICT
    default_code = "email_already_in_use"
    default_detail = "Já existe uma conta com este e-mail."


class WeakPassword(AuthError):
    default_code = "weak_password"
    default_detail = "A senha não atende aos requisitos mínimos."


class InvalidActionCode(AuthError):
    default_code = "invalid_action_code"
    default_detail = "O link é inválido ou expirou. Solicite um novo."


class NotAnonymous(AuthError):
    status_code = status.HTTP_409_CONFLICT
    default_code = "not_anonymous"
    default_detail = "Esta conta já possui e-mail vinculado."


class TooManyAttempts(AuthError):
    status_code = status.HTTP_429_TOO_MANY_REQUESTS
    default_code = "too_many_attempts"
    default_detail = "Muitas tentativas. Aguarde alguns minutos e tente novamente."


class AuthUnavailable(AuthError):
    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    default_code = "auth_unavailable"
    default_detail = "Serviço de autenticação indisponível no momento."


@dataclass(frozen=True)
class AuthSession:
    """Resultado de um login: tokens do Firebase e dados básicos da conta."""

    uid: str
    id_token: str
    refresh_token: str
    expires_in: int
    is_anonymous: bool
    email: str | None = None
    name: str | None = None
    email_verified: bool = False


class AuthProvider(ABC):
    @abstractmethod
    def sign_in_anonymously(self) -> AuthSession: ...

    @abstractmethod
    def sign_up(self, email: str, password: str, name: str | None) -> AuthSession:
        """Cria conta com e-mail e senha e envia o e-mail de verificação."""

    @abstractmethod
    def sign_in(self, email: str, password: str) -> AuthSession: ...

    @abstractmethod
    def refresh(self, refresh_token: str) -> AuthSession: ...

    @abstractmethod
    def link_email(self, id_token: str, email: str, password: str, name: str | None) -> AuthSession:
        """Converte a conta anônima em conta com e-mail, mantendo o mesmo uid."""

    @abstractmethod
    def send_email_verification(self, id_token: str) -> None: ...

    @abstractmethod
    def confirm_email_verification(self, oob_code: str) -> None: ...

    @abstractmethod
    def send_password_reset(self, email: str) -> None:
        """Não revela se o e-mail existe (evita enumeração de contas)."""

    @abstractmethod
    def confirm_password_reset(self, oob_code: str, new_password: str) -> None: ...

    @abstractmethod
    def verify_id_token(self, id_token: str) -> dict[str, Any]:
        """Valida o ID token e retorna as claims (``uid``, ``email``, ``firebase``...)."""

    @abstractmethod
    def delete_user(self, uid: str) -> None:
        """Apaga a conta no Firebase Auth."""
