"""Auditoria dos eventos de sincronização.

Cada evento vai para dois lugares:

* log estruturado ``dosis.audit`` (uma linha JSON): sempre funciona, inclusive
  quando o Firestore está fora do ar, que é justamente quando a falha
  precisa ficar registrada;
* coleção ``sync_audit`` no Firestore, para consulta e monitoramento. A
  gravação é "melhor esforço": se falhar, o sync não é afetado.

Os eventos nunca guardam o conteúdo dos registros, só metadados (ids,
contagens, códigos de erro).
"""
from __future__ import annotations

import datetime as dt
import json
import logging
from collections import Counter
from typing import Any

from django.conf import settings

from apps.core.fields import utcnow
from apps.core.store import StoreError, get_store, new_id

logger = logging.getLogger("dosis.audit")

COLLECTION = "sync_audit"

STARTED = "sync.started"
RESUMED = "sync.resumed"
COMPLETED = "sync.completed"
FAILED = "sync.failed"
REFUSED = "sync.refused"
CONSENT_ACCEPTED = "consent.accepted"
CONSENT_REVOKED = "consent.revoked"
KEY_CREATED = "key.created"

EVENT_CHOICES = [
    (STARTED, "Lote recebido (primeira tentativa)"),
    (RESUMED, "Lote reenviado (retomada)"),
    (COMPLETED, "Lote processado"),
    (FAILED, "Falha no meio do lote"),
    (REFUSED, "Lote recusado antes de processar"),
    (CONSENT_ACCEPTED, "Aviso de sincronização aceito"),
    (CONSENT_REVOKED, "Sincronização desativada"),
    (KEY_CREATED, "Chave de criptografia combinada"),
]


def record(uid: str, event: str, **fields: Any) -> dict[str, Any]:
    now = utcnow()
    data = {
        "uid": uid,
        "event": event,
        **{k: v for k, v in fields.items() if v is not None},
        "created_at": now,
        "expires_at": now + dt.timedelta(days=settings.SYNC_AUDIT_RETENTION_DAYS),
    }
    logger.info(json.dumps({**data, "created_at": now.isoformat(), "expires_at": None}, default=str))
    try:
        get_store().set(f"{COLLECTION}/{new_id()}", data)
    except StoreError:
        logger.warning("Evento de auditoria só ficou no log (Firestore indisponível): %s", event)
    return data


def list_events(
    uid: str | None = None,
    event: str | None = None,
    batch_id: str | None = None,
    since: dt.datetime | None = None,
    limit: int = 100,
) -> list[dict[str, Any]]:
    where = []
    if uid:
        where.append(("uid", "==", uid))
    if event:
        where.append(("event", "==", event))
    if batch_id:
        where.append(("batch_id", "==", batch_id))
    if since:
        where.append(("created_at", ">=", since))
    docs = get_store().list(COLLECTION, where=where, order_by=[("created_at", "desc")], limit=limit)
    return [{"id": d.id, **d.data} for d in docs]


def summary(hours: int, limit: int = 5000) -> dict[str, Any]:
    """Panorama para monitoramento: o que aconteceu nas últimas ``hours`` horas."""
    since = utcnow() - dt.timedelta(hours=hours)
    events = list_events(since=since, limit=limit)
    by_event = Counter(e["event"] for e in events)
    failures = Counter(e.get("error_code", "unknown") for e in events if e["event"] in (FAILED, REFUSED))
    completed = [e for e in events if e["event"] == COMPLETED]
    records = {k: sum(e.get(k, 0) for e in completed) for k in ("applied", "duplicate", "stale", "rejected")}
    durations = sorted(e["duration_ms"] for e in completed if "duration_ms" in e)
    return {
        "since": since,
        "events": len(events),
        "truncated": len(events) >= limit,
        "users": len({e["uid"] for e in events}),
        "by_event": dict(by_event),
        "failures_by_code": dict(failures),
        "records": records,
        "batch_duration_ms_p50": durations[len(durations) // 2] if durations else None,
        "batch_duration_ms_max": durations[-1] if durations else None,
    }
