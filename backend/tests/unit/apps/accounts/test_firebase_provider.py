"""FirebaseAuthProvider com as respostas HTTP do Firebase simuladas.

As respostas imitam o Firebase real: ``accounts:update`` que muda só o
displayName não devolve tokens novos.
"""
import pytest

from apps.core.auth import firebase as fb
from apps.core.auth.base import AuthError

SIGN_UP = {"idToken": "token-sem-nome", "refreshToken": "refresh-1", "expiresIn": "3600", "localId": "uid-1"}
UPDATE_SO_NOME = {"localId": "uid-1", "email": "rafa@gmail.com", "displayName": "Rafa"}
REFRESH = {"id_token": "token-com-nome", "refresh_token": "refresh-2", "expires_in": "3600"}
CLAIMS = {
    "token-sem-nome": {"uid": "uid-1", "email": "rafa@gmail.com", "firebase": {"sign_in_provider": "password"}},
    "token-com-nome": {
        "uid": "uid-1", "email": "rafa@gmail.com", "name": "Rafa", "firebase": {"sign_in_provider": "password"},
    },
}


class FakeResponse:
    def __init__(self, status, body):
        self.status_code = status
        self.ok = status < 400
        self._body = body

    def json(self):
        return self._body


def firebase_error(message):
    return FakeResponse(400, {"error": {"code": 400, "message": message}})


@pytest.fixture
def firebase(settings, monkeypatch):
    """Provedor real com o HTTP trocado por respostas por endpoint. Guarda as chamadas."""
    settings.FIREBASE_WEB_API_KEY = "chave-teste"
    settings.FIREBASE_AUTH_EMULATOR_HOST = ""
    responses = {
        "accounts:signUp": FakeResponse(200, SIGN_UP),
        "accounts:update": FakeResponse(200, UPDATE_SO_NOME),
        "accounts:sendOobCode": FakeResponse(200, {"email": "rafa@gmail.com"}),
        "token": FakeResponse(200, REFRESH),
    }
    calls = []

    def post(url, **kwargs):
        endpoint = url.rsplit("/", 1)[-1]
        calls.append((endpoint, kwargs.get("json") or kwargs.get("data")))
        return responses[endpoint]

    monkeypatch.setattr(fb.requests, "post", post)
    monkeypatch.setattr(fb.FirebaseAuthProvider, "verify_id_token", lambda self, token: CLAIMS[token])
    provider = fb.FirebaseAuthProvider()
    provider.responses = responses
    provider.calls = calls
    return provider


def test_sign_up_com_nome_nao_depende_de_tokens_no_update(firebase):
    session = firebase.sign_up("rafa@gmail.com", "senha1234", "Rafa")

    assert session.uid == "uid-1"
    assert session.name == "Rafa"
    assert session.id_token == "token-com-nome"
    assert session.refresh_token == "refresh-2"
    sent = [payload for endpoint, payload in firebase.calls if endpoint == "accounts:sendOobCode"]
    assert sent == [{"requestType": "VERIFY_EMAIL", "idToken": "token-com-nome"}]


def test_sign_up_sem_nome_usa_tokens_do_cadastro(firebase):
    session = firebase.sign_up("rafa@gmail.com", "senha1234", None)

    assert session.id_token == "token-sem-nome"
    assert [endpoint for endpoint, _ in firebase.calls] == ["accounts:signUp", "accounts:sendOobCode"]


def test_falha_no_envio_do_email_nao_derruba_o_cadastro(firebase, caplog):
    firebase.responses["accounts:sendOobCode"] = firebase_error("QUOTA_EXCEEDED : Exceeded quota for email")

    session = firebase.sign_up("rafa@gmail.com", "senha1234", "Rafa")

    assert session.name == "Rafa"
    assert "QUOTA_EXCEEDED" in caplog.text


def test_reenvio_do_email_continua_mostrando_o_erro(firebase):
    firebase.responses["accounts:sendOobCode"] = firebase_error("QUOTA_EXCEEDED : Exceeded quota for email")

    with pytest.raises(AuthError):
        firebase.send_email_verification("token-com-nome")


def test_endpoint_de_cadastro_responde_201_com_o_firebase_real(firebase, monkeypatch, api, store):
    from apps.core import auth as auth_module

    # O endpoint passa a usar o provedor real (com HTTP simulado); o Firestore segue em memória.
    monkeypatch.setattr(auth_module, "_provider", firebase)

    response = api.post(
        "/api/v1/auth/register/",
        {"name": "Rafa", "email": "rafa@gmail.com", "password": "senha1234", "accept_terms": True},
        format="json",
    )

    assert response.status_code == 201, response.content
    assert response.data["name"] == "Rafa"
    user = store.get("users/uid-1")
    assert user["name"] == "Rafa"
    assert user["terms_accepted_at"] is not None
