"""Como cada tipo de registro que chega pelo sync vira uma escrita no Firestore.

Os handlers reaproveitam os mesmos serializers e repositórios dos CRUDs:
um registro sincronizado passa pelas mesmas validações e pela mesma
criptografia de um registro criado pela API.

A validação acontece antes da transação (``prepare``). A transação em si
(em ``service.py``) só decide se a escrita vale e grava documento + recibo
juntos.
"""
from __future__ import annotations

import datetime as dt
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any

from core.resources import UserCollectionRepository
from core.store import user_doc
from profiles.repository import ProfileRepository
from profiles.serializers import ProfileSerializer
from tracking import repositories as r
from tracking import serializers as s

_SERVER_FIELDS = ("id", "created_at", "updated_at", "modified_at")


class SyncRejected(Exception):
    """Registro recusado: o app deve corrigir antes de reenviar."""

    def __init__(self, code: str, message: str, details: Any = None):
        super().__init__(message)
        self.code = code
        self.message = message
        self.details = details

    def as_dict(self) -> dict[str, Any]:
        return {"code": self.code, "message": self.message, "details": self.details}


@dataclass(frozen=True)
class PreparedWrite:
    """Escrita já validada e cifrada, pronta para entrar na transação."""

    path: str
    op: str
    # Documento completo, se ele não existir na hora da transação.
    create_payload: dict[str, Any] | None = None
    # Campos a mesclar, se ele já existir.
    update_payload: dict[str, Any] | None = None
    # Lápide de exclusão: impede que uma mudança antiga recrie o registro.
    tombstone_path: str | None = None


class EntityHandler(ABC):
    name: str

    @abstractmethod
    def prepare(self, uid: str, record: dict[str, Any], modified_at: dt.datetime) -> PreparedWrite: ...


class CollectionHandler(EntityHandler):
    def __init__(self, name: str, serializer_class, repository_class: type[UserCollectionRepository]):
        self.name = name
        self.serializer_class = serializer_class
        self.repository_class = repository_class

    def prepare(self, uid: str, record: dict[str, Any], modified_at: dt.datetime) -> PreparedWrite:
        repo = self.repository_class(uid)
        record_id = record["id"]
        tombstone = user_doc(uid, "sync_tombstones", f"{self.name}__{record_id}")
        if record["op"] == "delete":
            return PreparedWrite(path=repo.path(record_id), op="delete", tombstone_path=tombstone)

        existing = repo.get(record_id)
        serializer = self.serializer_class(
            instance=existing, data=record["data"], partial=existing is not None, context={"uid": uid}
        )
        if not serializer.is_valid():
            raise SyncRejected("validation_error", "Dados inválidos.", serializer.errors)
        changes = {k: v for k, v in serializer.validated_data.items() if k not in _SERVER_FIELDS}
        full = {**{k: v for k, v in (existing or {}).items() if k not in _SERVER_FIELDS}, **changes}
        return PreparedWrite(
            path=repo.path(record_id),
            op="upsert",
            create_payload=repo.storage_for_create(record_id, full, modified_at),
            update_payload=repo.storage_for_update(record_id, changes, modified_at),
            tombstone_path=tombstone,
        )


class ProfileHandler(EntityHandler):
    """O perfil é um documento único: o id do registro é o próprio uid."""

    name = "profile"

    def prepare(self, uid: str, record: dict[str, Any], modified_at: dt.datetime) -> PreparedWrite:
        if record["id"] != uid:
            raise SyncRejected("invalid_record", "No perfil, o id do registro deve ser o uid do usuário.")
        if record["op"] == "delete":
            raise SyncRejected("invalid_operation", "O perfil não é apagado pelo sync. Use DELETE /auth/me.")
        serializer = ProfileSerializer(data=record["data"], partial=True)
        if not serializer.is_valid():
            raise SyncRejected("validation_error", "Dados inválidos.", serializer.errors)
        payload = ProfileRepository(uid).storage_for_update(dict(serializer.validated_data), modified_at)
        return PreparedWrite(
            path=user_doc(uid), op="upsert",
            create_payload={**payload, "created_at": payload["updated_at"]},
            update_payload=payload,
        )


# A ordem importa: aplique itens da rotina antes das doses que apontam para eles.
HANDLERS: dict[str, EntityHandler] = {
    handler.name: handler
    for handler in (
        ProfileHandler(),
        CollectionHandler("routine_items", s.RoutineItemSerializer, r.RoutineItemRepository),
        CollectionHandler("dose_logs", s.DoseLogSerializer, r.DoseLogRepository),
        CollectionHandler("symptom_logs", s.SymptomLogSerializer, r.SymptomLogRepository),
        CollectionHandler("hydration_logs", s.HydrationLogSerializer, r.HydrationLogRepository),
    )
}
