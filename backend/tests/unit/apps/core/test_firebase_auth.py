"""FirebaseAuthProvider contra respostas simuladas da API REST do Firebase Auth."""
import pytest

from apps.core.auth import firebase as firebase_auth
from apps.core.auth.base import EmailAlreadyInUse
from apps.core.auth.firebase import FirebaseAuthProvider


class FakeResponse:
    def __init__(self, status: int, body: dict):
        self.status_code = status
        self.ok = status < 400
        self._body = body

    def json(self):
        return self._body


class FakeIdentityToolkit:
    """Reproduz o Identity Toolkit: ``accounts:update`` só com o nome não devolve tokens."""

    def __init__(self):
        self.calls: list[tuple[str, dict]] = []
        self.users: dict[str, dict] = {}

    def post(self, url, params=None, json=None, data=None, timeout=None):
        endpoint = url.rsplit("/", 1)[-1]
        self.calls.append((endpoint, json or data))
        if endpoint == "accounts:signUp":
            if any(u["email"] == json["email"] for u in self.users.values()):
                return FakeResponse(400, {"error": {"message": "EMAIL_EXISTS"}})
            self.users["u1"] = {"email": json["email"], "name": None}
            return FakeResponse(200, {"idToken": "tok-1", "refreshToken": "ref-1", "expiresIn": "3600"})
        if endpoint == "accounts:update":
            self.users["u1"]["name"] = json["displayName"]
            return FakeResponse(200, {"localId": "u1", "displayName": json["displayName"]})
        if endpoint == "accounts:sendOobCode":
            return FakeResponse(200, {"email": self.users["u1"]["email"]})
        if endpoint == "token":
            return FakeResponse(200, {"id_token": "tok-2", "refresh_token": "ref-2", "expires_in": "3600"})
        raise AssertionError(f"endpoint inesperado: {endpoint}")

    def claims(self, id_token, app=None):
        user = self.users["u1"]
        claims = {"uid": "u1", "email": user["email"], "firebase": {"sign_in_provider": "password"}}
        if id_token == "tok-2" and user["name"]:
            claims["name"] = user["name"]
        return claims


@pytest.fixture
def toolkit(monkeypatch, settings):
    settings.FIREBASE_WEB_API_KEY = "test-key"
    settings.FIREBASE_AUTH_EMULATOR_HOST = ""
    fake = FakeIdentityToolkit()
    monkeypatch.setattr(firebase_auth.requests, "post", fake.post)
    monkeypatch.setattr(firebase_auth.admin_auth, "verify_id_token", fake.claims)
    monkeypatch.setattr(firebase_auth, "get_app", lambda: None)
    return fake


def test_sign_up_with_name_refreshes_to_get_a_token_with_the_name(toolkit):
    session = FirebaseAuthProvider().sign_up("ana@dosis.dev", "senha1234", "Ana")

    assert [endpoint for endpoint, _ in toolkit.calls] == [
        "accounts:signUp", "accounts:sendOobCode", "accounts:update", "token",
    ]
    assert session.id_token == "tok-2"
    assert session.refresh_token == "ref-2"
    assert session.name == "Ana"
    assert session.email == "ana@dosis.dev"


def test_sign_up_without_name_keeps_the_sign_up_tokens(toolkit):
    session = FirebaseAuthProvider().sign_up("ana@dosis.dev", "senha1234", None)

    assert [endpoint for endpoint, _ in toolkit.calls] == ["accounts:signUp", "accounts:sendOobCode"]
    assert session.id_token == "tok-1"


def test_sign_up_maps_firebase_errors(toolkit):
    FirebaseAuthProvider().sign_up("ana@dosis.dev", "senha1234", None)
    with pytest.raises(EmailAlreadyInUse):
        FirebaseAuthProvider().sign_up("ana@dosis.dev", "senha1234", None)
