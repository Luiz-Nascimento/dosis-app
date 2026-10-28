"""Formato do arquivo de backup e sua criptografia.

Conteúdo: ``JSON → gzip → AES-256-GCM``. A chave vem de um destes caminhos:

* **chave do servidor** (padrão): HKDF-SHA256 sobre a chave mestra dos campos
  (``FIELD_ENCRYPTION_KEY``), com salt aleatório por backup e o ``uid`` no
  ``info``. Só restaura na mesma conta.
* **senha do usuário** (opcional): scrypt(senha, salt aleatório). O servidor
  não consegue abrir sem a senha, e o arquivo baixado pode ser restaurado em
  outra conta (ex.: depois de excluir a conta e criar outra).
"""
from __future__ import annotations

import gzip
import io
import os
from typing import Any

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives.kdf.scrypt import Scrypt
from rest_framework import status
from rest_framework.exceptions import APIException

from apps.core import jsoncodec
from apps.core.crypto import b64decode, b64encode, field_key

FORMAT = "dosis-backup"
VERSION = 1
ALGORITHM = "A256GCM"
SCRYPT_PARAMS = {"n": 2**15, "r": 8, "p": 1}
MAX_PLAINTEXT_BYTES = 50 * 1024 * 1024


class BackupError(APIException):
    status_code = status.HTTP_400_BAD_REQUEST
    default_code = "invalid_backup"
    default_detail = "Arquivo de backup inválido ou corrompido."


class PassphraseRequired(BackupError):
    default_code = "passphrase_required"
    default_detail = "Este backup é protegido por senha. Informe a senha para restaurar."


class InvalidPassphrase(BackupError):
    default_code = "invalid_passphrase"
    default_detail = "Senha do backup incorreta."


def _server_key(uid: str, salt: bytes) -> bytes:
    info = f"dosis-backup-v1:{uid}".encode()
    return HKDF(algorithm=hashes.SHA256(), length=32, salt=salt, info=info).derive(field_key())


def _passphrase_key(passphrase: str, salt: bytes, params: dict[str, int]) -> bytes:
    return Scrypt(salt=salt, length=32, **params).derive(passphrase.encode())


def _aad(backup_id: str, uid: str | None) -> bytes:
    # Backup com senha não fica preso ao uid: pode ser levado para outra conta.
    return f"dosis-backup-v1:{backup_id}:{uid or '*'}".encode()


def seal(uid: str, backup_id: str, content: dict[str, Any], passphrase: str | None = None) -> dict[str, Any]:
    """Comprime e cifra o conteúdo. Devolve o arquivo (envelope) pronto para guardar/baixar."""
    salt = os.urandom(16)
    if passphrase:
        key = _passphrase_key(passphrase, salt, SCRYPT_PARAMS)
        kdf = {"name": "scrypt", "salt": b64encode(salt), **SCRYPT_PARAMS}
        bound_uid = None
    else:
        key = _server_key(uid, salt)
        kdf = {"name": "server-hkdf", "salt": b64encode(salt)}
        bound_uid = uid
    nonce = os.urandom(12)
    compressed = gzip.compress(jsoncodec.dumps(content).encode())
    ciphertext = AESGCM(key).encrypt(nonce, compressed, _aad(backup_id, bound_uid))
    return {
        "format": FORMAT,
        "version": VERSION,
        "backup_id": backup_id,
        "protected": bool(passphrase),
        "algorithm": ALGORITHM,
        "compression": "gzip",
        "kdf": kdf,
        "nonce": b64encode(nonce),
        "ciphertext": b64encode(ciphertext),
    }


def unseal(uid: str, envelope: dict[str, Any], passphrase: str | None = None) -> dict[str, Any]:
    """Decifra um arquivo de backup e devolve o conteúdo."""
    if envelope.get("format") != FORMAT or envelope.get("version") != VERSION:
        raise BackupError("Formato de backup desconhecido.")
    try:
        kdf = envelope["kdf"]
        salt = b64decode(kdf["salt"])
        nonce = b64decode(envelope["nonce"])
        ciphertext = b64decode(envelope["ciphertext"])
        backup_id = envelope["backup_id"]
    except (KeyError, TypeError, ValueError) as exc:
        raise BackupError() from exc

    if kdf.get("name") == "scrypt":
        if not passphrase:
            raise PassphraseRequired()
        params = {k: int(kdf[k]) for k in ("n", "r", "p")}
        if params["n"] > 2**20 or params["r"] > 32 or params["p"] > 16:
            raise BackupError("Parâmetros de derivação de chave fora do limite.")
        key, aad, wrong = _passphrase_key(passphrase, salt, params), _aad(backup_id, None), InvalidPassphrase
    elif kdf.get("name") == "server-hkdf":
        key, aad, wrong = _server_key(uid, salt), _aad(backup_id, uid), BackupError
    else:
        raise BackupError("Derivação de chave desconhecida.")

    try:
        compressed = AESGCM(key).decrypt(nonce, ciphertext, aad)
    except InvalidTag as exc:
        raise wrong() from exc
    try:
        with gzip.GzipFile(fileobj=io.BytesIO(compressed)) as stream:
            raw = stream.read(MAX_PLAINTEXT_BYTES + 1)
    except OSError as exc:
        raise BackupError() from exc
    if len(raw) > MAX_PLAINTEXT_BYTES:
        raise BackupError("Backup grande demais.")
    content = jsoncodec.loads(raw)
    if not isinstance(content, dict) or content.get("format") != FORMAT:
        raise BackupError()
    return content
