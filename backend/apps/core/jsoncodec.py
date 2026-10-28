"""JSON que preserva datetime e bytes (marcados como ``{"$dt": ...}`` e ``{"$b64": ...}``)."""
from __future__ import annotations

import base64
import json
from datetime import datetime
from typing import Any


def encode(value: Any) -> Any:
    if isinstance(value, datetime):
        return {"$dt": value.isoformat()}
    if isinstance(value, bytes):
        return {"$b64": base64.b64encode(value).decode("ascii")}
    if isinstance(value, dict):
        return {k: encode(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [encode(v) for v in value]
    return value


def decode(value: Any) -> Any:
    if isinstance(value, dict):
        if set(value) == {"$dt"}:
            return datetime.fromisoformat(value["$dt"])
        if set(value) == {"$b64"}:
            return base64.b64decode(value["$b64"])
        return {k: decode(v) for k, v in value.items()}
    if isinstance(value, list):
        return [decode(v) for v in value]
    return value


def dumps(value: Any) -> str:
    return json.dumps(encode(value), ensure_ascii=False, separators=(",", ":"))


def loads(text: str | bytes) -> Any:
    return decode(json.loads(text))
