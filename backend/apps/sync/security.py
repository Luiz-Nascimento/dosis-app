"""Compressão, criptografia e consentimento da sincronização.

Chave do lote (sem a chave trafegar pela rede):

1. O app gera um par X25519 e envia só a chave pública em ``POST /sync/keys``.
2. O servidor gera o próprio par, calcula o segredo compartilhado (ECDH) e
   deriva a chave AES-256 com HKDF-SHA256 (salt = ``key_id``, info =
   ``dosis-sync-v1``). Devolve a sua chave pública e o ``key_id``.
3. O app faz o mesmo cálculo e chega à mesma chave. Ela fica no Android
   Keystore; no servidor, fica cifrada em ``users/{uid}/sync_keys/{key_id}``.

Lote: JSON → gzip → AES-256-GCM (nonce de 12 bytes, AAD
``dosis-sync-v1:{uid}:{key_id}``) → base64url dentro do envelope.
"""
from __future__ import annotations

import json
import zlib
from typing import Any

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey, X25519PublicKey
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from django.conf import settings
from rest_framework import status
from rest_framework.exceptions import APIException

from apps.core.crypto import b64decode, b64encode, decrypt_value, encrypt_value
from apps.core.fields import utcnow
from apps.core.store import get_store, new_id, user_doc

ALGORITHM = "A256GCM"
KEY_AGREEMENT = "X25519-HKDF-SHA256"
HKDF_INFO = b"dosis-sync-v1"
NONCE_BYTES = 12

# Aviso exibido no app antes da primeira sincronização. Mudou o texto? Suba a versão:
# todo mundo precisa aceitar de novo.
NOTICE = {
    "version": "2026-10-27",
    "title": "Antes de sincronizar",
    "text": (
        "Seus registros (rotina, doses, sintomas, água e dados do perfil) ficam salvos no seu "
        "celular. Se você ativar a sincronização, uma cópia vai para a nuvem (Firebase) apenas "
        "quando houver Wi-Fi. Antes de sair do aparelho, os dados são comprimidos e criptografados "
        "(AES-256), e os dados de saúde continuam cifrados no servidor. Você pode desativar a "
        "sincronização quando quiser e excluir todos os seus dados em Perfil."
    ),
}


class SyncSecurityError(APIException):
    status_code = status.HTTP_400_BAD_REQUEST
    default_code = "invalid_envelope"
    default_detail = "Lote em formato inválido."


class EncryptionRequired(SyncSecurityError):
    default_code = "encryption_required"
    default_detail = "O lote precisa ser comprimido e criptografado antes do envio."


class UnknownSyncKey(SyncSecurityError):
    default_code = "unknown_sync_key"
    default_detail = "Chave de sincronização desconhecida. Gere uma nova em /api/v1/sync/keys/."


class DecryptionFailed(SyncSecurityError):
    default_code = "decryption_failed"
    default_detail = "Não foi possível decifrar o lote. Confira a chave e o nonce."


class PayloadTooLarge(SyncSecurityError):
    status_code = status.HTTP_413_REQUEST_ENTITY_TOO_LARGE
    default_code = "payload_too_large"
    default_detail = "O lote descompactado passou do tamanho máximo."


class ConsentRequired(APIException):
    status_code = status.HTTP_428_PRECONDITION_REQUIRED
    default_code = "sync_consent_required"
    default_detail = "Mostre o aviso de sincronização e registre o aceite em /api/v1/sync/consent/ antes de enviar."


# -- Chaves -------------------------------------------------------------------


def _key_path(uid: str, key_id: str) -> str:
    return user_doc(uid, "sync_keys", key_id)


def derive_key(shared_secret: bytes, key_id: str) -> bytes:
    return HKDF(algorithm=hashes.SHA256(), length=32, salt=key_id.encode(), info=HKDF_INFO).derive(shared_secret)


def create_sync_key(uid: str, device_id: str, client_public_key: str) -> dict[str, Any]:
    try:
        client_key = X25519PublicKey.from_public_bytes(b64decode(client_public_key))
    except ValueError as exc:
        raise SyncSecurityError("client_public_key deve ser uma chave pública X25519 (32 bytes, base64url).") from exc

    server_private = X25519PrivateKey.generate()
    key_id = new_id()
    key = derive_key(server_private.exchange(client_key), key_id)
    path = _key_path(uid, key_id)
    get_store().set(path, {
        "device_id": device_id,
        "algorithm": ALGORITHM,
        "key_agreement": KEY_AGREEMENT,
        "key": encrypt_value(b64encode(key), f"{path}#key"),
        "created_at": utcnow(),
    })
    return {
        "key_id": key_id,
        "server_public_key": b64encode(server_private.public_key().public_bytes_raw()),
        "algorithm": ALGORITHM,
        "key_agreement": KEY_AGREEMENT,
        "hkdf_info": HKDF_INFO.decode(),
    }


def load_sync_key(uid: str, key_id: str) -> bytes:
    path = _key_path(uid, key_id)
    doc = get_store().get(path)
    if doc is None:
        raise UnknownSyncKey()
    return b64decode(decrypt_value(doc["key"], f"{path}#key"))


# -- Envelope -----------------------------------------------------------------


def envelope_aad(uid: str, key_id: str) -> bytes:
    return f"dosis-sync-v1:{uid}:{key_id}".encode()


def open_envelope(uid: str, envelope: dict[str, Any]) -> dict[str, Any]:
    """Decifra e descomprime um lote. Devolve o JSON do lote em claro."""
    key = load_sync_key(uid, envelope["key_id"])
    try:
        nonce = b64decode(envelope["nonce"])
        ciphertext = b64decode(envelope["payload"])
    except ValueError as exc:
        raise SyncSecurityError("nonce e payload devem estar em base64url.") from exc
    if len(nonce) != NONCE_BYTES:
        raise SyncSecurityError(f"O nonce deve ter {NONCE_BYTES} bytes.")
    try:
        plaintext = AESGCM(key).decrypt(nonce, ciphertext, envelope_aad(uid, envelope["key_id"]))
    except InvalidTag as exc:
        raise DecryptionFailed() from exc
    if envelope["compression"] == "gzip":
        plaintext = gunzip(plaintext, settings.SYNC_MAX_PAYLOAD_BYTES)
    elif len(plaintext) > settings.SYNC_MAX_PAYLOAD_BYTES:
        raise PayloadTooLarge()
    try:
        batch = json.loads(plaintext)
    except ValueError as exc:
        raise SyncSecurityError("O conteúdo decifrado não é um JSON válido.") from exc
    if not isinstance(batch, dict):
        raise SyncSecurityError("O conteúdo decifrado deve ser um objeto JSON.")
    return batch


def gunzip(data: bytes, limit: int) -> bytes:
    """Descompacta com limite de tamanho (proteção contra "zip bomb")."""
    decompressor = zlib.decompressobj(wbits=16 + zlib.MAX_WBITS)
    try:
        output = decompressor.decompress(data, limit + 1)
    except zlib.error as exc:
        raise SyncSecurityError("O conteúdo não é um gzip válido.") from exc
    if len(output) > limit or decompressor.unconsumed_tail:
        raise PayloadTooLarge()
    return output


# -- Consentimento --------------------------------------------------------------


def consent_status(uid: str) -> dict[str, Any]:
    consent = (get_store().get(user_doc(uid)) or {}).get("sync_consent") or {}
    return {
        "notice": NOTICE,
        "accepted": consent.get("version") == NOTICE["version"],
        "accepted_version": consent.get("version"),
        "accepted_at": consent.get("accepted_at"),
    }


def accept_consent(uid: str) -> dict[str, Any]:
    get_store().set(
        user_doc(uid), {"sync_consent": {"version": NOTICE["version"], "accepted_at": utcnow()}}, merge=True
    )
    return consent_status(uid)


def revoke_consent(uid: str) -> None:
    get_store().set(user_doc(uid), {"sync_consent": None}, merge=True)


def require_consent(uid: str) -> None:
    if not consent_status(uid)["accepted"]:
        raise ConsentRequired()
