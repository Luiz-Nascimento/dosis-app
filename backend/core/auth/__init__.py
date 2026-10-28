from __future__ import annotations

import threading

from .base import AuthError, AuthProvider, AuthSession

__all__ = ["AuthError", "AuthProvider", "AuthSession", "get_auth_provider", "reset_auth_provider"]

_provider: AuthProvider | None = None
_lock = threading.Lock()


def get_auth_provider() -> AuthProvider:
    """Provedor do modo configurado em FIREBASE_MODE (instância única por processo)."""
    global _provider
    if _provider is None:
        with _lock:
            if _provider is None:
                _provider = _build_provider()
    return _provider


def reset_auth_provider() -> None:
    global _provider
    with _lock:
        _provider = None


def _build_provider() -> AuthProvider:
    from core.firebase import MODE_MOCK, firebase_mode

    if firebase_mode() == MODE_MOCK:
        from core.store import get_store

        from .mock import MockAuthProvider

        return MockAuthProvider(get_store())

    from .firebase import FirebaseAuthProvider

    return FirebaseAuthProvider()
