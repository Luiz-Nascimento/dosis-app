def test_health_is_public(api):
    response = api.get("/api/v1/system/health/")
    assert response.status_code == 200
    assert response.data == {"status": "ok", "firebase_mode": "mock"}


def test_firestore_check_writes_and_reads_own_document(client):
    uid = client.session_data["uid"]
    response = client.post("/api/v1/system/diagnostics/firestore/", {"message": "olá"}, format="json")
    assert response.status_code == 200
    assert response.data["path"] == f"users/{uid}/diagnostics/firestore"
    assert response.data["data"]["message"] == "olá"


def test_firestore_check_is_isolated_per_user(make_client):
    alice, bob = make_client(), make_client()
    alice.post("/api/v1/system/diagnostics/firestore/", {"message": "segredo"}, format="json")

    response = bob.get("/api/v1/system/diagnostics/firestore/")
    assert response.data["path"].startswith(f"users/{bob.session_data['uid']}/")
    assert response.data["data"] is None


def test_firestore_check_requires_authentication(api):
    assert api.get("/api/v1/system/diagnostics/firestore/").status_code == 401


def test_openapi_schema_and_swagger(api):
    schema = api.get("/api/schema/")
    assert schema.status_code == 200
    assert b"/api/v1/auth/anonymous/" in schema.content
    assert b"FirebaseIdToken" in schema.content
    assert api.get("/api/docs/").status_code == 200
