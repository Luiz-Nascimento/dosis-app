import pytest

from .sync_helpers import batch, rec, rid, make_client, plaintext_sync  # noqa: F401

pytestmark = pytest.mark.usefixtures("plaintext_sync")


def test_policy(client):
    policy = client.get("/api/v1/sync/policy").data
    assert policy["wifi_only"] is True
    assert policy["allowed_networks"] == ["wifi", "ethernet"]
    assert policy["max_batch_size"] == 50
    assert policy["entities"][:3] == ["profile", "routine_items", "dose_logs"]


def test_batch_applies_offline_records(client):
    item_id, dose_id, symptom_id, water_id = rid(), rid(), rid(), rid()
    uid = client.session_data["uid"]
    response = client.post("/api/v1/sync/batches", batch(
        rec("profile", uid, {"weight_kg": 76, "height_cm": 178}),
        rec("routine_items", item_id, {"product_id": "creatina"}),
        rec("dose_logs", dose_id, {"routine_item_id": item_id, "taken_at": "2026-09-20T08:00:00-03:00"}),
        rec("symptom_logs", symptom_id, {"status": "normal"}),
        rec("hydration_logs", water_id, {"amount_ml": 500}),
    ), format="json")
    assert response.status_code == 200, response.data
    assert response.data["received"] == 5 and response.data["applied"] == 5
    assert all(r["status"] == "applied" for r in response.data["results"])

    assert client.get("/api/v1/profile").data["weight_kg"] == 76
    assert client.get(f"/api/v1/doses/{dose_id}").data["name"] == "Creatina monohidratada"
    assert client.get(f"/api/v1/symptoms/{symptom_id}").status_code == 200
    assert client.get(f"/api/v1/hydration/{water_id}").data["amount_ml"] == 500


def test_upsert_updates_and_delete_removes(client):
    item_id = rid()
    client.post("/api/v1/sync/batches", batch(rec("routine_items", item_id, {"product_id": "creatina"})), format="json")
    response = client.post("/api/v1/sync/batches", batch(rec("routine_items", item_id, {"dose_amount": 5})), format="json")
    assert response.data["applied"] == 1
    assert client.get(f"/api/v1/routine-items/{item_id}").data["dose_amount"] == 5

    deleted = client.post("/api/v1/sync/batches", batch(
        rec("routine_items", item_id, op="delete"),
        rec("routine_items", op="delete"),
    ), format="json")
    assert deleted.data["applied"] == 2  # apagar o que não existe também é sucesso
    assert client.get(f"/api/v1/routine-items/{item_id}").status_code == 404


def test_invalid_record_is_rejected_without_blocking_others(client):
    bad = rec("symptom_logs", data={"status": "different"})
    good = rec("hydration_logs", data={"amount_ml": 250})
    response = client.post("/api/v1/sync/batches", batch(bad, good), format="json")
    results = {r["id"]: r for r in response.data["results"]}
    assert results[bad["id"]]["status"] == "rejected"
    assert results[bad["id"]]["error"]["code"] == "validation_error"
    assert "symptoms" in results[bad["id"]]["error"]["details"]
    assert results[good["id"]]["status"] == "applied" and results[good["id"]]["error"] is None
    assert response.data["rejected"] == 1


def test_profile_rules_in_sync(client):
    response = client.post("/api/v1/sync/batches", batch(
        rec("profile", rid(), {"age": 30}),
        rec("profile", client.session_data["uid"], op="delete"),
    ), format="json")
    codes = [r["error"]["code"] for r in response.data["results"]]
    assert codes == ["invalid_record", "invalid_operation"]


def test_sync_only_on_wifi(client):
    record = rec("hydration_logs", data={"amount_ml": 200})
    response = client.post("/api/v1/sync/batches", batch(record, network="cellular"), format="json")
    assert response.status_code == 412
    assert response.data["error"]["code"] == "wifi_required"
    assert client.get("/api/v1/hydration").data["results"] == []

    assert client.post("/api/v1/sync/batches", batch(record, network="ethernet"), format="json").status_code == 200


def test_wifi_rule_can_be_disabled(client, settings):
    settings.SYNC_WIFI_ONLY = False
    record = rec("hydration_logs", data={"amount_ml": 200})
    assert client.post("/api/v1/sync/batches", batch(record, network="cellular"), format="json").status_code == 200


def test_batch_validation(client, settings):
    settings.SYNC_MAX_BATCH_SIZE = 2
    records = [rec("hydration_logs", data={"amount_ml": 100}) for _ in range(3)]
    response = client.post("/api/v1/sync/batches", batch(*records), format="json")
    assert response.status_code == 400
    assert "records" in response.data["error"]["details"]

    assert client.post("/api/v1/sync/batches", batch(), format="json").status_code == 400
    assert client.post("/api/v1/sync/batches", batch(rec("pedidos")), format="json").status_code == 400

    same = rec("hydration_logs", data={"amount_ml": 100})
    repeated = client.post("/api/v1/sync/batches", batch(same, dict(same)), format="json")
    assert repeated.status_code == 400


def test_sync_is_isolated_per_user(make_client):
    alice, bob = make_client(), make_client()
    item_id = rid()
    alice.post("/api/v1/sync/batches", batch(rec("routine_items", item_id, {"product_id": "creatina"})), format="json")
    bob.post("/api/v1/sync/batches", batch(rec("routine_items", item_id, {"product_id": "whey-protein"})), format="json")
    assert alice.get(f"/api/v1/routine-items/{item_id}").data["product_id"] == "creatina"
    assert bob.get(f"/api/v1/routine-items/{item_id}").data["product_id"] == "whey-protein"
