"""Campos de serializer que já devolvem valores aceitos pelo Firestore."""
from __future__ import annotations

import datetime as dt

from rest_framework import serializers

TIME_OF_DAY_REGEX = r"^([01]\d|2[0-3]):[0-5]\d$"


class IsoDateField(serializers.DateField):
    """Data guardada como texto ``AAAA-MM-DD`` (o Firestore não tem tipo data pura)."""

    def to_internal_value(self, value):
        return super().to_internal_value(value).isoformat()

    def to_representation(self, value):
        if isinstance(value, str):
            return value
        return super().to_representation(value)


class TimeOfDayField(serializers.RegexField):
    """Horário ``HH:MM`` (24h), como no campo de horário do Figma."""

    def __init__(self, **kwargs):
        kwargs.setdefault("help_text", "Horário no formato HH:MM (24h).")
        super().__init__(TIME_OF_DAY_REGEX, **kwargs)
        self.error_messages["invalid"] = "Use o formato HH:MM (24h)."


def utcnow() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)
