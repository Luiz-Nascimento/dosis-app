def test_default_profile(client):
    response = client.get("/api/v1/profile/")
    assert response.status_code == 200
    assert response.data["uid"] == client.session_data["uid"]
    assert response.data["is_anonymous"] is True
    assert response.data["weight_kg"] is None
    assert response.data["notifications"] == {"dose_reminders": True, "symptom_reminder": True}


def test_update_profile_encrypts_health_data(client, store):
    payload = {
        "name": "Rafael Martins", "age": 24, "weight_kg": 76, "height_cm": 178,
        "biological_sex": "male", "goal": "hypertrophy",
    }
    response = client.patch("/api/v1/profile/", payload, format="json")
    assert response.status_code == 200, response.data
    for key, value in payload.items():
        assert response.data[key] == value

    raw = store.get(f"users/{client.session_data['uid']}")
    for field in ("age", "weight_kg", "height_cm", "biological_sex"):
        assert raw[field].startswith("enc:v1:")
    assert raw["goal"] == "hypertrophy"


def test_partial_notification_update(client):
    client.patch("/api/v1/profile/", {"notifications": {"dose_reminders": False}}, format="json")
    response = client.get("/api/v1/profile/")
    assert response.data["notifications"] == {"dose_reminders": False, "symptom_reminder": True}


def test_personal_data_can_be_erased(client):
    client.patch("/api/v1/profile/", {"weight_kg": 76}, format="json")
    response = client.patch("/api/v1/profile/", {"weight_kg": None}, format="json")
    assert response.data["weight_kg"] is None


def test_profile_validation(client):
    response = client.patch("/api/v1/profile/", {"age": 5, "biological_sex": "x"}, format="json")
    assert response.status_code == 400
    assert set(response.data["error"]["details"]) == {"age", "biological_sex"}
