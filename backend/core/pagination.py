from __future__ import annotations

from typing import Any

from drf_spectacular.utils import OpenApiParameter, inline_serializer
from rest_framework import serializers


class PageQuerySerializer(serializers.Serializer):
    page = serializers.IntegerField(required=False, min_value=1, default=1)
    page_size = serializers.IntegerField(required=False, min_value=1, max_value=100, default=20)


PAGE_PARAMETERS = [
    OpenApiParameter("page", int, description="Página (começa em 1)."),
    OpenApiParameter("page_size", int, description="Itens por página (padrão 20, máximo 100)."),
]


def paginate(items: list[Any], page: int, page_size: int) -> dict[str, Any]:
    start = (page - 1) * page_size
    return {"count": len(items), "page": page, "page_size": page_size, "results": items[start:start + page_size]}


def page_response(name: str, item_serializer) -> serializers.Serializer:
    return inline_serializer(name, {
        "count": serializers.IntegerField(help_text="Total de itens no filtro."),
        "page": serializers.IntegerField(),
        "page_size": serializers.IntegerField(),
        "results": item_serializer(many=True),
    })
