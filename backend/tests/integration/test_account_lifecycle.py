"""Conta: vincular a conta anônima e excluir tudo (LGPD), atravessando todos os apps."""
from rest_framework.test import APIClient

from tests.unit.apps.sync.helpers import Device, accept_consent, batch, rec

USER_COLLECTIONS = (
    "routine_items", "dose_logs", "symptom_logs", "hydration_logs", "diagnostics",
    "backups", "sync_keys", "sync_batches", "sync_mutations",
)


def authenticated(session):
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {session['id_token']}")
    client.session_data = session
    return client


def fill_every_app(client):
    client.patch("/api/v1/profile/", {"name": "Rafa", "weight_kg": 76}, format="json")
    item = client.post("/api/v1/tracking/routine-items/", {"product_id": "creatina"}, format="json").data
    dose = client.post("/api/v1/tracking/doses/", {"routine_item_id": item["id"]}, format="json").data
    client.post("/api/v1/tracking/symptoms/", {"status": "normal"}, format="json")
    client.post("/api/v1/system/diagnostics/firestore/", {"message": "antes"}, format="json")
    accept_consent(client)
    Device(client).send(batch(rec("hydration_logs", data={"amount_ml": 500})))
    backup = client.post("/api/v1/backups/", {}, format="json").data
    return {"dose": dose, "backup": backup}


def test_linking_anonymous_account_keeps_data_of_every_app(client):
    uid = client.session_data["uid"]
    data = fill_every_app(client)

    response = client.post("/api/v1/auth/link/", {
        "email": "rafa@gmail.com", "password": "senha1234", "accept_terms": True,
    }, format="json")
    assert response.status_code == 200, response.data
    assert response.data["uid"] == uid

    linked = authenticated(response.data)
    profile = linked.get("/api/v1/profile/").data
    assert (profile["name"], profile["email"], profile["is_anonymous"]) == ("Rafa", "rafa@gmail.com", False)
    assert linked.get(f"/api/v1/tracking/doses/{data['dose']['id']}/").status_code == 200
    assert len(linked.get("/api/v1/tracking/hydration/").data["results"]) == 1
    assert linked.get("/api/v1/system/diagnostics/firestore/").data["data"]["message"] == "antes"
    assert linked.get(f"/api/v1/backups/{data['backup']['id']}/").status_code == 200
    assert linked.get("/api/v1/sync/consent/").data["accepted"] is True


def test_delete_account_wipes_every_app(api, store):
    credentials = {"email": "rafa@gmail.com", "password": "senha1234"}
    session = api.post("/api/v1/auth/register/", {**credentials, "name": "Rafa", "accept_terms": True}, format="json").data
    client = authenticated(session)
    fill_every_app(client)
    uid = session["uid"]
    assert all(store.list(f"users/{uid}/{c}") for c in ("dose_logs", "backups", "sync_keys"))

    assert client.delete("/api/v1/auth/me/").status_code == 204

    assert store.get(f"users/{uid}") is None
    for collection in USER_COLLECTIONS:
        assert store.list(f"users/{uid}/{collection}") == [], collection
    assert client.get("/api/v1/profile/").status_code == 401
    assert api.post("/api/v1/auth/login/", credentials, format="json").status_code == 401
    # O e-mail fica livre para uma conta nova.
    again = api.post("/api/v1/auth/register/", {**credentials, "name": "Rafa", "accept_terms": True}, format="json")
    assert again.status_code == 201 and again.data["uid"] != uid
