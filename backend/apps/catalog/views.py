"""Catálogo de produtos e artigos educativos (somente leitura para o app)."""
from __future__ import annotations

import unicodedata

from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import viewsets
from rest_framework.response import Response

from apps.core.choices import KIND_CHOICES
from apps.core.pagination import PAGE_PARAMETERS, page_response, paginate
from apps.core.resources import RecordNotFound, parse_query
from apps.core.schema import ErrorSerializer
from apps.core.store import get_store

from . import serializers as s


def normalize(text: str) -> str:
    """Minúsculas e sem acento, para a busca achar "omega" em "Ômega 3"."""
    decomposed = unicodedata.normalize("NFKD", text.lower())
    return "".join(ch for ch in decomposed if not unicodedata.combining(ch))


def _all(collection: str) -> list[dict]:
    return [{"id": d.id, **d.data} for d in get_store().list(collection)]


def _one(collection: str, item_id: str) -> dict:
    data = get_store().get(f"{collection}/{item_id}")
    if data is None:
        raise RecordNotFound()
    return {"id": item_id, **data}


class ProductViewSet(viewsets.ViewSet):
    lookup_field = "id"
    lookup_value_regex = r"[a-z0-9-]+"

    @extend_schema(
        tags=["Catálogo"],
        summary="Listar suplementos e anabolizantes",
        description="Usado na tela \"Adicionar à rotina\". Busca sem acento e paginação.",
        parameters=[
            OpenApiParameter("kind", str, enum=[k for k, _ in KIND_CHOICES]),
            OpenApiParameter("search", str, description="Parte do nome."),
            *PAGE_PARAMETERS,
        ],
        responses={200: page_response("ProductPage", s.ProductSerializer), 401: ErrorSerializer},
    )
    def list(self, request):
        query = parse_query(s.ProductQuerySerializer, request)
        items = sorted(_all("products"), key=lambda p: normalize(p["name"]))
        if query.get("kind"):
            items = [p for p in items if p["kind"] == query["kind"]]
        if query.get("search"):
            term = normalize(query["search"])
            items = [p for p in items if term in normalize(p["name"])]
        page = paginate(items, query["page"], query["page_size"])
        page["results"] = s.ProductSerializer(page["results"], many=True).data
        return Response(page)

    @extend_schema(
        tags=["Catálogo"],
        summary="Detalhar produto",
        parameters=[OpenApiParameter("id", str, OpenApiParameter.PATH)],
        responses={200: s.ProductSerializer, 404: ErrorSerializer},
    )
    def retrieve(self, request, id=None):
        return Response(s.ProductSerializer(_one("products", id)).data)


class ArticleViewSet(viewsets.ViewSet):
    lookup_field = "id"
    lookup_value_regex = r"[a-z0-9-]+"

    @extend_schema(
        tags=["Artigos"],
        summary="Listar artigos educativos",
        parameters=[
            OpenApiParameter("tag", str, description="Filtra por tag (ex.: creatina, whey, sono)."),
            OpenApiParameter("search", str, description="Parte do título ou resumo."),
            *PAGE_PARAMETERS,
        ],
        responses={200: page_response("ArticlePage", s.ArticleSummarySerializer), 401: ErrorSerializer},
    )
    def list(self, request):
        query = parse_query(s.ArticleQuerySerializer, request)
        items = sorted(_all("articles"), key=lambda a: (a["published_at"], a["title"]), reverse=True)
        if query.get("tag"):
            items = [a for a in items if normalize(query["tag"]) in a["tags"]]
        if query.get("search"):
            term = normalize(query["search"])
            items = [a for a in items if term in normalize(f"{a['title']} {a['summary']}")]
        page = paginate(items, query["page"], query["page_size"])
        page["results"] = s.ArticleSummarySerializer(page["results"], many=True).data
        return Response(page)

    @extend_schema(
        tags=["Artigos"],
        summary="Ler artigo",
        parameters=[OpenApiParameter("id", str, OpenApiParameter.PATH)],
        responses={200: s.ArticleSerializer, 404: ErrorSerializer},
    )
    def retrieve(self, request, id=None):
        return Response(s.ArticleSerializer(_one("articles", id)).data)
