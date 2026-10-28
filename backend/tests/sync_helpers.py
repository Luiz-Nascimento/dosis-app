import datetime as dt
import uuid


def rid():
    return uuid.uuid4().hex


def rec(entity, record_id=None, data=None, op="upsert", at=None, mutation_id=None):
    """Um item da fila de sincronização do aparelho."""
    return {
        "mutation_id": mutation_id or rid(),
        "id": record_id or rid(),
        "entity": entity,
        "op": op,
        "client_updated_at": (at or dt.datetime.now(dt.timezone.utc)).isoformat(),
        "data": data or {},
    }


def batch(*records, network="wifi", batch_id=None):
    return {"batch_id": batch_id or rid(), "device_id": "pixel-7", "network": network, "records": list(records)}
