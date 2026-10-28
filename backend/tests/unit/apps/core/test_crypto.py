import base64
import os

import pytest
from django.core.exceptions import ImproperlyConfigured

from apps.core import crypto


@pytest.fixture(autouse=True)
def clear_key_cache():
    crypto._key_for.cache_clear()
    yield
    crypto._key_for.cache_clear()


@pytest.mark.parametrize("value", [76.5, 24, "Tudo tranquilo", ["pain", "nausea"], {"a": 1}, True])
def test_roundtrip(value):
    token = crypto.encrypt_value(value, "users/u1/dose_logs/d1#amount")
    assert token.startswith("enc:v1:")
    assert crypto.decrypt_value(token, "users/u1/dose_logs/d1#amount") == value


def test_same_value_encrypts_differently_each_time():
    assert crypto.encrypt_value(5, "x#y") != crypto.encrypt_value(5, "x#y")


def test_ciphertext_is_bound_to_document_and_field():
    token = crypto.encrypt_value(5, "users/u1/dose_logs/d1#amount")
    with pytest.raises(crypto.DecryptionError):
        crypto.decrypt_value(token, "users/u2/dose_logs/d1#amount")
    with pytest.raises(crypto.DecryptionError):
        crypto.decrypt_value(token, "users/u1/dose_logs/d1#notes")


def test_configured_key_is_used(settings):
    settings.FIELD_ENCRYPTION_KEY = base64.urlsafe_b64encode(os.urandom(32)).decode()
    token = crypto.encrypt_value("segredo", "a#b")
    settings.FIELD_ENCRYPTION_KEY = base64.urlsafe_b64encode(os.urandom(32)).decode()
    with pytest.raises(crypto.DecryptionError):
        crypto.decrypt_value(token, "a#b")


def test_invalid_key_length_is_rejected(settings):
    settings.FIELD_ENCRYPTION_KEY = base64.urlsafe_b64encode(b"curta").decode()
    with pytest.raises(ImproperlyConfigured):
        crypto.encrypt_value(1, "a#b")


def test_plain_values_pass_through():
    assert crypto.decrypt_value(None, "a#b") is None
    assert crypto.decrypt_value("texto comum", "a#b") == "texto comum"


def test_encrypt_fields_only_touches_listed_non_null_fields():
    data = {"amount": 5, "notes": None, "name": "Creatina"}
    stored = crypto.encrypt_fields("p", data, ("amount", "notes"))
    assert stored["amount"].startswith("enc:v1:")
    assert stored["notes"] is None and stored["name"] == "Creatina"
    assert crypto.decrypt_fields("p", stored, ("amount", "notes")) == data
