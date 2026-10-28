"""Formato único de erro da API: ``{"error": {"code", "message", "details"}}``."""
from __future__ import annotations

import logging

from rest_framework import status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import exception_handler as drf_exception_handler

from core.store import StoreError

logger = logging.getLogger("dosis.api")


def exception_handler(exc, context):
    if isinstance(exc, StoreError):
        logger.exception("Falha no Firestore", exc_info=exc)
        return Response(
            {"error": {"code": "storage_unavailable", "message": "Banco de dados indisponível no momento.", "details": None}},
            status=status.HTTP_503_SERVICE_UNAVAILABLE,
        )

    response = drf_exception_handler(exc, context)
    if response is None:
        return None

    if isinstance(exc, ValidationError):
        code, message, details = "validation_error", "Dados inválidos.", response.data
    else:
        detail = getattr(exc, "detail", None)
        code = getattr(detail, "code", None) or getattr(exc, "default_code", "error")
        message = str(detail) if detail is not None else str(exc)
        details = None

    response.data = {"error": {"code": code, "message": message, "details": details}}
    return response
