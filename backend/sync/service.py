"""Aplicação transacional de um lote de sincronização.

Garantias:

* **Sem duplicação:** cada mudança feita no aparelho tem um ``mutation_id``.
  O documento e o recibo da mutação (``users/{uid}/sync_mutations``) são
  gravados na mesma transação. Reenviar a mutação devolve ``duplicate`` sem
  gravar de novo.
* **Sem perda:** se a conexão cair no meio do lote, o que foi aplicado tem
  recibo e o resto não foi gravado. ``GET /sync/batches/{id}`` mostra
  exatamente o que entrou, e o app pode reenviar o lote inteiro com segurança.
* **Fora de ordem:** vale a mudança mais recente (``client_updated_at``). Uma
  mudança mais antiga que a versão do servidor vira ``stale`` e não sobrescreve
  nada. Exclusões deixam uma lápide para uma mudança antiga não recriar o
  registro.
"""
from __future__ import annotations

import datetime as dt
from collections import Counter
from typing import Any

from core.fields import utcnow
from core.store import DocumentStore, StoreError, get_store, user_collection, user_doc

from .handlers import HANDLERS, PreparedWrite, SyncRejected

APPLIED, DUPLICATE, STALE, REJECTED = "applied", "duplicate", "stale", "rejected"
STATUSES = (APPLIED, DUPLICATE, STALE, REJECTED)
# Recibos e lápides podem ser apagados depois disso (política de TTL do Firestore).
RETENTION = dt.timedelta(days=30)


def process_batch(uid: str, batch: dict[str, Any]) -> dict[str, Any]:
    store = get_store()
    batch_path = user_doc(uid, "sync_batches", batch["batch_id"])
    previous = store.get(batch_path)
    attempt = (previous or {}).get("attempts", 0) + 1
    store.set(batch_path, {
        "device_id": batch["device_id"],
        "network": batch["network"],
        "status": "processing",
        "attempts": attempt,
        "received": len(batch["records"]),
        "started_at": utcnow(),
        "finished_at": None,
        "error": None,
    }, merge=True)

    results: list[dict[str, Any]] = []
    try:
        for record in batch["records"]:
            results.append(apply_record(store, uid, batch["batch_id"], record))
    except StoreError as exc:
        _try_set(store, batch_path, {"status": "interrupted", "processed": len(results), "error": str(exc)})
        raise

    counts = Counter(r["status"] for r in results)
    summary = {status: counts.get(status, 0) for status in STATUSES}
    store.set(batch_path, {"status": "completed", "processed": len(results), "finished_at": utcnow(), **summary}, merge=True)
    return {"batch_id": batch["batch_id"], "attempt": attempt, "received": len(results), **summary, "results": results}


def apply_record(store: DocumentStore, uid: str, batch_id: str, record: dict[str, Any]) -> dict[str, Any]:
    result = {
        "mutation_id": record["mutation_id"],
        "id": record["id"],
        "entity": record["entity"],
        "op": record["op"],
        "status": APPLIED,
        "error": None,
    }
    receipt_path = user_doc(uid, "sync_mutations", record["mutation_id"])
    # Já processada antes (ex.: resposta perdida na queda): nem valida de novo.
    if store.get(receipt_path) is not None:
        result["status"] = DUPLICATE
        return result

    # Relógio do aparelho adiantado não pode "ganhar" de mudanças futuras.
    modified_at = min(record["client_updated_at"], utcnow())
    try:
        prepared = HANDLERS[record["entity"]].prepare(uid, record, modified_at)
    except SyncRejected as exc:
        # Recusa não gera recibo: o app pode corrigir e reenviar a mesma mutação.
        result.update(status=REJECTED, error=exc.as_dict())
        return result

    def work(tx):
        if tx.get(receipt_path) is not None:
            return DUPLICATE
        current = tx.get(prepared.path)
        tombstone = tx.get(prepared.tombstone_path) if prepared.tombstone_path else None
        status = STALE if _is_stale(modified_at, current, tombstone) else APPLIED
        if status == APPLIED:
            _write(tx, prepared, current, tombstone, record, modified_at)
        now = utcnow()
        tx.create(receipt_path, {
            "batch_id": batch_id,
            "entity": record["entity"],
            "record_id": record["id"],
            "op": record["op"],
            "status": status,
            "client_updated_at": modified_at,
            "processed_at": now,
            "expires_at": now + RETENTION,
        })
        return status

    result["status"] = store.run_transaction(work)
    return result


def get_batch(uid: str, batch_id: str) -> dict[str, Any] | None:
    store = get_store()
    batch = store.get(user_doc(uid, "sync_batches", batch_id))
    if batch is None:
        return None
    receipts = store.list(
        user_collection(uid, "sync_mutations"),
        where=[("batch_id", "==", batch_id)],
        order_by=[("processed_at", "asc")],
    )
    return {
        "batch_id": batch_id,
        **{k: batch.get(k) for k in ("status", "attempts", "received", "processed", "started_at", "finished_at")},
        "mutations": [
            {
                "mutation_id": doc.id,
                "id": doc.data["record_id"],
                "entity": doc.data["entity"],
                "op": doc.data["op"],
                "status": doc.data["status"],
                "processed_at": doc.data["processed_at"],
            }
            for doc in receipts
        ],
    }


def _is_stale(modified_at: dt.datetime, current: dict | None, tombstone: dict | None) -> bool:
    versions = [doc["modified_at"] for doc in (current, tombstone) if doc and doc.get("modified_at")]
    return bool(versions) and max(versions) > modified_at


def _write(tx, prepared: PreparedWrite, current, tombstone, record, modified_at) -> None:
    if prepared.op == "delete":
        if current is not None:
            tx.delete(prepared.path)
        tx.set(prepared.tombstone_path, {
            "entity": record["entity"],
            "record_id": record["id"],
            "modified_at": modified_at,
            "expires_at": utcnow() + RETENTION,
        })
        return
    if current is None:
        tx.set(prepared.path, prepared.create_payload)
    else:
        tx.set(prepared.path, prepared.update_payload, merge=True)
    if tombstone is not None:
        tx.delete(prepared.tombstone_path)


def _try_set(store: DocumentStore, path: str, data: dict[str, Any]) -> None:
    try:
        store.set(path, data, merge=True)
    except StoreError:
        pass  # O Firestore pode continuar fora; o lote fica como "processing".
