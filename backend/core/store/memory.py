"""Firestore simulado em memória (modo mock).

Reproduz o comportamento do Firestore que o Dosis usa: caminhos de
coleção/documento, ``create`` que falha se o documento existe, consultas com
filtro/ordenação/limite e transações atômicas (leituras antes das escritas).
Com ``MOCK_STORE_PATH`` os dados são gravados em um arquivo JSON para
sobreviver a reinícios do servidor de desenvolvimento.
"""
from __future__ import annotations

import copy
import os
import threading
from pathlib import Path
from typing import Any, Callable, Iterable

from core import jsoncodec

from .base import (
    Doc,
    DocumentAlreadyExists,
    DocumentNotFound,
    DocumentStore,
    Filter,
    Order,
    StoreError,
    T,
    Transaction,
    validate_collection_path,
    validate_doc_path,
    validate_query,
)

_MISSING = object()


def _get_field(data: dict[str, Any], field: str) -> Any:
    value: Any = data
    for part in field.split("."):
        if not isinstance(value, dict) or part not in value:
            return _MISSING
        value = value[part]
    return value


def _matches(data: dict[str, Any], flt: Filter) -> bool:
    field, op, expected = flt
    value = _get_field(data, field)
    if value is _MISSING:
        return False
    try:
        if op == "==":
            return value == expected
        if op == "!=":
            return value != expected
        if op == "<":
            return value < expected
        if op == "<=":
            return value <= expected
        if op == ">":
            return value > expected
        if op == ">=":
            return value >= expected
        if op == "in":
            return value in expected
        if op == "array_contains":
            return isinstance(value, list) and expected in value
    except TypeError:
        return False
    raise ValueError(f"Operador de filtro não suportado: {op!r}")


def _deep_merge(base: dict[str, Any], incoming: dict[str, Any]) -> dict[str, Any]:
    merged = dict(base)
    for key, value in incoming.items():
        if isinstance(value, dict) and isinstance(merged.get(key), dict):
            merged[key] = _deep_merge(merged[key], value)
        else:
            merged[key] = value
    return merged


class _MemoryTransaction(Transaction):
    def __init__(self, store: MemoryStore):
        self._store = store
        self.writes: list[tuple[str, str, dict[str, Any] | None, bool]] = []

    def get(self, path: str) -> dict[str, Any] | None:
        if self.writes:
            raise StoreError("Na transação, todas as leituras devem vir antes das escritas.")
        return self._store.get(path)

    def set(self, path: str, data: dict[str, Any], merge: bool = False) -> None:
        validate_doc_path(path)
        self.writes.append(("set", path, copy.deepcopy(data), merge))

    def create(self, path: str, data: dict[str, Any]) -> None:
        validate_doc_path(path)
        self.writes.append(("create", path, copy.deepcopy(data), False))

    def delete(self, path: str) -> None:
        validate_doc_path(path)
        self.writes.append(("delete", path, None, False))


class MemoryStore(DocumentStore):
    def __init__(self, persist_path: str | os.PathLike | None = None):
        self._docs: dict[str, dict[str, Any]] = {}
        self._lock = threading.RLock()
        self._persist_path = Path(persist_path) if persist_path else None
        if self._persist_path and self._persist_path.exists():
            self._docs = jsoncodec.loads(self._persist_path.read_text(encoding="utf-8"))

    # -- leitura -----------------------------------------------------------

    def get(self, path: str) -> dict[str, Any] | None:
        validate_doc_path(path)
        with self._lock:
            data = self._docs.get(path)
            return copy.deepcopy(data) if data is not None else None

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
        with self._lock:
            docs = [
                Doc(id=path.rsplit("/", 1)[1], path=path, data=copy.deepcopy(data))
                for path, data in self._docs.items()
                if path.rsplit("/", 1)[0] == collection
            ]
        docs = [d for d in docs if all(_matches(d.data, f) for f in where)]
        # Como no Firestore: sem o campo de ordenação, o documento fica de fora.
        docs = [d for d in docs if all(_get_field(d.data, f) is not _MISSING for f, _ in order_by)]
        docs.sort(key=lambda d: d.id)
        for field, direction in reversed(order_by):
            docs.sort(key=lambda d: _get_field(d.data, field), reverse=direction == "desc")
        return docs[:limit] if limit else docs

    # -- escrita -----------------------------------------------------------

    def set(self, path: str, data: dict[str, Any], merge: bool = False) -> None:
        validate_doc_path(path)
        with self._lock:
            self._apply_set(path, data, merge)
            self._persist()

    def create(self, path: str, data: dict[str, Any]) -> None:
        validate_doc_path(path)
        with self._lock:
            if path in self._docs:
                raise DocumentAlreadyExists(path)
            self._docs[path] = copy.deepcopy(data)
            self._persist()

    def update(self, path: str, data: dict[str, Any]) -> None:
        validate_doc_path(path)
        with self._lock:
            if path not in self._docs:
                raise DocumentNotFound(path)
            self._docs[path].update(copy.deepcopy(data))
            self._persist()

    def delete(self, path: str) -> None:
        validate_doc_path(path)
        with self._lock:
            self._docs.pop(path, None)
            self._persist()

    def delete_tree(self, path: str) -> None:
        prefix = path.rstrip("/") + "/"
        with self._lock:
            for key in [k for k in self._docs if k == path or k.startswith(prefix)]:
                del self._docs[key]
            self._persist()

    def run_transaction(self, fn: Callable[[Transaction], T]) -> T:
        with self._lock:
            tx = _MemoryTransaction(self)
            result = fn(tx)
            # Valida tudo antes de aplicar qualquer escrita: atomicidade.
            created: set[str] = set()
            for op, path, _, _ in tx.writes:
                if op == "create" and (path in self._docs or path in created):
                    raise DocumentAlreadyExists(path)
                if op == "create":
                    created.add(path)
            for op, path, data, merge in tx.writes:
                if op == "delete":
                    self._docs.pop(path, None)
                else:
                    self._apply_set(path, data or {}, merge)
            self._persist()
            return result

    # -- interno -----------------------------------------------------------

    def _apply_set(self, path: str, data: dict[str, Any], merge: bool) -> None:
        data = copy.deepcopy(data)
        if merge and path in self._docs:
            data = _deep_merge(self._docs[path], data)
        self._docs[path] = data

    def _persist(self) -> None:
        if not self._persist_path:
            return
        tmp = self._persist_path.with_suffix(self._persist_path.suffix + ".tmp")
        tmp.write_text(jsoncodec.dumps(self._docs), encoding="utf-8")
        os.replace(tmp, self._persist_path)
