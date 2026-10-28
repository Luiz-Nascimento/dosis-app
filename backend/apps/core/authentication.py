"""Autenticação do DRF com ID token do Firebase (header ``Authorization: Bearer``)."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from rest_framework.authentication import BaseAuthentication, get_authorization_header
from rest_framework.exceptions import AuthenticationFailed

from apps.core.auth import get_auth_provider


@dataclass(frozen=True)
class FirebaseUser:
    """Usuário autenticado. Não existe tabela de usuários: a identidade vem do token."""

    uid: str
    email: str | None = None
    name: str | None = None
    is_anonymous: bool = False
    email_verified: bool = False
    claims: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    is_authenticated = True
    is_active = True

    @property
    def pk(self) -> str:
        return self.uid

    @classmethod
    def from_claims(cls, claims: dict[str, Any]) -> FirebaseUser:
        provider = claims.get("firebase", {}).get("sign_in_provider")
        return cls(
            uid=claims["uid"],
            email=claims.get("email"),
            name=claims.get("name"),
            is_anonymous=provider == "anonymous",
            email_verified=bool(claims.get("email_verified")),
            claims=claims,
        )


class FirebaseAuthentication(BaseAuthentication):
    keyword = "bearer"

    def authenticate(self, request):
        header = get_authorization_header(request).split()
        if not header or header[0].lower() != self.keyword.encode():
            return None
        if len(header) != 2:
            raise AuthenticationFailed("Cabeçalho Authorization inválido. Use: Bearer <id_token>.")
        token = header[1].decode()
        claims = get_auth_provider().verify_id_token(token)
        return FirebaseUser.from_claims(claims), token

    def authenticate_header(self, request) -> str:
        # Faz o DRF responder 401 (e não 403) quando falta o token.
        return 'Bearer realm="api"'
