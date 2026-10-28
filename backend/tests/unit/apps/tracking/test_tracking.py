import uuid

import pytest


def _create(client, url, payload):
    response = client.post(url, payload, format="json")
    assert response.status_code == 201, response.data
    return response.data


@pytest.fixture
def creatina(client):
    return _create(client, "/api/v1/tracking/routine-items/", {"product_id": "creatina", "schedule_times": ["08:00"]})


# -- Rotina (stack) --------------------------------------------------------------


def test_routine_item_defaults_come_from_catalog(creatina):
    assert creatina["name"] == "Creatina monohidratada"
    assert creatina["kind"] == "supplement"
    assert creatina["dose_unit"] == "g"
    assert creatina["dose_amount"] == 3
    assert creatina["protocol"] == "continuous"
    assert creatina["active"] is True
    assert creatina["created_at"]


def test_custom_routine_item_requires_basic_fields(client):
    response = client.post("/api/v1/tracking/routine-items/", {"brand": "Growth"}, format="json")
    assert response.status_code == 400
    assert set(response.data["error"]["details"]) == {"name", "kind", "dose_unit"}

    item = _create(client, "/api/v1/tracking/routine-items/", {"name": "Cafeína", "kind": "supplement", "dose_unit": "mg"})
    assert item["product_id"] is None
    assert item["notes"] is None and item["start_date"] is None


def test_routine_item_rejects_unknown_product(client):
    response = client.post("/api/v1/tracking/routine-items/", {"product_id": "nao-existe"}, format="json")
    assert response.data["error"]["details"]["product_id"] == ["Produto não encontrado no catálogo."]


def test_client_generated_id_and_duplicate(client):
    item_id = str(uuid.uuid4())
    item = _create(client, "/api/v1/tracking/routine-items/", {"id": item_id, "product_id": "whey-protein"})
    assert item["id"] == item_id
    again = client.post("/api/v1/tracking/routine-items/", {"id": item_id, "product_id": "whey-protein"}, format="json")
    assert again.status_code == 409
    assert again.data["error"]["code"] == "already_exists"


def test_routine_item_list_filters(client, creatina):
    _create(client, "/api/v1/tracking/routine-items/", {"product_id": "testosterona", "active": False})
    assert len(client.get("/api/v1/tracking/routine-items/").data["results"]) == 2
    active = client.get("/api/v1/tracking/routine-items/", {"active": "true"}).data["results"]
    assert [i["id"] for i in active] == [creatina["id"]]
    anabolic = client.get("/api/v1/tracking/routine-items/", {"kind": "anabolic"}).data["results"]
    assert [i["name"] for i in anabolic] == ["Testosterona"]


def test_routine_item_partial_update_and_validation(client, creatina):
    url = f"/api/v1/tracking/routine-items/{creatina['id']}/"
    response = client.patch(url, {"protocol": "loading", "dose_amount": 20, "schedule_times": ["20:30", "08:00", "08:00"]}, format="json")
    assert response.status_code == 200, response.data
    assert response.data["protocol"] == "loading"
    assert response.data["dose_amount"] == 20
    assert response.data["schedule_times"] == ["08:00", "20:30"]
    assert response.data["name"] == "Creatina monohidratada"

    bad = client.patch(url, {"start_date": "2026-10-10", "end_date": "2026-10-01", "schedule_times": ["25:00"]}, format="json")
    assert bad.status_code == 400
    assert "schedule_times" in bad.data["error"]["details"]


def test_routine_item_delete(client, creatina):
    url = f"/api/v1/tracking/routine-items/{creatina['id']}/"
    assert client.delete(url).status_code == 204
    assert client.get(url).status_code == 404
    assert client.delete(url).status_code == 404


def test_records_are_isolated_between_users(make_client, creatina):
    other = make_client()
    assert other.get(f"/api/v1/tracking/routine-items/{creatina['id']}/").status_code == 404
    assert other.get("/api/v1/tracking/routine-items/").data["results"] == []


def test_routine_notes_are_encrypted(client, store):
    item = _create(client, "/api/v1/tracking/routine-items/", {"product_id": "creatina", "notes": "Tomar com água"})
    raw = store.get(f"users/{client.session_data['uid']}/routine_items/{item['id']}")
    assert raw["notes"].startswith("enc:v1:")
    assert client.get(f"/api/v1/tracking/routine-items/{item['id']}/").data["notes"] == "Tomar com água"


# -- Doses ------------------------------------------------------------------------


def test_register_dose_with_only_routine_item(client, store, creatina):
    dose = _create(client, "/api/v1/tracking/doses/", {"routine_item_id": creatina["id"]})
    assert dose["name"] == "Creatina monohidratada"
    assert dose["amount"] == 3 and dose["unit"] == "g"
    assert dose["protocol"] == "continuous"
    assert dose["product_id"] == "creatina"
    assert dose["taken_at"] and dose["local_date"]

    raw = store.get(f"users/{client.session_data['uid']}/dose_logs/{dose['id']}")
    assert raw["amount"].startswith("enc:v1:")


def test_dose_local_date_uses_app_timezone(client, creatina):
    dose = _create(client, "/api/v1/tracking/doses/", {"routine_item_id": creatina["id"], "taken_at": "2026-09-20T01:30:00Z"})
    assert dose["local_date"] == "2026-09-19"  # 22:30 em Brasília
    assert dose["taken_at"] == "2026-09-19T22:30:00-03:00"


def test_dose_without_routine_item_requires_fields(client):
    response = client.post("/api/v1/tracking/doses/", {"name": "Whey"}, format="json")
    assert set(response.data["error"]["details"]) == {"kind", "amount", "unit"}
    unknown = client.post("/api/v1/tracking/doses/", {"routine_item_id": "naoexiste123"}, format="json")
    assert "routine_item_id" in unknown.data["error"]["details"]


def test_dose_list_by_day_and_item(client, creatina):
    whey = _create(client, "/api/v1/tracking/routine-items/", {"product_id": "whey-protein"})
    for day, hour in (("19", "08"), ("20", "08"), ("20", "12"), ("21", "08")):
        _create(client, "/api/v1/tracking/doses/", {"routine_item_id": creatina["id"], "taken_at": f"2026-09-{day}T{hour}:00:00-03:00"})
    _create(client, "/api/v1/tracking/doses/", {"routine_item_id": whey["id"], "taken_at": "2026-09-20T12:00:00-03:00", "amount": 60})

    day = client.get("/api/v1/tracking/doses/", {"date_from": "2026-09-20", "date_to": "2026-09-20"}).data["results"]
    assert [d["taken_at"][11:16] for d in day] == ["12:00", "12:00", "08:00"]
    assert {d["local_date"] for d in day} == {"2026-09-20"}

    history = client.get("/api/v1/tracking/doses/", {"routine_item_id": creatina["id"], "limit": 2}).data["results"]
    assert [d["local_date"] for d in history] == ["2026-09-21", "2026-09-20"]

    bad = client.get("/api/v1/tracking/doses/", {"date_from": "2026-09-21", "date_to": "2026-09-20"})
    assert bad.status_code == 400


def test_dose_edit_recomputes_local_date(client, creatina):
    dose = _create(client, "/api/v1/tracking/doses/", {"routine_item_id": creatina["id"], "taken_at": "2026-09-20T08:00:00-03:00"})
    response = client.patch(f"/api/v1/tracking/doses/{dose['id']}/", {"taken_at": "2026-09-21T08:00:00-03:00", "amount": 5}, format="json")
    assert response.data["local_date"] == "2026-09-21"
    assert response.data["amount"] == 5


def test_dose_history_survives_routine_item_deletion(client, creatina):
    dose = _create(client, "/api/v1/tracking/doses/", {"routine_item_id": creatina["id"]})
    client.delete(f"/api/v1/tracking/routine-items/{creatina['id']}/")
    assert client.get(f"/api/v1/tracking/doses/{dose['id']}/").data["name"] == "Creatina monohidratada"


# -- Sintomas ----------------------------------------------------------------------


def test_symptom_log_normal_day(client):
    log = _create(client, "/api/v1/tracking/symptoms/", {"status": "normal", "notes": "Tudo tranquilo"})
    assert log["symptoms"] == [] and log["local_date"]


def test_symptom_log_rules(client):
    cases = [
        ({"status": "different"}, "symptoms"),
        ({"status": "normal", "symptoms": ["pain"]}, "symptoms"),
        ({"status": "different", "symptoms": ["other"]}, "other_description"),
        ({"symptoms": ["pain"]}, "status"),
    ]
    for payload, field in cases:
        response = client.post("/api/v1/tracking/symptoms/", payload, format="json")
        assert response.status_code == 400, payload
        assert field in response.data["error"]["details"], payload


def test_symptom_log_is_encrypted_and_deduplicated(client, store):
    log = _create(client, "/api/v1/tracking/symptoms/", {
        "status": "different",
        "symptoms": ["dizziness", "fatigue", "dizziness", "other"],
        "other_description": "Visão turva",
        "notes": "Um pouco tonto e mais cansado que o normal.",
    })
    assert log["symptoms"] == ["dizziness", "fatigue", "other"]
    raw = store.get(f"users/{client.session_data['uid']}/symptom_logs/{log['id']}")
    for field in ("symptoms", "other_description", "notes"):
        assert raw[field].startswith("enc:v1:")


def test_symptom_timeline_order(client):
    for day in ("18", "20", "19"):
        _create(client, "/api/v1/tracking/symptoms/", {"status": "normal", "logged_at": f"2026-09-{day}T21:00:00-03:00"})
    timeline = client.get("/api/v1/tracking/symptoms/").data["results"]
    assert [s["local_date"] for s in timeline] == ["2026-09-20", "2026-09-19", "2026-09-18"]


# -- Hidratação --------------------------------------------------------------------


def test_hydration_logs(client):
    _create(client, "/api/v1/tracking/hydration/", {"amount_ml": 500, "logged_at": "2026-09-20T09:00:00-03:00"})
    _create(client, "/api/v1/tracking/hydration/", {"amount_ml": 300, "logged_at": "2026-09-21T09:00:00-03:00"})
    day = client.get("/api/v1/tracking/hydration/", {"date_from": "2026-09-20", "date_to": "2026-09-20"}).data["results"]
    assert [h["amount_ml"] for h in day] == [500]
    assert client.post("/api/v1/tracking/hydration/", {"amount_ml": 0}, format="json").status_code == 400
