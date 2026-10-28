"""Grava o catálogo e os artigos no Firestore (coleções ``products`` e ``articles``)."""
from __future__ import annotations

import copy
from typing import Any

from core.store import DocumentStore

from .content import ARTICLES, PRODUCTS, SOURCES


def _resolve_sources(source_ids: list[str]) -> list[dict[str, Any]]:
    return [{"id": sid, **SOURCES[sid]} for sid in source_ids]


def product_documents() -> list[tuple[str, dict[str, Any]]]:
    docs = []
    for product in copy.deepcopy(PRODUCTS):
        product_id = product.pop("id")
        product["sources"] = _resolve_sources(product.pop("source_ids"))
        for dose_range in product["dose_ranges"]:
            dose_range["sources"] = _resolve_sources(dose_range.pop("source_ids"))
        product["search_name"] = product["name"].lower()
        docs.append((product_id, product))
    return docs


def article_documents() -> list[tuple[str, dict[str, Any]]]:
    docs = []
    for article in copy.deepcopy(ARTICLES):
        article_id = article.pop("id")
        article["sources"] = _resolve_sources(article.pop("source_ids"))
        docs.append((article_id, article))
    return docs


def seed_content(store: DocumentStore, overwrite: bool = False) -> int:
    """Grava o conteúdo padrão. Sem ``overwrite``, não mexe no que já existe."""
    written = 0
    for collection, docs in (("products", product_documents()), ("articles", article_documents())):
        for doc_id, data in docs:
            path = f"{collection}/{doc_id}"
            if overwrite or store.get(path) is None:
                store.set(path, data)
                written += 1
    return written
