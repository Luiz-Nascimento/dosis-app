"""KAN-17: auditoria dos eventos de sincronização."""
import logging
from io import StringIO

import pytest
from django.core.management import call_command
from rest_framework.test import APIClient

from core.auth import get_auth_provider
from core.store import StoreError

from .sync_helpers import Device, accept_consent, batch, break_connection_on_transaction, rec, rid


@pytest.fixture
def device(client):
    accept_consent(client)
    return Device(client)


def events(client, **params):
    response = client.get("/api/v1/sync/events", params)
    assert response.status_code == 200, response.data
    return response.data["results"]


def test_full_lifecycle_is_audited(client, store, device, monkeypatch):
    payload = batch(*[rec("hydration_logs", data={"amount_ml": 100}) for _ in range(4)])
    restore = break_connection_on_transaction(monkeypatch, store, number=3)
    assert device.send(payload).status_code == 503
    restore()
    assert device.send(payload).status_code == 200

    history = events(client, batch_id=payload["batch_id"])
    assert [e["event"] for e in history] == ["sync.completed", "sync.resumed", "sync.failed", "sync.started"]
    completed, resumed, failed, started = history
    assert started["attempt"] == 1 and started["received"] == 4
    assert failed["processed"] == 2 and failed["error_code"] == "storage_unavailable"
    assert resumed["attempt"] == 2
    assert completed["duplicate"] == 2 and completed["applied"] == 2
    assert completed["duration_ms"] is not None
    assert completed["device_id"] == "pixel-7" and completed["network"] == "wifi"


def test_consent_and_key_events(client, device):
    kinds = [e["event"] for e in events(client)]
    assert kinds == ["key.created", "consent.accepted"]
    client.delete("/api/v1/sync/consent")
    assert events(client, event="consent.revoked")


def test_refusals_are_audited_with_reason(client):
    plain = batch(rec("hydration_logs", data={"amount_ml": 100}))
    client.post("/api/v1/sync/batches", plain, format="json")  # sem aceite
    accept_consent(client)
    client.post("/api/v1/sync/batches", plain, format="json")  # sem criptografia
    device = Device(client)
    device.send(batch(rec("hydration_logs", data={"amount_ml": 1}), network="cellular"))

    refused = events(client, event="sync.refused")
    assert [e["error_code"] for e in refused] == ["wifi_required", "encryption_required", "sync_consent_required"]
    assert refused[0]["network"] == "cellular" and refused[0]["batch_id"]


def test_audit_never_stores_record_content(client, device, store):
    device.send(batch(rec("symptom_logs", data={"status": "different", "symptoms": ["nausea"], "notes": "segredo"})))
    for doc in store.list("sync_audit"):
        assert "segredo" not in str(doc.data) and "nausea" not in str(doc.data)


def test_events_are_also_written_to_structured_log(client, device, caplog):
    with caplog.at_level(logging.INFO, logger="dosis.audit"):
        device.send(batch(rec("hydration_logs", data={"amount_ml": 100})))
    assert any('"event": "sync.completed"' in r.message for r in caplog.records)


def test_audit_survives_firestore_outage(client, device, store, monkeypatch, caplog):
    """Se o Firestore cai, a falha ainda fica registrada no log."""
    original_set = store.set

    def broken_set(path, data, merge=False):
        if path.startswith("sync_audit/"):
            raise StoreError("fora do ar")
        return original_set(path, data, merge=merge)

    monkeypatch.setattr(store, "set", broken_set)
    with caplog.at_level(logging.INFO, logger="dosis.audit"):
        assert device.send(batch(rec("hydration_logs", data={"amount_ml": 100}))).status_code == 200
    assert any("sync.completed" in r.message for r in caplog.records)


def test_events_are_private(client, device, make_client):
    device.send(batch(rec("hydration_logs", data={"amount_ml": 100})))
    assert events(make_client()) == []


def test_admin_monitoring_requires_claim(client, device, make_client):
    device.send(batch(rec("hydration_logs", data={"amount_ml": 100})))
    assert client.get("/api/v1/admin/sync/summary").status_code == 403

    admin = make_client()
    get_auth_provider().set_custom_claims(admin.session_data["uid"], {"admin": True})
    refreshed = APIClient().post(
        "/api/v1/auth/refresh", {"refresh_token": admin.session_data["refresh_token"]}, format="json"
    ).data
    admin.credentials(HTTP_AUTHORIZATION=f"Bearer {refreshed['id_token']}")

    summary = admin.get("/api/v1/admin/sync/summary", {"hours": 1}).data
    assert summary["by_event"]["sync.completed"] == 1
    assert summary["records"]["applied"] == 1
    assert summary["users"] == 1
    assert summary["batch_duration_ms_p50"] is not None

    all_events = admin.get("/api/v1/admin/sync/events", {"uid": client.session_data["uid"]}).data["results"]
    assert {e["uid"] for e in all_events} == {client.session_data["uid"]}


def test_set_admin_command(client):
    out = StringIO()
    call_command("set_admin", client.session_data["uid"], stdout=out)
    assert "concedido" in out.getvalue()
    token = APIClient().post(
        "/api/v1/auth/refresh", {"refresh_token": client.session_data["refresh_token"]}, format="json"
    ).data["id_token"]
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    assert client.get("/api/v1/admin/sync/summary").status_code == 200

    call_command("set_admin", client.session_data["uid"], "--revoke", stdout=out)


def test_unknown_batch_events_filter(client):
    assert events(client, batch_id=rid()) == []
    assert client.get("/api/v1/sync/events", {"event": "x"}).status_code == 400
