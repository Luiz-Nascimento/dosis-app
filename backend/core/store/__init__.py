from __future__ import annotations

import threading

from django.conf import settings

from .base import (
    Doc,
    DocumentAlreadyExists,
    DocumentNotFound,
    DocumentStore,
    StoreError,
    Transaction,
    collection_path,
    doc_path,
    new_id,
)

__all__ = [
    "Doc",
    "DocumentAlreadyExists",
    "DocumentNotFound",
    "DocumentStore",
    "StoreError",
    "Transaction",
    "collection_path",
    "doc_path",
    "get_store",
    "new_id",
    "reset_store",
    "user_doc",
    "user_collection",
]

_store: DocumentStore | None = None
_lock = threading.Lock()


def get_store() -> DocumentStore:
    """Store do modo configurado em FIREBASE_MODE (instância única por processo)."""
    global _store
    if _store is None:
        with _lock:
            if _store is None:
                _store = _build_store()
    return _store


def reset_store() -> None:
    """Descarta a instância atual (usado nos testes)."""
    global _store
    with _lock:
        _store = None


def _build_store() -> DocumentStore:
    from core.firebase import MODE_MOCK, firebase_mode, firestore_client

    if firebase_mode() == MODE_MOCK:
        from .memory import MemoryStore

        return MemoryStore(settings.MOCK_STORE_PATH or None)

    from .firestore import FirestoreStore

    return FirestoreStore(firestore_client())


def user_doc(uid: str, *segments: str) -> str:
    """Caminho de documento dentro da árvore do usuário: ``users/{uid}/...``."""
    return doc_path("users", uid, *segments)


def user_collection(uid: str, *segments: str) -> str:
    """Caminho de coleção dentro da árvore do usuário: ``users/{uid}/...``."""
    return collection_path("users", uid, *segments)
