"""Implementação do DocumentStore sobre o Firestore real (firebase-admin)."""
from __future__ import annotations

from typing import Any, Callable, Iterable

from google.api_core import exceptions as gexc
from google.cloud import firestore as gfirestore
from google.cloud.firestore_v1.base_query import FieldFilter

from .base import (
    Doc,
    DocumentAlreadyExists,
    DocumentNotFound,
    DocumentStore,
    Filter,
    Order,
    T,
    Transaction,
    validate_collection_path,
    validate_doc_path,
    validate_query,
)


class _FirestoreTransaction(Transaction):
    def __init__(self, db: gfirestore.Client, transaction: gfirestore.Transaction):
        self._db = db
        self._tx = transaction

    def get(self, path: str) -> dict[str, Any] | None:
        snapshot = self._db.document(path).get(transaction=self._tx)
        return snapshot.to_dict() if snapshot.exists else None

    def set(self, path: str, data: dict[str, Any], merge: bool = False) -> None:
        self._tx.set(self._db.document(path), data, merge=merge)

    def create(self, path: str, data: dict[str, Any]) -> None:
        self._tx.create(self._db.document(path), data)

    def delete(self, path: str) -> None:
        self._tx.delete(self._db.document(path))


class FirestoreStore(DocumentStore):
    def __init__(self, client: gfirestore.Client):
        self._db = client

    def get(self, path: str) -> dict[str, Any] | None:
        validate_doc_path(path)
        snapshot = self._db.document(path).get()
        return snapshot.to_dict() if snapshot.exists else None

    def set(self, path: str, data: dict[str, Any], merge: bool = False) -> None:
        validate_doc_path(path)
        self._db.document(path).set(data, merge=merge)

    def create(self, path: str, data: dict[str, Any]) -> None:
        validate_doc_path(path)
        try:
            self._db.document(path).create(data)
        except (gexc.AlreadyExists, gexc.Conflict) as exc:
            raise DocumentAlreadyExists(path) from exc

    def update(self, path: str, data: dict[str, Any]) -> None:
        validate_doc_path(path)
        try:
            self._db.document(path).update(data)
        except gexc.NotFound as exc:
            raise DocumentNotFound(path) from exc

    def delete(self, path: str) -> None:
        validate_doc_path(path)
        self._db.document(path).delete()

    def list(
        self,
        collection: str,
        where: Iterable[Filter] = (),
        order_by: Iterable[Order] = (),
        limit: int | None = None,
    ) -> list[Doc]:
        validate_collection_path(collection)
        where, order_by = list(where), list(order_by)
        validate_query(where, order_by)
        query: Any = self._db.collection(collection)
        for field, op, value in where:
            query = query.where(filter=FieldFilter(field, op, value))
        for field, direction in order_by:
            query = query.order_by(
                field,
                direction=gfirestore.Query.DESCENDING if direction == "desc" else gfirestore.Query.ASCENDING,
            )
        if limit:
            query = query.limit(limit)
        return [Doc(id=s.id, path=s.reference.path, data=s.to_dict()) for s in query.stream()]

    def delete_tree(self, path: str) -> None:
        segments = path.strip("/").split("/")
        ref = self._db.document(path) if len(segments) % 2 == 0 else self._db.collection(path)
        self._db.recursive_delete(ref)

    def run_transaction(self, fn: Callable[[Transaction], T]) -> T:
        @gfirestore.transactional
        def _run(transaction: gfirestore.Transaction) -> T:
            return fn(_FirestoreTransaction(self._db, transaction))

        try:
            return _run(self._db.transaction())
        except (gexc.AlreadyExists, gexc.Conflict) as exc:
            raise DocumentAlreadyExists(str(exc)) from exc
