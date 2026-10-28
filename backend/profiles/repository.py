from __future__ import annotations

from typing import Any

from core.crypto import decrypt_fields, encrypt_fields
from core.fields import utcnow
from core.store import DocumentStore, get_store, user_doc

DEFAULT_NOTIFICATIONS = {"dose_reminders": True, "symptom_reminder": True}


class ProfileRepository:
    """Perfil do usuário no documento raiz ``users/{uid}``."""

    # Dados de saúde e pessoais usados nos cálculos: ficam cifrados no Firestore.
    encrypted_fields = ("age", "weight_kg", "height_cm", "biological_sex")

    def __init__(self, uid: str, store: DocumentStore | None = None):
        self.uid = uid
        self.store = store or get_store()
        self.path = user_doc(uid)

    def get(self) -> dict[str, Any]:
        data = decrypt_fields(self.path, self.store.get(self.path) or {}, self.encrypted_fields)
        return {
            "uid": self.uid,
            "email": data.get("email"),
            "is_anonymous": data.get("is_anonymous", True),
            "name": data.get("name"),
            "age": data.get("age"),
            "weight_kg": data.get("weight_kg"),
            "height_cm": data.get("height_cm"),
            "biological_sex": data.get("biological_sex"),
            "goal": data.get("goal"),
            "notifications": {**DEFAULT_NOTIFICATIONS, **data.get("notifications", {})},
            "terms_accepted_at": data.get("terms_accepted_at"),
            "created_at": data.get("created_at"),
            "updated_at": data.get("updated_at"),
        }

    def storage_for_update(self, changes: dict[str, Any], modified_at=None) -> dict[str, Any]:
        now = utcnow()
        record = {**changes, "updated_at": now, "modified_at": modified_at or now}
        return encrypt_fields(self.path, record, self.encrypted_fields)

    def update(self, changes: dict[str, Any]) -> dict[str, Any]:
        self.store.set(self.path, self.storage_for_update(changes), merge=True)
        return self.get()
