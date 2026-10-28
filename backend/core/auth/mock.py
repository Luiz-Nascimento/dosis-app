"""Firebase Auth simulado (FIREBASE_MODE=mock).

As contas ficam na coleção ``mock_auth_users`` do próprio store mock e os
tokens são assinados com a SECRET_KEY do Django. As claims seguem o formato
do ID token do Firebase, então o restante do backend não percebe diferença.
Os "e-mails" (verificação e recuperação de senha) não são enviados: o link é
escrito no log ``dosis.auth`` e guardado em ``outbox`` para os testes.
"""
from __future__ import annotations

import hashlib
import hmac
import logging
import secrets
import time
from dataclasses import dataclass
from typing import Any

from django.conf import settings
from django.core import signing

from core.store import DocumentStore, new_id

from .base import (
    AuthProvider,
    AuthSession,
    EmailAlreadyInUse,
    InvalidActionCode,
    InvalidCredentials,
    InvalidToken,
    NotAnonymous,
)

logger = logging.getLogger("dosis.auth")

USERS = "mock_auth_users"
_ID_SALT = "dosis.mock.id_token"
_REFRESH_SALT = "dosis.mock.refresh_token"
_OOB_SALT = "dosis.mock.oob_code"
_OOB_TTL_SECONDS = 60 * 60 * 24
# Iterações reduzidas: é só o mock. No modo firebase quem guarda senhas é o Firebase.
_PBKDF2_ITERATIONS = 20_000


@dataclass(frozen=True)
class MockEmail:
    to: str
    action: str
    oob_code: str


def _hash_password(password: str, salt: str) -> str:
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), _PBKDF2_ITERATIONS)
    return digest.hex()


class MockAuthProvider(AuthProvider):
    def __init__(self, store: DocumentStore):
        self._store = store
        self.outbox: list[MockEmail] = []

    # -- operações públicas --------------------------------------------------

    def sign_in_anonymously(self) -> AuthSession:
        uid = new_id()
        self._store.create(f"{USERS}/{uid}", {"is_anonymous": True, "email_verified": False})
        return self._session(uid)

    def sign_up(self, email: str, password: str, name: str | None) -> AuthSession:
        email = email.strip().lower()
        if self._find_by_email(email):
            raise EmailAlreadyInUse()
        uid = new_id()
        self._store.create(f"{USERS}/{uid}", {
            "email": email,
            "name": name,
            "is_anonymous": False,
            "email_verified": False,
            **self._password_fields(password),
        })
        self._send(email, "verifyEmail", uid)
        return self._session(uid)

    def sign_in(self, email: str, password: str) -> AuthSession:
        found = self._find_by_email(email.strip().lower())
        if not found:
            raise InvalidCredentials()
        uid, user = found
        expected = _hash_password(password, user["password_salt"])
        if not hmac.compare_digest(expected, user["password_hash"]):
            raise InvalidCredentials()
        return self._session(uid)

    def refresh(self, refresh_token: str) -> AuthSession:
        try:
            payload = signing.loads(
                refresh_token, salt=_REFRESH_SALT, max_age=settings.MOCK_REFRESH_TOKEN_TTL_SECONDS
            )
        except signing.BadSignature as exc:
            raise InvalidToken() from exc
        if not self._user(payload["uid"]):
            raise InvalidToken()
        return self._session(payload["uid"])

    def link_email(self, id_token: str, email: str, password: str, name: str | None) -> AuthSession:
        uid = self.verify_id_token(id_token)["uid"]
        user = self._user(uid)
        if not user.get("is_anonymous"):
            raise NotAnonymous()
        email = email.strip().lower()
        if self._find_by_email(email):
            raise EmailAlreadyInUse()
        self._store.update(f"{USERS}/{uid}", {
            "email": email,
            "name": name or user.get("name"),
            "is_anonymous": False,
            **self._password_fields(password),
        })
        self._send(email, "verifyEmail", uid)
        return self._session(uid)

    def send_email_verification(self, id_token: str) -> None:
        uid = self.verify_id_token(id_token)["uid"]
        user = self._user(uid)
        if user.get("email") and not user.get("email_verified"):
            self._send(user["email"], "verifyEmail", uid)

    def confirm_email_verification(self, oob_code: str) -> None:
        payload = self._read_oob(oob_code, "verifyEmail")
        self._store.update(f"{USERS}/{payload['uid']}", {"email_verified": True})

    def send_password_reset(self, email: str) -> None:
        found = self._find_by_email(email.strip().lower())
        if found:
            uid, user = found
            self._send(user["email"], "resetPassword", uid, fingerprint=user["password_hash"][:16])

    def confirm_password_reset(self, oob_code: str, new_password: str) -> None:
        payload = self._read_oob(oob_code, "resetPassword")
        user = self._user(payload["uid"])
        # O código vale uma vez só: depois que a senha muda, a impressão digital não bate.
        if user.get("password_hash", "")[:16] != payload.get("fingerprint"):
            raise InvalidActionCode()
        self._store.update(f"{USERS}/{payload['uid']}", self._password_fields(new_password))

    def verify_id_token(self, id_token: str) -> dict[str, Any]:
        try:
            claims = signing.loads(id_token, salt=_ID_SALT, max_age=settings.MOCK_ID_TOKEN_TTL_SECONDS)
        except signing.BadSignature as exc:
            raise InvalidToken() from exc
        if not self._store.get(f"{USERS}/{claims['uid']}"):
            raise InvalidToken()
        return claims

    def delete_user(self, uid: str) -> None:
        self._store.delete(f"{USERS}/{uid}")

    def set_custom_claims(self, uid: str, claims: dict[str, Any]) -> None:
        self._user(uid)
        self._store.update(f"{USERS}/{uid}", {"custom_claims": claims})

    # -- interno -------------------------------------------------------------

    def _user(self, uid: str) -> dict[str, Any]:
        user = self._store.get(f"{USERS}/{uid}")
        if user is None:
            raise InvalidToken()
        return user

    def _find_by_email(self, email: str) -> tuple[str, dict[str, Any]] | None:
        docs = self._store.list(USERS, where=[("email", "==", email)], limit=1)
        return (docs[0].id, docs[0].data) if docs else None

    @staticmethod
    def _password_fields(password: str) -> dict[str, str]:
        salt = secrets.token_hex(16)
        return {"password_salt": salt, "password_hash": _hash_password(password, salt)}

    def _session(self, uid: str) -> AuthSession:
        user = self._user(uid)
        provider = "anonymous" if user.get("is_anonymous") else "password"
        claims = {
            **user.get("custom_claims", {}),
            "uid": uid,
            "user_id": uid,
            "email": user.get("email"),
            "email_verified": bool(user.get("email_verified")),
            "name": user.get("name"),
            "iat": int(time.time()),
            "firebase": {"sign_in_provider": provider},
        }
        return AuthSession(
            uid=uid,
            id_token=signing.dumps(claims, salt=_ID_SALT, compress=True),
            refresh_token=signing.dumps({"uid": uid}, salt=_REFRESH_SALT),
            expires_in=settings.MOCK_ID_TOKEN_TTL_SECONDS,
            is_anonymous=provider == "anonymous",
            email=user.get("email"),
            name=user.get("name"),
            email_verified=bool(user.get("email_verified")),
        )

    def _send(self, email: str, action: str, uid: str, **extra: Any) -> None:
        code = signing.dumps({"uid": uid, "action": action, **extra}, salt=_OOB_SALT)
        self.outbox.append(MockEmail(to=email, action=action, oob_code=code))
        logger.info("[mock e-mail] %s para %s | oob_code=%s", action, email, code)

    @staticmethod
    def _read_oob(oob_code: str, action: str) -> dict[str, Any]:
        try:
            payload = signing.loads(oob_code, salt=_OOB_SALT, max_age=_OOB_TTL_SECONDS)
        except signing.BadSignature as exc:
            raise InvalidActionCode() from exc
        if payload.get("action") != action:
            raise InvalidActionCode()
        return payload
