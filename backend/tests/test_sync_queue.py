import uuid


def rid():
    return uuid.uuid4().hex


def batch(*records, network="wifi"):
    return {"batch_id": rid(), "device_id": "pixel-7", "network": network, "records": list(records)}


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
        {"id": uid, "entity": "profile", "data": {"weight_kg": 76, "height_cm": 178}},
        {"id": item_id, "entity": "routine_items", "data": {"product_id": "creatina"}},
        {"id": dose_id, "entity": "dose_logs", "data": {"routine_item_id": item_id, "taken_at": "2026-09-20T08:00:00-03:00"}},
        {"id": symptom_id, "entity": "symptom_logs", "data": {"status": "normal"}},
        {"id": water_id, "entity": "hydration_logs", "data": {"amount_ml": 500}},
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
    client.post("/api/v1/sync/batches", batch(
        {"id": item_id, "entity": "routine_items", "data": {"product_id": "creatina"}},
    ), format="json")
    response = client.post("/api/v1/sync/batches", batch(
        {"id": item_id, "entity": "routine_items", "data": {"dose_amount": 5}},
    ), format="json")
    assert response.data["applied"] == 1
    assert client.get(f"/api/v1/routine-items/{item_id}").data["dose_amount"] == 5

    deleted = client.post("/api/v1/sync/batches", batch(
        {"id": item_id, "entity": "routine_items", "op": "delete"},
        {"id": rid(), "entity": "routine_items", "op": "delete"},
    ), format="json")
    assert deleted.data["applied"] == 2  # apagar o que não existe também é sucesso
    assert client.get(f"/api/v1/routine-items/{item_id}").status_code == 404


def test_invalid_record_is_rejected_without_blocking_others(client):
    good, bad = rid(), rid()
    response = client.post("/api/v1/sync/batches", batch(
        {"id": bad, "entity": "symptom_logs", "data": {"status": "different"}},
        {"id": good, "entity": "hydration_logs", "data": {"amount_ml": 250}},
    ), format="json")
    results = {r["id"]: r for r in response.data["results"]}
    assert results[bad]["status"] == "rejected"
    assert results[bad]["error"]["code"] == "validation_error"
    assert "symptoms" in results[bad]["error"]["details"]
    assert results[good]["status"] == "applied" and results[good]["error"] is None
    assert response.data["rejected"] == 1


def test_profile_rules_in_sync(client):
    response = client.post("/api/v1/sync/batches", batch(
        {"id": rid(), "entity": "profile", "data": {"age": 30}},
        {"id": client.session_data["uid"], "entity": "profile", "op": "delete"},
    ), format="json")
    codes = [r["error"]["code"] for r in response.data["results"]]
    assert codes == ["invalid_record", "invalid_operation"]


def test_sync_only_on_wifi(client):
    record = {"id": rid(), "entity": "hydration_logs", "data": {"amount_ml": 200}}
    response = client.post("/api/v1/sync/batches", batch(record, network="cellular"), format="json")
    assert response.status_code == 412
    assert response.data["error"]["code"] == "wifi_required"
    assert client.get("/api/v1/hydration").data["results"] == []

    assert client.post("/api/v1/sync/batches", batch(record, network="ethernet"), format="json").status_code == 200


def test_wifi_rule_can_be_disabled(client, settings):
    settings.SYNC_WIFI_ONLY = False
    record = {"id": rid(), "entity": "hydration_logs", "data": {"amount_ml": 200}}
    assert client.post("/api/v1/sync/batches", batch(record, network="cellular"), format="json").status_code == 200


def test_batch_size_limit_and_validation(client, settings):
    settings.SYNC_MAX_BATCH_SIZE = 2
    records = [{"id": rid(), "entity": "hydration_logs", "data": {"amount_ml": 100}} for _ in range(3)]
    response = client.post("/api/v1/sync/batches", batch(*records), format="json")
    assert response.status_code == 400
    assert "records" in response.data["error"]["details"]

    empty = client.post("/api/v1/sync/batches", batch(), format="json")
    assert empty.status_code == 400
    unknown = client.post("/api/v1/sync/batches", batch({"id": rid(), "entity": "pedidos"}), format="json")
    assert unknown.status_code == 400


def test_sync_is_isolated_per_user(make_client):
    alice, bob = make_client(), make_client()
    item_id = rid()
    alice.post("/api/v1/sync/batches", batch(
        {"id": item_id, "entity": "routine_items", "data": {"product_id": "creatina"}},
    ), format="json")
    bob.post("/api/v1/sync/batches", batch(
        {"id": item_id, "entity": "routine_items", "data": {"product_id": "whey-protein"}},
    ), format="json")
    assert alice.get(f"/api/v1/routine-items/{item_id}").data["product_id"] == "creatina"
    assert bob.get(f"/api/v1/routine-items/{item_id}").data["product_id"] == "whey-protein"
