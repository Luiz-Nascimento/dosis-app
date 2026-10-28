from __future__ import annotations

from datetime import datetime, timezone

from core.auth import AuthSession
from core.store import get_store, user_doc


def sync_user_document(session: AuthSession, accepted_terms: bool = False) -> None:
    """Cria ou atualiza ``users/{uid}`` com os dados da conta no Firebase Auth."""
    store = get_store()
    path = user_doc(session.uid)
    now = datetime.now(timezone.utc)
    data = {
        "is_anonymous": session.is_anonymous,
        "email": session.email,
        "name": session.name,
        "updated_at": now,
    }
    existing = store.get(path)
    if existing is None:
        data["created_at"] = now
    if accepted_terms and not (existing or {}).get("terms_accepted_at"):
        data["terms_accepted_at"] = now
    store.set(path, data, merge=True)
