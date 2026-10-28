"""Aparelho offline: registra tudo sem internet e sincroniza no Wi-Fi, com queda no meio."""
from rest_framework.test import APIClient

from apps.core.crypto import is_encrypted
from tests.unit.apps.sync.helpers import Device, accept_consent, batch, break_connection_on_transaction, rec, rid


def test_offline_day_synced_with_connection_drop(client, store, monkeypatch, make_client, auth_provider):
    uid = client.session_data["uid"]
    accept_consent(client)
    device = Device(client)

    item_id = rid()
    records = [
        rec("profile", uid, {"weight_kg": 76, "goal": "hypertrophy"}),
        rec("routine_items", item_id, {"product_id": "creatina"}),
        *[rec("dose_logs", data={"routine_item_id": item_id, "taken_at": f"2026-09-{day}T08:00:00-03:00"})
          for day in range(10, 20)],
        rec("symptom_logs", data={"status": "different", "symptoms": ["acne"]}),
        rec("hydration_logs", data={"amount_ml": 750}),
    ]
    payload = batch(*records)

    # A conexão cai na 8ª gravação: 7 entram, o resto fica pendente.
    restore = break_connection_on_transaction(monkeypatch, store, number=8)
    assert device.send(payload).status_code == 503
    status = client.get(f"/api/v1/sync/batches/{payload['batch_id']}/").data
    assert status["status"] == "interrupted"
    assert [m["mutation_id"] for m in status["mutations"]] == [r["mutation_id"] for r in records[:7]]

    restore()
    resumed = device.send(payload).data
    assert (resumed["duplicate"], resumed["applied"]) == (7, len(records) - 7)

    # Cada app recebeu seus dados, e os sensíveis estão cifrados no Firestore.
    assert client.get("/api/v1/profile/").data["goal"] == "hypertrophy"
    doses = client.get("/api/v1/tracking/doses/", {"routine_item_id": item_id}).data["results"]
    assert len(doses) == 10 and {d["name"] for d in doses} == {"Creatina monohidratada"}
    assert all(is_encrypted(d.data["amount"]) for d in store.list(f"users/{uid}/dose_logs"))
    assert client.get("/api/v1/tracking/symptoms/").data["results"][0]["symptoms"] == ["acne"]
    assert client.get("/api/v1/tracking/hydration/").data["results"][0]["amount_ml"] == 750

    # Auditoria do lote
    history = client.get("/api/v1/sync/events/", {"batch_id": payload["batch_id"]}).data["results"]
    assert [e["event"] for e in history] == ["sync.completed", "sync.resumed", "sync.failed", "sync.started"]

    # Monitoramento pela equipe (custom claim admin)
    admin = make_client()
    auth_provider.set_custom_claims(admin.session_data["uid"], {"admin": True})
    refreshed = APIClient().post(
        "/api/v1/auth/refresh/", {"refresh_token": admin.session_data["refresh_token"]}, format="json"
    ).data
    admin.credentials(HTTP_AUTHORIZATION=f"Bearer {refreshed['id_token']}")
    summary = admin.get("/api/v1/sync/admin/summary/", {"hours": 1}).data
    assert summary["by_event"]["sync.failed"] == 1
    assert summary["failures_by_code"]["storage_unavailable"] == 1
    assert summary["records"]["applied"] == len(records) - 7
