"""Criptografia de campos sensíveis antes de gravar no Firestore.

Cada valor é serializado em JSON e cifrado com AES-256-GCM. O texto gravado
tem o formato ``enc:v1:<base64url(nonce || ciphertext+tag)>``. O caminho do
documento e o nome do campo entram como dado associado (AAD): um valor
cifrado copiado para outro documento ou campo não decifra.

A chave vem de ``FIELD_ENCRYPTION_KEY`` (32 bytes em base64). Sem ela, uma
chave é derivada da SECRET_KEY, o que só serve para desenvolvimento.
"""
from __future__ import annotations

import base64
import json
import os
from functools import lru_cache
from typing import Any

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from django.conf import settings
from django.core.exceptions import ImproperlyConfigured

PREFIX = "enc:v1:"
_NONCE_BYTES = 12


class DecryptionError(Exception):
    pass


def b64decode(value: str) -> bytes:
    return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))


def b64encode(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def derive_key(secret: bytes, info: bytes) -> bytes:
    return HKDF(algorithm=hashes.SHA256(), length=32, salt=None, info=info).derive(secret)


@lru_cache(maxsize=4)
def _key_for(raw_key: str, secret_key: str) -> bytes:
    if raw_key:
        key = b64decode(raw_key)
        if len(key) != 32:
            raise ImproperlyConfigured("FIELD_ENCRYPTION_KEY deve ter 32 bytes em base64.")
        return key
    return derive_key(secret_key.encode(), b"dosis-field-encryption")


def field_key() -> bytes:
    return _key_for(settings.FIELD_ENCRYPTION_KEY, settings.SECRET_KEY)


def encrypt_value(value: Any, aad: str, key: bytes | None = None) -> str:
    plaintext = json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode()
    nonce = os.urandom(_NONCE_BYTES)
    ciphertext = AESGCM(key or field_key()).encrypt(nonce, plaintext, aad.encode())
    return PREFIX + b64encode(nonce + ciphertext)


def decrypt_value(token: Any, aad: str, key: bytes | None = None) -> Any:
    if not is_encrypted(token):
        return token
    raw = b64decode(token[len(PREFIX):])
    try:
        plaintext = AESGCM(key or field_key()).decrypt(raw[:_NONCE_BYTES], raw[_NONCE_BYTES:], aad.encode())
    except InvalidTag as exc:
        raise DecryptionError(f"Não foi possível decifrar o campo ({aad}).") from exc
    return json.loads(plaintext)


def is_encrypted(value: Any) -> bool:
    return isinstance(value, str) and value.startswith(PREFIX)


def encrypt_fields(path: str, data: dict[str, Any], fields: tuple[str, ...]) -> dict[str, Any]:
    """Cifra os campos listados que estiverem presentes e não forem nulos."""
    out = dict(data)
    for name in fields:
        if out.get(name) is not None:
            out[name] = encrypt_value(out[name], f"{path}#{name}")
    return out


def decrypt_fields(path: str, data: dict[str, Any], fields: tuple[str, ...]) -> dict[str, Any]:
    out = dict(data)
    for name in fields:
        if name in out:
            out[name] = decrypt_value(out[name], f"{path}#{name}")
    return out
