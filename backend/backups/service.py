"""Criação, armazenamento e restauração de backups.

Os backups ficam em ``users/{uid}/backups/{id}``: o documento guarda os
metadados e o cabeçalho do arquivo, e o conteúdo cifrado fica dividido em
``chunks`` (o Firestore limita cada documento a 1 MiB). O documento de
metadados é gravado por último: um backup só aparece depois de completo.
"""
from __future__ import annotations

import hashlib
import re
from typing import Any

from django.conf import settings

from core.fields import utcnow
from core.resources import ID_PATTERN
from core.store import get_store, new_id, user_collection, user_doc
from profiles.repository import ProfileRepository
from profiles.serializers import ProfileSerializer
from tracking import repositories as r
from tracking import serializers as s

from . import archive

# Ordem de restauração: itens da rotina antes das doses.
COLLECTIONS = {
    "routine_items": (r.RoutineItemRepository, s.RoutineItemSerializer),
    "dose_logs": (r.DoseLogRepository, s.DoseLogSerializer),
    "symptom_logs": (r.SymptomLogRepository, s.SymptomLogSerializer),
    "hydration_logs": (r.HydrationLogRepository, s.HydrationLogSerializer),
}
PROFILE_FIELDS = ("name", "age", "weight_kg", "height_cm", "biological_sex", "goal", "notifications")
SERVER_FIELDS = ("created_at", "updated_at", "modified_at")
CHUNK_CHARS = 500_000
TRANSACTION_WRITES = 400
_ID = re.compile(rf"^{ID_PATTERN}$")


def collect(uid: str) -> dict[str, Any]:
    profile = ProfileRepository(uid).get()
    return {
        "format": archive.FORMAT,
        "version": archive.VERSION,
        "exported_at": utcnow(),
        "profile": {k: profile.get(k) for k in PROFILE_FIELDS},
        "collections": {
            name: repo_cls(uid).list(order_by=[]) for name, (repo_cls, _) in COLLECTIONS.items()
        },
    }


def create_backup(uid: str, passphrase: str | None = None, reason: str = "manual") -> dict[str, Any]:
    backup_id = new_id()
    content = collect(uid)
    envelope = archive.seal(uid, backup_id, content, passphrase)
    ciphertext = envelope.pop("ciphertext")
    chunks = [ciphertext[i:i + CHUNK_CHARS] for i in range(0, len(ciphertext), CHUNK_CHARS)] or [""]

    store = get_store()
    for index, chunk in enumerate(chunks):
        store.set(user_doc(uid, "backups", backup_id, "chunks", f"{index:04d}"), {"data": chunk})
    meta = {
        "created_at": utcnow(),
        "reason": reason,
        "protected": envelope["protected"],
        "counts": {name: len(items) for name, items in content["collections"].items()},
        "size_bytes": len(ciphertext),
        "sha256": hashlib.sha256(ciphertext.encode()).hexdigest(),
        "chunk_count": len(chunks),
        "envelope": envelope,
    }
    store.set(user_doc(uid, "backups", backup_id), meta)
    _prune(uid)
    return _public(backup_id, meta)


def list_backups(uid: str) -> list[dict[str, Any]]:
    docs = get_store().list(user_collection(uid, "backups"), order_by=[("created_at", "desc")])
    return [_public(d.id, d.data) for d in docs]


def get_backup(uid: str, backup_id: str) -> dict[str, Any] | None:
    meta = get_store().get(user_doc(uid, "backups", backup_id))
    return None if meta is None else _public(backup_id, meta)


def load_file(uid: str, backup_id: str) -> dict[str, Any] | None:
    """Monta o arquivo completo (cabeçalho + conteúdo cifrado) para download ou restauração."""
    store = get_store()
    meta = store.get(user_doc(uid, "backups", backup_id))
    if meta is None:
        return None
    chunks = store.list(user_collection(uid, "backups", backup_id, "chunks"), order_by=[])
    return {**meta["envelope"], "ciphertext": "".join(c.data["data"] for c in chunks)}


def delete_backup(uid: str, backup_id: str) -> bool:
    store = get_store()
    path = user_doc(uid, "backups", backup_id)
    if store.get(path) is None:
        return False
    store.delete_tree(path)
    return True


def restore(uid: str, envelope: dict[str, Any], mode: str, passphrase: str | None = None) -> dict[str, Any]:
    content = archive.unseal(uid, envelope, passphrase)
    profile = _valid_profile(content.get("profile") or {})
    collections = {name: _valid_records(name, content.get("collections", {}).get(name, [])) for name in COLLECTIONS}

    # Rede de segurança: dá para desfazer a restauração com este backup.
    safety = create_backup(uid, reason="pre_restore")

    store = get_store()
    restored = {}
    for name, (repo_cls, _) in COLLECTIONS.items():
        if mode == "replace":
            store.delete_tree(user_collection(uid, name))
        repo = repo_cls(uid)
        records = collections[name]
        for start in range(0, len(records), TRANSACTION_WRITES):
            chunk = records[start:start + TRANSACTION_WRITES]

            def work(tx, chunk=chunk):
                # Sem efeitos colaterais: o Firestore pode repetir a função em caso de conflito.
                for record in chunk:
                    data = {k: v for k, v in record.items() if k != "id"}
                    tx.set(repo.path(record["id"]), repo.to_storage(record["id"], data))

            store.run_transaction(work)
        restored[name] = len(records)
    ProfileRepository(uid).update(profile)
    return {"mode": mode, "restored": restored, "safety_backup_id": safety["id"]}


# -- interno -----------------------------------------------------------------------


def _public(backup_id: str, meta: dict[str, Any]) -> dict[str, Any]:
    return {"id": backup_id, **{k: meta.get(k) for k in ("created_at", "reason", "protected", "counts", "size_bytes", "sha256")}}


def _prune(uid: str) -> None:
    for old in list_backups(uid)[settings.BACKUP_MAX_PER_USER:]:
        delete_backup(uid, old["id"])


def _valid_profile(profile: dict[str, Any]) -> dict[str, Any]:
    data = {k: v for k, v in profile.items() if k in PROFILE_FIELDS}
    serializer = ProfileSerializer(data=data, partial=True)
    if not serializer.is_valid():
        raise archive.BackupError("O perfil dentro do backup é inválido.")
    return {k: data.get(k) for k in PROFILE_FIELDS if k in data}


def _valid_records(name: str, records: Any) -> list[dict[str, Any]]:
    """Mantém só registros com id válido e campos conhecidos da entidade."""
    if not isinstance(records, list):
        raise archive.BackupError(f"A coleção {name} do backup é inválida.")
    allowed = set(COLLECTIONS[name][1]().fields) | set(SERVER_FIELDS)
    valid = []
    for record in records:
        if isinstance(record, dict) and isinstance(record.get("id"), str) and _ID.match(record["id"]):
            valid.append({k: v for k, v in record.items() if k in allowed})
    return valid
