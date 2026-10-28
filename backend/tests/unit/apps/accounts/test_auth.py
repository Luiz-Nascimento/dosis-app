from rest_framework.test import APIClient

REGISTER = {"name": "Rafael", "email": "Rafael@Gmail.com", "password": "senha1234", "accept_terms": True}


def _auth(client, token):
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


def test_anonymous_sign_in_creates_user_document(api, store):
    response = api.post("/api/v1/auth/anonymous/")
    assert response.status_code == 201
    assert response.data["is_anonymous"] is True
    assert response.data["id_token"] and response.data["refresh_token"]
    user = store.get(f"users/{response.data['uid']}")
    assert user["is_anonymous"] is True and user["created_at"]


def test_me_requires_token(api):
    response = api.get("/api/v1/auth/me/")
    assert response.status_code == 401
    assert response.data["error"]["code"] == "not_authenticated"


def test_me_rejects_invalid_token(api):
    response = _auth(api, "token-falso").get("/api/v1/auth/me/")
    assert response.status_code == 401
    assert response.data["error"]["code"] == "invalid_token"


def test_register_login_and_me(api, auth_provider, store):
    response = api.post("/api/v1/auth/register/", REGISTER, format="json")
    assert response.status_code == 201, response.data
    assert response.data["email"] == "rafael@gmail.com"
    assert response.data["name"] == "Rafael"
    assert response.data["is_anonymous"] is False
    assert response.data["email_verified"] is False
    assert auth_provider.outbox[-1].action == "verifyEmail"
    assert store.get(f"users/{response.data['uid']}")["terms_accepted_at"]

    login = api.post("/api/v1/auth/login/", {"email": "rafael@gmail.com", "password": "senha1234"}, format="json")
    assert login.status_code == 200
    assert login.data["uid"] == response.data["uid"]

    me = _auth(APIClient(), login.data["id_token"]).get("/api/v1/auth/me/")
    assert me.data == {
        "uid": response.data["uid"],
        "email": "rafael@gmail.com",
        "name": "Rafael",
        "is_anonymous": False,
        "email_verified": False,
    }


def test_register_rejects_duplicate_email(api):
    api.post("/api/v1/auth/register/", REGISTER, format="json")
    response = api.post("/api/v1/auth/register/", {**REGISTER, "email": "rafael@gmail.com"}, format="json")
    assert response.status_code == 409
    assert response.data["error"]["code"] == "email_already_in_use"


def test_register_validates_password_policy_and_terms(api):
    response = api.post(
        "/api/v1/auth/register/", {**REGISTER, "password": "abcdefgh", "accept_terms": False}, format="json"
    )
    assert response.status_code == 400
    error = response.data["error"]
    assert error["code"] == "validation_error"
    assert "A senha precisa ter pelo menos um número." in error["details"]["password"]
    assert "accept_terms" in error["details"]


def test_login_with_wrong_password(api):
    api.post("/api/v1/auth/register/", REGISTER, format="json")
    for email in ("rafael@gmail.com", "ninguem@gmail.com"):
        response = api.post("/api/v1/auth/login/", {"email": email, "password": "errada123"}, format="json")
        assert response.status_code == 401
        assert response.data["error"]["code"] == "invalid_credentials"


def test_refresh_keeps_uid(api):
    session = api.post("/api/v1/auth/anonymous/").data
    response = api.post("/api/v1/auth/refresh/", {"refresh_token": session["refresh_token"]}, format="json")
    assert response.status_code == 200
    assert response.data["uid"] == session["uid"]
    bad = api.post("/api/v1/auth/refresh/", {"refresh_token": "invalido"}, format="json")
    assert bad.status_code == 401


def test_email_verification_flow(api, auth_provider):
    session = api.post("/api/v1/auth/register/", REGISTER, format="json").data
    code = auth_provider.outbox[-1].oob_code

    assert api.post("/api/v1/auth/verify-email/confirm/", {"oob_code": code}, format="json").status_code == 204
    refreshed = api.post("/api/v1/auth/refresh/", {"refresh_token": session["refresh_token"]}, format="json")
    assert refreshed.data["email_verified"] is True

    invalid = api.post("/api/v1/auth/verify-email/confirm/", {"oob_code": "x"}, format="json")
    assert invalid.data["error"]["code"] == "invalid_action_code"


def test_resend_verification_email(api, auth_provider):
    session = api.post("/api/v1/auth/register/", REGISTER, format="json").data
    before = len(auth_provider.outbox)
    response = _auth(api, session["id_token"]).post("/api/v1/auth/verify-email/")
    assert response.status_code == 202
    assert len(auth_provider.outbox) == before + 1


def test_password_reset_flow(api, auth_provider):
    api.post("/api/v1/auth/register/", REGISTER, format="json")

    unknown = api.post("/api/v1/auth/password-reset/", {"email": "ninguem@gmail.com"}, format="json")
    assert unknown.status_code == 202
    assert auth_provider.outbox[-1].action == "verifyEmail"  # nada enviado para e-mail desconhecido

    assert api.post("/api/v1/auth/password-reset/", {"email": "rafael@gmail.com"}, format="json").status_code == 202
    code = auth_provider.outbox[-1].oob_code
    confirm = api.post(
        "/api/v1/auth/password-reset/confirm/", {"oob_code": code, "new_password": "novasenha9"}, format="json"
    )
    assert confirm.status_code == 204

    old = api.post("/api/v1/auth/login/", {"email": "rafael@gmail.com", "password": "senha1234"}, format="json")
    new = api.post("/api/v1/auth/login/", {"email": "rafael@gmail.com", "password": "novasenha9"}, format="json")
    assert old.status_code == 401 and new.status_code == 200

    reused = api.post(
        "/api/v1/auth/password-reset/confirm/", {"oob_code": code, "new_password": "outrasenha9"}, format="json"
    )
    assert reused.status_code == 400
    assert reused.data["error"]["code"] == "invalid_action_code"


def test_link_anonymous_account_keeps_uid(client, store):
    uid = client.session_data["uid"]
    payload = {"name": "Rafael", "email": "rafael@gmail.com", "password": "senha1234", "accept_terms": True}
    response = client.post("/api/v1/auth/link/", payload, format="json")
    assert response.status_code == 200, response.data
    assert response.data["uid"] == uid
    assert response.data["is_anonymous"] is False
    assert store.get(f"users/{uid}")["email"] == "rafael@gmail.com"

    linked = _auth(APIClient(), response.data["id_token"])
    assert linked.get("/api/v1/auth/me/").data["email"] == "rafael@gmail.com"
    again = linked.post("/api/v1/auth/link/", {**payload, "email": "outro@gmail.com"}, format="json")
    assert again.status_code == 409
    assert again.data["error"]["code"] == "not_anonymous"


def test_link_rejects_email_in_use(api, client):
    api.post("/api/v1/auth/register/", REGISTER, format="json")
    payload = {"email": "rafael@gmail.com", "password": "senha1234", "accept_terms": True}
    response = client.post("/api/v1/auth/link/", payload, format="json")
    assert response.status_code == 409
    assert response.data["error"]["code"] == "email_already_in_use"
