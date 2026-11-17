"""Ponto de entrada do container: prepara as chaves, popula o Firestore e sobe o gunicorn.

Em Python (e não em shell) para não quebrar quando o Git do Windows converte
as quebras de linha para CRLF.
"""
from __future__ import annotations

import base64
import json
import os
import secrets
import subprocess
import sys
from pathlib import Path

KEYS_FILE = Path(os.environ.get("DOSIS_KEYS_FILE", "/data/keys.json"))


def stored_keys() -> dict[str, str]:
    """Chaves criadas no primeiro start e guardadas no volume, para valerem entre reinícios."""
    if KEYS_FILE.exists():
        return json.loads(KEYS_FILE.read_text())
    keys = {
        "DJANGO_SECRET_KEY": secrets.token_urlsafe(50),
        "FIELD_ENCRYPTION_KEY": base64.urlsafe_b64encode(os.urandom(32)).decode(),
    }
    KEYS_FILE.parent.mkdir(parents=True, exist_ok=True)
    KEYS_FILE.write_text(json.dumps(keys))
    KEYS_FILE.chmod(0o600)
    return keys


def main() -> None:
    # O que vier do .env tem prioridade sobre as chaves do volume.
    for name, value in stored_keys().items():
        if not os.environ.get(name):
            os.environ[name] = value
            print(f"[dosis] {name} gerada no volume ({KEYS_FILE})", flush=True)

    mode = os.environ.get("FIREBASE_MODE", "mock")
    if mode == "firebase":
        # O mock já nasce com o catálogo; no Firestore real ele é gravado aqui
        # sem sobrescrever o que já existe.
        subprocess.run([sys.executable, "manage.py", "seed_content"], check=True)

    # O mock vive na memória do processo: com mais de um worker cada um teria
    # os próprios dados. Threads compartilham o mesmo store.
    workers = os.environ.get("GUNICORN_WORKERS") or ("1" if mode == "mock" else "2")
    os.execvp("gunicorn", [
        "gunicorn", "config.wsgi:application",
        "--bind", "0.0.0.0:8000",
        "--workers", workers,
        "--threads", "8",
        "--timeout", "60",
        "--access-logfile", "-",
    ])


if __name__ == "__main__":
    main()
