"""Contrato de acesso a documentos no estilo do Firestore.

Todo dado do Dosis fica no Firestore. As views nunca falam direto com o SDK:
usam um ``DocumentStore``, que tem duas implementações:

* ``FirestoreStore``: Firestore real (ou emulador), via firebase-admin.
* ``MemoryStore``: mock em memória, usado em desenvolvimento e nos testes
  enquanto o projeto Firebase real não está configurado.

Os caminhos seguem o formato do Firestore: coleções têm número ímpar de
segmentos (``users/abc/doses``) e documentos, número par (``users/abc/doses/x``).
"""
from __future__ import annotations

import uuid
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any, Callable, Iterable, TypeVar

T = TypeVar("T")

FILTER_OPERATORS = frozenset({"==", "!=", "<", "<=", ">", ">=", "in", "array_contains"})


class StoreError(Exception):
    """Erro genérico do armazenamento."""


class DocumentAlreadyExists(StoreError):
    pass


class DocumentNotFound(StoreError):
    pass


@dataclass(frozen=True)
class Doc:
    id: str
    path: str
    data: dict[str, Any]


Filter = tuple[str, str, Any]
Order = tuple[str, str]


def doc_path(*segments: str) -> str:
    path = "/".join(segments)
    validate_doc_path(path)
    return path


def collection_path(*segments: str) -> str:
    path = "/".join(segments)
    validate_collection_path(path)
    return path


def validate_doc_path(path: str) -> None:
    parts = path.split("/")
    if len(parts) % 2 != 0 or any(not p for p in parts):
        raise ValueError(f"Caminho de documento inválido: {path!r}")


def validate_collection_path(path: str) -> None:
    parts = path.split("/")
    if len(parts) % 2 != 1 or any(not p for p in parts):
        raise ValueError(f"Caminho de coleção inválido: {path!r}")


def validate_query(where: Iterable[Filter], order_by: Iterable[Order]) -> None:
    for _, op, _ in where:
        if op not in FILTER_OPERATORS:
            raise ValueError(f"Operador de filtro não suportado: {op!r}")
    for _, direction in order_by:
        if direction not in ("asc", "desc"):
            raise ValueError(f"Direção de ordenação inválida: {direction!r}")


def new_id() -> str:
    """ID aleatório para documentos criados pelo servidor."""
    return uuid.uuid4().hex


class Transaction(ABC):
    """Operações dentro de uma transação. Como no Firestore, faça todas as
    leituras antes da primeira escrita."""

    @abstractmethod
    def get(self, path: str) -> dict[str, Any] | None: ...

    @abstractmethod
    def set(self, path: str, data: dict[str, Any], merge: bool = False) -> None: ...

    @abstractmethod
    def create(self, path: str, data: dict[str, Any]) -> None: ...

    @abstractmethod
    def delete(self, path: str) -> None: ...


class DocumentStore(ABC):
    @abstractmethod
    def get(self, path: str) -> dict[str, Any] | None:
        """Lê um documento. Retorna ``None`` se ele não existir."""

    @abstractmethod
    def set(self, path: str, data: dict[str, Any], merge: bool = False) -> None:
        """Cria ou sobrescreve um documento (``merge=True`` mescla os campos)."""

    @abstractmethod
    def create(self, path: str, data: dict[str, Any]) -> None:
        """Cria um documento. Lança ``DocumentAlreadyExists`` se já existir."""

    @abstractmethod
    def update(self, path: str, data: dict[str, Any]) -> None:
        """Atualiza campos de um documento. Lança ``DocumentNotFound`` se não existir."""

    @abstractmethod
    def delete(self, path: str) -> None:
        """Apaga um documento (não apaga subcoleções)."""

    @abstractmethod
    def list(
        self,
        collection: str,
        where: Iterable[Filter] = (),
        order_by: Iterable[Order] = (),
        limit: int | None = None,
    ) -> list[Doc]:
        """Consulta uma coleção com filtros, ordenação e limite."""

    @abstractmethod
    def delete_tree(self, path: str) -> None:
        """Apaga um documento ou coleção e todas as subcoleções abaixo dele."""

    @abstractmethod
    def run_transaction(self, fn: Callable[[Transaction], T]) -> T:
        """Executa ``fn`` de forma atômica: ou todas as escritas valem, ou nenhuma."""
