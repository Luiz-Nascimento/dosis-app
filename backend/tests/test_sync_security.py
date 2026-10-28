"""KAN-16: lotes comprimidos e criptografados, com aviso explícito antes."""
import gzip
import json
import os

import pytest
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from core.crypto import b64encode, is_encrypted
from sync.security import envelope_aad

from .sync_helpers import Device, accept_consent, batch, rec


@pytest.fixture
def device(client):
    accept_consent(client)
    return Device(client)


def test_policy_announces_encryption_and_consent(client):
    policy = client.get("/api/v1/sync/policy").data
    assert policy["encryption_required"] is True
    assert policy["encryption"] == "A256GCM"
    assert policy["key_agreement"] == "X25519-HKDF-SHA256"
    assert policy["compression"] == "gzip"
    assert policy["consent_version"] == client.get("/api/v1/sync/consent").data["notice"]["version"]


# -- Aviso explícito -------------------------------------------------------------


def test_sync_requires_explicit_consent(client):
    consent = client.get("/api/v1/sync/consent").data
    assert consent["accepted"] is False
    assert "criptografados" in consent["notice"]["text"]

    device = Device(client)
    blocked = device.send(batch(rec("hydration_logs", data={"amount_ml": 200})))
    assert blocked.status_code == 428
    assert blocked.data["error"]["code"] == "sync_consent_required"

    accept_consent(client)
    assert client.get("/api/v1/sync/consent").data["accepted"] is True
    assert device.send(batch(rec("hydration_logs", data={"amount_ml": 200}))).status_code == 200

    assert client.delete("/api/v1/sync/consent").status_code == 204
    assert device.send(batch(rec("hydration_logs", data={"amount_ml": 200}))).status_code == 428


def test_consent_must_match_current_notice(client):
    response = client.post("/api/v1/sync/consent", {"notice_version": "2020-01-01"}, format="json")
    assert response.status_code == 400
    assert "notice_version" in response.data["error"]["details"]


# -- Criptografia e compressão ----------------------------------------------------


def test_encrypted_compressed_batch_is_applied(client, device):
    water = rec("hydration_logs", data={"amount_ml": 750})
    response = device.send(batch(water))
    assert response.status_code == 200, response.data
    assert response.data["applied"] == 1
    assert client.get(f"/api/v1/hydration/{water['id']}").data["amount_ml"] == 750


def test_uncompressed_envelope_is_accepted(device):
    response = device.send(batch(rec("hydration_logs", data={"amount_ml": 100})), compression="none")
    assert response.status_code == 200


def test_plaintext_batch_is_refused(client):
    accept_consent(client)
    response = client.post("/api/v1/sync/batches", batch(rec("hydration_logs", data={"amount_ml": 1})), format="json")
    assert response.status_code == 400
    assert response.data["error"]["code"] == "encryption_required"
    assert client.get("/api/v1/hydration").data["results"] == []


def test_tampered_payload_is_refused(client, device):
    envelope = device.envelope(batch(rec("hydration_logs", data={"amount_ml": 100})))
    payload = bytearray(envelope["payload"].encode())
    payload[10] = ord("A") if payload[10] != ord("A") else ord("B")
    envelope["payload"] = payload.decode()
    response = client.post("/api/v1/sync/batches", envelope, format="json")
    assert response.status_code == 400
    assert response.data["error"]["code"] == "decryption_failed"


def test_key_of_another_user_does_not_work(make_client, device):
    other = make_client()
    accept_consent(other)
    envelope = device.envelope(batch(rec("hydration_logs", data={"amount_ml": 100})))
    response = other.post("/api/v1/sync/batches", envelope, format="json")
    assert response.data["error"]["code"] == "unknown_sync_key"


def test_invalid_client_public_key(client):
    response = client.post("/api/v1/sync/keys", {"device_id": "x", "client_public_key": b64encode(b"curta")}, format="json")
    assert response.status_code == 400
    assert response.data["error"]["code"] == "invalid_envelope"


def test_sync_key_is_stored_encrypted(client, device, store):
    stored = store.get(f"users/{client.session_data['uid']}/sync_keys/{device.key_id}")
    assert is_encrypted(stored["key"])
    assert stored["device_id"] == "pixel-7"


def test_zip_bomb_is_refused(client, device, settings):
    settings.SYNC_MAX_PAYLOAD_BYTES = 10_000
    bomb = gzip.compress(b"{" + b" " * 1_000_000 + b"}")
    assert len(bomb) < 10_000
    nonce = os.urandom(12)
    ciphertext = AESGCM(device.key).encrypt(nonce, bomb, envelope_aad(device.uid, device.key_id))
    envelope = {**device.envelope({}), "nonce": b64encode(nonce), "payload": b64encode(ciphertext)}
    response = client.post("/api/v1/sync/batches", envelope, format="json")
    assert response.status_code == 413
    assert response.data["error"]["code"] == "payload_too_large"


def test_decrypted_content_must_be_a_batch(client, device):
    response = device.send(["não é um lote"])
    assert response.status_code == 400
    assert json.dumps(response.data)  # erro no formato padrão
