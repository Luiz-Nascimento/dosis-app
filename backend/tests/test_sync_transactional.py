"""KAN-15: queda no meio do lote não perde nem duplica registros."""
import datetime as dt

import pytest

from .sync_helpers import batch, break_connection_on_transaction, rec, rid, make_client, plaintext_sync  # noqa: F401

pytestmark = pytest.mark.usefixtures("plaintext_sync")

T0 = dt.datetime(2026, 9, 20, 8, 0, tzinfo=dt.timezone.utc)


def at(minutes):
    return T0 + dt.timedelta(minutes=minutes)


def count(store, uid, collection):
    return len(store.list(f"users/{uid}/{collection}"))


@pytest.fixture
def creatina(client):
    response = client.post("/api/v1/routine-items", {"product_id": "creatina"}, format="json")
    return response.data["id"]


def test_connection_drop_in_the_middle_of_20_records(client, store, creatina, monkeypatch):
    uid = client.session_data["uid"]
    records = [
        rec("dose_logs", data={"routine_item_id": creatina, "taken_at": at(i).isoformat()}, at=at(i))
        for i in range(20)
    ]
    payload = batch(*records)
    restore = break_connection_on_transaction(monkeypatch, store, number=11)

    dropped = client.post("/api/v1/sync/batches", payload, format="json")
    assert dropped.status_code == 503
    assert dropped.data["error"]["code"] == "storage_unavailable"
    # O 11º foi montado mas não confirmado: nem a dose nem o recibo existem.
    assert count(store, uid, "dose_logs") == 10
    assert count(store, uid, "sync_mutations") == 10

    status = client.get(f"/api/v1/sync/batches/{payload['batch_id']}").data
    assert status["status"] == "interrupted"
    assert status["processed"] == 10
    assert {m["mutation_id"] for m in status["mutations"]} == {r["mutation_id"] for r in records[:10]}

    restore()
    resumed = client.post("/api/v1/sync/batches", payload, format="json")
    assert resumed.status_code == 200
    assert resumed.data["attempt"] == 2
    assert resumed.data["duplicate"] == 10 and resumed.data["applied"] == 10
    assert [r["status"] for r in resumed.data["results"]] == ["duplicate"] * 10 + ["applied"] * 10
    assert count(store, uid, "dose_logs") == 20

    again = client.post("/api/v1/sync/batches", payload, format="json")
    assert again.data["duplicate"] == 20
    assert count(store, uid, "dose_logs") == 20
    assert client.get(f"/api/v1/sync/batches/{payload['batch_id']}").data["status"] == "completed"


def test_lost_response_resend_is_all_duplicate(client, store):
    uid = client.session_data["uid"]
    payload = batch(*[rec("hydration_logs", data={"amount_ml": 200}) for _ in range(5)])
    first = client.post("/api/v1/sync/batches", payload, format="json")
    assert first.data["applied"] == 5
    second = client.post("/api/v1/sync/batches", payload, format="json")
    assert second.data["duplicate"] == 5 and second.data["applied"] == 0
    assert count(store, uid, "hydration_logs") == 5


def test_same_mutation_in_a_new_batch_is_duplicate(client, store):
    record = rec("hydration_logs", data={"amount_ml": 200})
    client.post("/api/v1/sync/batches", batch(record), format="json")
    response = client.post("/api/v1/sync/batches", batch(record), format="json")
    assert response.data["results"][0]["status"] == "duplicate"
    assert count(store, client.session_data["uid"], "hydration_logs") == 1


def test_out_of_order_changes_keep_the_newest(client):
    item_id = rid()
    created = rec("routine_items", item_id, {"product_id": "creatina"}, at=at(0))
    newer = rec("routine_items", item_id, {"dose_amount": 5}, at=at(30))
    older = rec("routine_items", item_id, {"dose_amount": 10}, at=at(10))
    response = client.post("/api/v1/sync/batches", batch(created, newer, older), format="json")
    assert [r["status"] for r in response.data["results"]] == ["applied", "applied", "stale"]
    assert client.get(f"/api/v1/routine-items/{item_id}").data["dose_amount"] == 5


def test_offline_change_older_than_api_edit_is_stale(client, creatina):
    client.patch(f"/api/v1/routine-items/{creatina}", {"dose_amount": 4}, format="json")
    offline = rec("routine_items", creatina, {"dose_amount": 9}, at=at(0))
    response = client.post("/api/v1/sync/batches", batch(offline), format="json")
    assert response.data["results"][0]["status"] == "stale"
    assert client.get(f"/api/v1/routine-items/{creatina}").data["dose_amount"] == 4


def test_deleted_record_is_not_resurrected_by_older_change(client):
    item_id = rid()
    full = {"name": "Cafeína", "kind": "supplement", "dose_unit": "mg", "dose_amount": 200}
    client.post("/api/v1/sync/batches", batch(rec("routine_items", item_id, full, at=at(0))), format="json")
    client.post("/api/v1/sync/batches", batch(rec("routine_items", item_id, op="delete", at=at(30))), format="json")

    older = client.post("/api/v1/sync/batches", batch(rec("routine_items", item_id, full, at=at(20))), format="json")
    assert older.data["results"][0]["status"] == "stale"
    assert client.get(f"/api/v1/routine-items/{item_id}").status_code == 404

    newer = client.post("/api/v1/sync/batches", batch(rec("routine_items", item_id, full, at=at(40))), format="json")
    assert newer.data["results"][0]["status"] == "applied"
    assert client.get(f"/api/v1/routine-items/{item_id}").status_code == 200


def test_device_clock_in_the_future_is_clamped(client, creatina):
    future = dt.datetime(2099, 1, 1, tzinfo=dt.timezone.utc)
    client.post("/api/v1/sync/batches", batch(rec("routine_items", creatina, {"dose_amount": 5}, at=future)), format="json")
    later = rec("routine_items", creatina, {"dose_amount": 7}, at=dt.datetime.now(dt.timezone.utc) + dt.timedelta(seconds=1))
    response = client.post("/api/v1/sync/batches", batch(later), format="json")
    assert response.data["results"][0]["status"] == "applied"
    assert client.get(f"/api/v1/routine-items/{creatina}").data["dose_amount"] == 7


def test_rejected_mutation_can_be_resent_after_dependency_arrives(client):
    item_id = rid()
    dose = rec("dose_logs", data={"routine_item_id": item_id})
    first = client.post("/api/v1/sync/batches", batch(dose), format="json")
    assert first.data["results"][0]["status"] == "rejected"

    item = rec("routine_items", item_id, {"product_id": "creatina"})
    retry = client.post("/api/v1/sync/batches", batch(item, dose), format="json")
    assert [r["status"] for r in retry.data["results"]] == ["applied", "applied"]


def test_batch_status_is_private_and_404_when_unknown(client, make_client):
    payload = batch(rec("hydration_logs", data={"amount_ml": 100}))
    client.post("/api/v1/sync/batches", payload, format="json")
    assert client.get(f"/api/v1/sync/batches/{payload['batch_id']}").data["status"] == "completed"
    assert make_client().get(f"/api/v1/sync/batches/{payload['batch_id']}").status_code == 404
    assert client.get(f"/api/v1/sync/batches/{rid()}").status_code == 404
