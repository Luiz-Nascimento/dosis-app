"""Firebase Auth real, via API REST (Identity Toolkit) e Admin SDK.

* Operações de conta (cadastro, login, refresh, e-mails): API REST com a
  ``FIREBASE_WEB_API_KEY`` do projeto.
* Validação do ID token: ``firebase_admin.auth.verify_id_token``.
* Com ``FIREBASE_AUTH_EMULATOR_HOST`` tudo aponta para o emulador local.
"""
from __future__ import annotations

from typing import Any

import requests
from django.conf import settings
from django.core.exceptions import ImproperlyConfigured
from firebase_admin import auth as admin_auth

from core.firebase import get_app

from .base import (
    AuthError,
    AuthProvider,
    AuthSession,
    AuthUnavailable,
    EmailAlreadyInUse,
    InvalidActionCode,
    InvalidCredentials,
    InvalidToken,
    NotAnonymous,
    TooManyAttempts,
    WeakPassword,
)

_TIMEOUT_SECONDS = 10

_ERRORS: dict[str, type[AuthError]] = {
    "EMAIL_EXISTS": EmailAlreadyInUse,
    "EMAIL_NOT_FOUND": InvalidCredentials,
    "INVALID_PASSWORD": InvalidCredentials,
    "INVALID_LOGIN_CREDENTIALS": InvalidCredentials,
    "USER_DISABLED": InvalidCredentials,
    "WEAK_PASSWORD": WeakPassword,
    "INVALID_ID_TOKEN": InvalidToken,
    "TOKEN_EXPIRED": InvalidToken,
    "USER_NOT_FOUND": InvalidToken,
    "INVALID_REFRESH_TOKEN": InvalidToken,
    "CREDENTIAL_TOO_OLD_LOGIN_AGAIN": InvalidToken,
    "EXPIRED_OOB_CODE": InvalidActionCode,
    "INVALID_OOB_CODE": InvalidActionCode,
    "TOO_MANY_ATTEMPTS_TRY_LATER": TooManyAttempts,
}


class FirebaseAuthProvider(AuthProvider):
    def __init__(self) -> None:
        emulator = settings.FIREBASE_AUTH_EMULATOR_HOST
        if emulator:
            self._identity_url = f"http://{emulator}/identitytoolkit.googleapis.com/v1"
            self._token_url = f"http://{emulator}/securetoken.googleapis.com/v1/token"
        else:
            self._identity_url = "https://identitytoolkit.googleapis.com/v1"
            self._token_url = "https://securetoken.googleapis.com/v1/token"

    # -- operações públicas --------------------------------------------------

    def sign_in_anonymously(self) -> AuthSession:
        data = self._call("accounts:signUp", {"returnSecureToken": True})
        return self._session(data["idToken"], data["refreshToken"], data["expiresIn"])

    def sign_up(self, email: str, password: str, name: str | None) -> AuthSession:
        data = self._call("accounts:signUp", {"email": email, "password": password, "returnSecureToken": True})
        if name:
            data = self._call(
                "accounts:update", {"idToken": data["idToken"], "displayName": name, "returnSecureToken": True}
            )
        self.send_email_verification(data["idToken"])
        return self._session(data["idToken"], data["refreshToken"], data["expiresIn"])

    def sign_in(self, email: str, password: str) -> AuthSession:
        data = self._call(
            "accounts:signInWithPassword", {"email": email, "password": password, "returnSecureToken": True}
        )
        return self._session(data["idToken"], data["refreshToken"], data["expiresIn"])

    def refresh(self, refresh_token: str) -> AuthSession:
        try:
            response = requests.post(
                self._token_url,
                params={"key": self._api_key()},
                data={"grant_type": "refresh_token", "refresh_token": refresh_token},
                timeout=_TIMEOUT_SECONDS,
            )
        except requests.RequestException as exc:
            raise AuthUnavailable() from exc
        data = self._parse(response)
        return self._session(data["id_token"], data["refresh_token"], data["expires_in"])

    def link_email(self, id_token: str, email: str, password: str, name: str | None) -> AuthSession:
        claims = self.verify_id_token(id_token)
        if claims.get("firebase", {}).get("sign_in_provider") != "anonymous":
            raise NotAnonymous()
        payload: dict[str, Any] = {"idToken": id_token, "email": email, "password": password, "returnSecureToken": True}
        if name:
            payload["displayName"] = name
        data = self._call("accounts:update", payload)
        self.send_email_verification(data["idToken"])
        return self._session(data["idToken"], data["refreshToken"], data["expiresIn"])

    def send_email_verification(self, id_token: str) -> None:
        self._call("accounts:sendOobCode", {"requestType": "VERIFY_EMAIL", "idToken": id_token})

    def confirm_email_verification(self, oob_code: str) -> None:
        self._call("accounts:update", {"oobCode": oob_code})

    def send_password_reset(self, email: str) -> None:
        try:
            self._call("accounts:sendOobCode", {"requestType": "PASSWORD_RESET", "email": email})
        except InvalidCredentials:
            pass  # Não revela se o e-mail existe.

    def confirm_password_reset(self, oob_code: str, new_password: str) -> None:
        self._call("accounts:resetPassword", {"oobCode": oob_code, "newPassword": new_password})

    def verify_id_token(self, id_token: str) -> dict[str, Any]:
        try:
            return admin_auth.verify_id_token(id_token, app=get_app())
        except admin_auth.CertificateFetchError as exc:
            raise AuthUnavailable() from exc
        except (ValueError, admin_auth.InvalidIdTokenError, admin_auth.UserDisabledError) as exc:
            raise InvalidToken() from exc

    def delete_user(self, uid: str) -> None:
        try:
            admin_auth.delete_user(uid, app=get_app())
        except admin_auth.UserNotFoundError:
            pass

    def set_custom_claims(self, uid: str, claims: dict[str, Any]) -> None:
        admin_auth.set_custom_user_claims(uid, claims or None, app=get_app())

    # -- interno -------------------------------------------------------------

    @staticmethod
    def _api_key() -> str:
        if not settings.FIREBASE_WEB_API_KEY and not settings.FIREBASE_AUTH_EMULATOR_HOST:
            raise ImproperlyConfigured("Defina FIREBASE_WEB_API_KEY no .env (Configurações do projeto no Firebase).")
        return settings.FIREBASE_WEB_API_KEY or "emulator"

    def _call(self, endpoint: str, payload: dict[str, Any]) -> dict[str, Any]:
        try:
            response = requests.post(
                f"{self._identity_url}/{endpoint}",
                params={"key": self._api_key()},
                json=payload,
                timeout=_TIMEOUT_SECONDS,
            )
        except requests.RequestException as exc:
            raise AuthUnavailable() from exc
        return self._parse(response)

    @staticmethod
    def _parse(response: requests.Response) -> dict[str, Any]:
        if response.ok:
            return response.json()
        try:
            message = response.json()["error"]["message"]
        except (ValueError, KeyError, TypeError):
            raise AuthUnavailable()
        # Ex.: "WEAK_PASSWORD : Password should be at least 6 characters"
        code = message.split(" ")[0].split(":")[0]
        raise _ERRORS.get(code, AuthError)()

    def _session(self, id_token: str, refresh_token: str, expires_in: str | int) -> AuthSession:
        claims = self.verify_id_token(id_token)
        return AuthSession(
            uid=claims["uid"],
            id_token=id_token,
            refresh_token=refresh_token,
            expires_in=int(expires_in),
            is_anonymous=claims.get("firebase", {}).get("sign_in_provider") == "anonymous",
            email=claims.get("email"),
            name=claims.get("name"),
            email_verified=bool(claims.get("email_verified")),
        )
