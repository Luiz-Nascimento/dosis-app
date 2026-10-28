"""Inicialização do Firebase Admin SDK (usado só com FIREBASE_MODE=firebase)."""
from __future__ import annotations

import os

import firebase_admin
from django.conf import settings
from django.core.exceptions import ImproperlyConfigured
from firebase_admin import credentials, firestore

MODE_MOCK = "mock"
MODE_FIREBASE = "firebase"


def firebase_mode() -> str:
    mode = settings.FIREBASE_MODE
    if mode not in (MODE_MOCK, MODE_FIREBASE):
        raise ImproperlyConfigured(f"FIREBASE_MODE deve ser 'mock' ou 'firebase', não {mode!r}.")
    return mode


def _export_emulator_hosts() -> None:
    # Os SDKs do Google leem os emuladores destas variáveis de ambiente.
    if settings.FIRESTORE_EMULATOR_HOST:
        os.environ.setdefault("FIRESTORE_EMULATOR_HOST", settings.FIRESTORE_EMULATOR_HOST)
    if settings.FIREBASE_AUTH_EMULATOR_HOST:
        os.environ.setdefault("FIREBASE_AUTH_EMULATOR_HOST", settings.FIREBASE_AUTH_EMULATOR_HOST)


def get_app() -> firebase_admin.App:
    _export_emulator_hosts()
    try:
        return firebase_admin.get_app()
    except ValueError:
        pass
    if settings.FIREBASE_CREDENTIALS:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS)
    elif settings.FIRESTORE_EMULATOR_HOST or settings.FIREBASE_AUTH_EMULATOR_HOST:
        cred = None  # Os emuladores não validam credenciais.
    else:
        raise ImproperlyConfigured(
            "FIREBASE_MODE=firebase exige FIREBASE_CREDENTIALS (JSON da service account) "
            "ou os emuladores do Firebase. Veja backend/README.md."
        )
    return firebase_admin.initialize_app(cred, {"projectId": settings.FIREBASE_PROJECT_ID})


def firestore_client():
    _export_emulator_hosts()
    if settings.FIRESTORE_EMULATOR_HOST:
        from google.auth.credentials import AnonymousCredentials
        from google.cloud import firestore as gfirestore

        return gfirestore.Client(project=settings.FIREBASE_PROJECT_ID, credentials=AnonymousCredentials())
    return firestore.client(get_app())
