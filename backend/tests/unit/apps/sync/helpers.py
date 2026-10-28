import datetime as dt
import gzip
import json
import os
import uuid

import pytest
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey, X25519PublicKey
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from apps.core.crypto import b64decode, b64encode
from apps.core.store import StoreError
from apps.sync.security import derive_key, envelope_aad


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


def accept_consent(client):
    version = client.get("/api/v1/sync/consent/").data["notice"]["version"]
    response = client.post("/api/v1/sync/consent/", {"notice_version": version}, format="json")
    assert response.status_code == 200, response.data


class Device:
    """Faz o papel do app: combina a chave com o servidor e monta envelopes."""

    def __init__(self, client):
        self.client = client
        self.uid = client.session_data["uid"]
        private = X25519PrivateKey.generate()
        response = client.post("/api/v1/sync/keys/", {
            "device_id": "pixel-7",
            "client_public_key": b64encode(private.public_key().public_bytes_raw()),
        }, format="json")
        assert response.status_code == 201, response.data
        self.key_id = response.data["key_id"]
        server_public = X25519PublicKey.from_public_bytes(b64decode(response.data["server_public_key"]))
        self.key = derive_key(private.exchange(server_public), self.key_id)

    def envelope(self, payload, compression="gzip", nonce=None):
        raw = json.dumps(payload).encode()
        if compression == "gzip":
            raw = gzip.compress(raw)
        nonce = nonce or os.urandom(12)
        ciphertext = AESGCM(self.key).encrypt(nonce, raw, envelope_aad(self.uid, self.key_id))
        return {
            "key_id": self.key_id,
            "algorithm": "A256GCM",
            "compression": compression,
            "nonce": b64encode(nonce),
            "payload": b64encode(ciphertext),
        }

    def send(self, payload, **kwargs):
        return self.client.post("/api/v1/sync/batches/", self.envelope(payload, **kwargs), format="json")


def break_connection_on_transaction(monkeypatch, store, number):
    """Derruba a conexão na N-ésima transação, depois de montar as escritas e antes do commit."""
    original = store.run_transaction
    calls = {"n": 0}

    def flaky(fn):
        calls["n"] += 1
        if calls["n"] != number:
            return original(fn)

        def fail_before_commit(tx):
            fn(tx)
            raise StoreError("conexão perdida")

        return original(fail_before_commit)

    monkeypatch.setattr(store, "run_transaction", flaky)
    return lambda: monkeypatch.setattr(store, "run_transaction", original)


# Fixtures para os testes da fila e da transação: lote em texto puro (o
# envelope cifrado tem testes próprios) e aviso de sincronização aceito.

@pytest.fixture
def plaintext_sync(settings):
    settings.SYNC_REQUIRE_ENCRYPTION = False


@pytest.fixture
def make_client(make_client):
    def _make():
        client = make_client()
        accept_consent(client)
        return client

    return _make
