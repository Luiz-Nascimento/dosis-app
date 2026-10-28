from __future__ import annotations

from typing import Any

from drf_spectacular.utils import OpenApiParameter
from rest_framework import serializers

from apps.core.choices import KIND_CHOICES
from apps.core.resources import (
    DATE_RANGE_PARAMETERS,
    ID_PATTERN,
    DateRangeQuerySerializer,
    UserCollectionViewSet,
    crud_schema,
    day_bounds,
    parse_query,
)

from . import repositories as r
from . import serializers as s


def date_range_query(request, time_field: str, extra_where=()) -> dict[str, Any]:
    query = parse_query(DateRangeQuerySerializer, request)
    lower, upper = day_bounds(query.get("date_from"), query.get("date_to"))
    where = list(extra_where)
    if lower:
        where.append((time_field, ">=", lower))
    if upper:
        where.append((time_field, "<", upper))
    return {"where": where, "order_by": [(time_field, "desc")], "limit": query["limit"]}


class RoutineItemQuerySerializer(serializers.Serializer):
    active = serializers.BooleanField(required=False, allow_null=True, default=None)
    kind = serializers.ChoiceField(KIND_CHOICES, required=False)


@crud_schema(
    "Rotina (stack)", s.RoutineItemSerializer, "item da rotina",
    list_parameters=[
        OpenApiParameter("active", bool, description="true = só itens ativos (\"Stack de hoje\")."),
        OpenApiParameter("kind", str, enum=[k for k, _ in KIND_CHOICES]),
    ],
    list_description="Suplementos e anabolizantes que o usuário usa (\"Seus itens\").",
)
class RoutineItemViewSet(UserCollectionViewSet):
    repository_class = r.RoutineItemRepository
    serializer_class = s.RoutineItemSerializer

    def list(self, request):
        query = parse_query(RoutineItemQuerySerializer, request)
        response = super().list(request)
        results = response.data["results"]
        if query.get("active") is not None:
            results = [i for i in results if i["active"] == query["active"]]
        if query.get("kind"):
            results = [i for i in results if i["kind"] == query["kind"]]
        response.data["results"] = results
        return response


class DoseLogQuerySerializer(DateRangeQuerySerializer):
    routine_item_id = serializers.RegexField(rf"^{ID_PATTERN}$", required=False)


@crud_schema(
    "Doses", s.DoseLogSerializer, "dose",
    list_parameters=[
        *DATE_RANGE_PARAMETERS,
        OpenApiParameter("routine_item_id", str, description="Só as doses de um item (histórico por suplemento)."),
    ],
    list_description="Mais recentes primeiro. Use date_from/date_to para o calendário de registros.",
)
class DoseLogViewSet(UserCollectionViewSet):
    repository_class = r.DoseLogRepository
    serializer_class = s.DoseLogSerializer

    def list_query(self, request):
        item = parse_query(DoseLogQuerySerializer, request).get("routine_item_id")
        extra = [("routine_item_id", "==", item)] if item else []
        return date_range_query(request, "taken_at", extra)


@crud_schema(
    "Sintomas", s.SymptomLogSerializer, "registro de sintomas",
    list_parameters=DATE_RANGE_PARAMETERS,
    list_description="Linha do tempo de \"Como você se sentiu\", mais recentes primeiro.",
)
class SymptomLogViewSet(UserCollectionViewSet):
    repository_class = r.SymptomLogRepository
    serializer_class = s.SymptomLogSerializer

    def list_query(self, request):
        return date_range_query(request, "logged_at")


@crud_schema(
    "Hidratação", s.HydrationLogSerializer, "registro de água",
    list_parameters=DATE_RANGE_PARAMETERS,
    list_description="Água ingerida, mais recentes primeiro.",
)
class HydrationLogViewSet(UserCollectionViewSet):
    repository_class = r.HydrationLogRepository
    serializer_class = s.HydrationLogSerializer

    def list_query(self, request):
        return date_range_query(request, "logged_at")
