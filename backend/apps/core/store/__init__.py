from __future__ import annotations

import threading
from typing import Callable

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
    "register_mock_seeder",
    "reset_store",
    "user_doc",
    "user_collection",
]

_store: DocumentStore | None = None
_lock = threading.Lock()
_mock_seeders: list[Callable[[DocumentStore], object]] = []


def register_mock_seeder(seeder: Callable[[DocumentStore], object]) -> None:
    """Registra uma função que popula o store mock assim que ele é criado
    (ex.: catálogo e artigos). No Firestore real use o comando seed_content."""
    if seeder not in _mock_seeders:
        _mock_seeders.append(seeder)


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
    from apps.core.firebase import MODE_MOCK, firebase_mode, firestore_client

    if firebase_mode() == MODE_MOCK:
        from .memory import MemoryStore

        store = MemoryStore(settings.MOCK_STORE_PATH or None)
        for seeder in _mock_seeders:
            seeder(store)
        return store

    from .firestore import FirestoreStore

    return FirestoreStore(firestore_client())


def user_doc(uid: str, *segments: str) -> str:
    """Caminho de documento dentro da árvore do usuário: ``users/{uid}/...``."""
    return doc_path("users", uid, *segments)


def user_collection(uid: str, *segments: str) -> str:
    """Caminho de coleção dentro da árvore do usuário: ``users/{uid}/...``."""
    return collection_path("users", uid, *segments)
