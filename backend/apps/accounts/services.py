from __future__ import annotations

from datetime import datetime, timezone

from apps.core.auth import AuthSession, get_auth_provider
from apps.core.store import get_store, user_doc


def sync_user_document(session: AuthSession, accepted_terms: bool = False) -> None:
    """Cria ou atualiza ``users/{uid}`` com os dados da conta no Firebase Auth."""
    store = get_store()
    path = user_doc(session.uid)
    now = datetime.now(timezone.utc)
    data = {"is_anonymous": session.is_anonymous, "updated_at": now}
    # Não apaga nome/e-mail já salvos no perfil quando a sessão não os traz.
    if session.email:
        data["email"] = session.email
    if session.name:
        data["name"] = session.name
    existing = store.get(path)
    if existing is None:
        data["created_at"] = now
    if accepted_terms and not (existing or {}).get("terms_accepted_at"):
        data["terms_accepted_at"] = now
    store.set(path, data, merge=True)


def delete_account(uid: str) -> None:
    """Exclusão definitiva (LGPD): apaga todos os dados no Firestore e a conta no Firebase Auth."""
    get_store().delete_tree(user_doc(uid))
    get_auth_provider().delete_user(uid)
