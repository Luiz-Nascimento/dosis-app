"""Aplicação de um lote de sincronização."""
from __future__ import annotations

from typing import Any

from .handlers import HANDLERS, SyncRejected


def process_batch(uid: str, batch: dict[str, Any]) -> dict[str, Any]:
    """Aplica os registros na ordem recebida e devolve o resultado de cada um.

    Um registro recusado (dados inválidos) não impede os demais. Uma falha de
    infraestrutura (Firestore fora do ar) interrompe o lote com erro 503, e o
    app reenvia o lote inteiro depois.
    """
    results = []
    for record in batch["records"]:
        handler = HANDLERS[record["entity"]]
        result = {"id": record["id"], "entity": record["entity"], "op": record["op"], "status": "applied", "error": None}
        try:
            if record["op"] == "delete":
                handler.delete(uid, record["id"])
            else:
                handler.upsert(uid, record["id"], record["data"])
        except SyncRejected as exc:
            result.update(status="rejected", error=exc.as_dict())
        results.append(result)

    applied = sum(1 for r in results if r["status"] == "applied")
    return {
        "batch_id": batch["batch_id"],
        "received": len(results),
        "applied": applied,
        "rejected": len(results) - applied,
        "results": results,
    }
