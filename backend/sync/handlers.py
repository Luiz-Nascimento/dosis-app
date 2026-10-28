"""Como cada tipo de registro que chega pelo sync é aplicado no Firestore.

Os handlers reaproveitam os mesmos serializers e repositórios dos CRUDs:
um registro sincronizado passa pelas mesmas validações e pela mesma
criptografia de um registro criado pela API.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any

from core.resources import Conflict, RecordNotFound, UserCollectionRepository
from profiles.repository import ProfileRepository
from profiles.serializers import ProfileSerializer
from tracking import repositories as r
from tracking import serializers as s


class SyncRejected(Exception):
    """Registro recusado de forma definitiva: o app não deve reenviar sem corrigir."""

    def __init__(self, code: str, message: str, details: Any = None):
        super().__init__(message)
        self.code = code
        self.message = message
        self.details = details

    def as_dict(self) -> dict[str, Any]:
        return {"code": self.code, "message": self.message, "details": self.details}


class EntityHandler(ABC):
    name: str

    @abstractmethod
    def upsert(self, uid: str, record_id: str, data: dict[str, Any]) -> None: ...

    @abstractmethod
    def delete(self, uid: str, record_id: str) -> None: ...


class CollectionHandler(EntityHandler):
    def __init__(self, name: str, serializer_class, repository_class: type[UserCollectionRepository]):
        self.name = name
        self.serializer_class = serializer_class
        self.repository_class = repository_class

    def upsert(self, uid: str, record_id: str, data: dict[str, Any]) -> None:
        repo = self.repository_class(uid)
        existing = repo.get(record_id)
        serializer = self.serializer_class(
            instance=existing, data=data, partial=existing is not None, context={"uid": uid}
        )
        if not serializer.is_valid():
            raise SyncRejected("validation_error", "Dados inválidos.", serializer.errors)
        validated = dict(serializer.validated_data)
        validated.pop("id", None)
        if existing is None:
            try:
                repo.create(validated, record_id)
                return
            except Conflict:
                pass  # Criado em paralelo: segue como atualização.
        repo.update(record_id, validated)

    def delete(self, uid: str, record_id: str) -> None:
        try:
            self.repository_class(uid).delete(record_id)
        except RecordNotFound:
            pass  # Já apagado: apagar de novo não é erro.


class ProfileHandler(EntityHandler):
    """O perfil é um documento único: o id do registro é o próprio uid."""

    name = "profile"

    def upsert(self, uid: str, record_id: str, data: dict[str, Any]) -> None:
        if record_id != uid:
            raise SyncRejected("invalid_record", "No perfil, o id do registro deve ser o uid do usuário.")
        serializer = ProfileSerializer(data=data, partial=True)
        if not serializer.is_valid():
            raise SyncRejected("validation_error", "Dados inválidos.", serializer.errors)
        ProfileRepository(uid).update(dict(serializer.validated_data))

    def delete(self, uid: str, record_id: str) -> None:
        raise SyncRejected("invalid_operation", "O perfil não é apagado pelo sync. Use DELETE /auth/me.")


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
