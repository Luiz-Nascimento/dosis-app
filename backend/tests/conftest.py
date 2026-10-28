import pytest
from django.core.cache import cache
from rest_framework.test import APIClient

from apps.core.auth import get_auth_provider, reset_auth_provider
from apps.core.store import get_store, reset_store


@pytest.fixture(autouse=True)
def mock_firebase(settings):
    """Todos os testes rodam no modo mock, com store e contas zerados."""
    settings.FIREBASE_MODE = "mock"
    settings.MOCK_STORE_PATH = ""
    reset_store()
    reset_auth_provider()
    cache.clear()
    yield
    reset_store()
    reset_auth_provider()


@pytest.fixture
def api():
    return APIClient()


@pytest.fixture
def store():
    return get_store()


@pytest.fixture
def auth_provider():
    return get_auth_provider()


@pytest.fixture
def make_client():
    """Cria um APIClient já autenticado com uma conta anônima nova."""

    def _make():
        client = APIClient()
        response = client.post("/api/v1/auth/anonymous/")
        assert response.status_code == 201, response.data
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {response.data['id_token']}")
        client.session_data = response.data
        return client

    return _make


@pytest.fixture
def client(make_client):
    return make_client()
