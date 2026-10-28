"""Base dos CRUDs das coleções do usuário (``users/{uid}/<coleção>``).

Cada recurso declara um repositório (coleção, campos cifrados, campo de
ordenação) e um ViewSet (serializer e filtros). O repositório cuida do
Firestore e da criptografia; o ViewSet cuida do HTTP.

Os ids podem ser gerados pelo app (UUID): assim um registro criado offline
mantém o mesmo id quando chega ao servidor, sem duplicar.
"""
from __future__ import annotations

import datetime as dt
from typing import Any, Iterable
from zoneinfo import ZoneInfo

from django.conf import settings
from drf_spectacular.utils import OpenApiParameter, extend_schema, extend_schema_view, inline_serializer
from rest_framework import serializers, status, viewsets
from rest_framework.exceptions import APIException, NotFound, ValidationError
from rest_framework.response import Response

from apps.core.crypto import decrypt_fields, encrypt_fields
from apps.core.fields import utcnow
from apps.core.schema import ErrorSerializer
from apps.core.store import DocumentAlreadyExists, DocumentStore, get_store, new_id, user_collection, user_doc

ID_PATTERN = r"[A-Za-z0-9_-]{8,64}"
DEFAULT_LIMIT = 100
MAX_LIMIT = 500


class Conflict(APIException):
    status_code = status.HTTP_409_CONFLICT
    default_code = "already_exists"
    default_detail = "Já existe um registro com este id."


class RecordNotFound(NotFound):
    default_code = "not_found"
    default_detail = "Registro não encontrado."


class UserCollectionRepository:
    collection: str = ""
    encrypted_fields: tuple[str, ...] = ()
    order_field: str = "created_at"

    def __init__(self, uid: str, store: DocumentStore | None = None):
        self.uid = uid
        self.store = store or get_store()

    def path(self, item_id: str) -> str:
        return user_doc(self.uid, self.collection, item_id)

    def collection_path(self) -> str:
        return user_collection(self.uid, self.collection)

    def to_storage(self, item_id: str, data: dict[str, Any]) -> dict[str, Any]:
        return encrypt_fields(self.path(item_id), data, self.encrypted_fields)

    def from_storage(self, item_id: str, data: dict[str, Any]) -> dict[str, Any]:
        return {"id": item_id, **decrypt_fields(self.path(item_id), data, self.encrypted_fields)}

    def get(self, item_id: str) -> dict[str, Any] | None:
        data = self.store.get(self.path(item_id))
        return None if data is None else self.from_storage(item_id, data)

    def list(
        self,
        where: Iterable[tuple[str, str, Any]] = (),
        order_by: Iterable[tuple[str, str]] | None = None,
        limit: int | None = None,
    ) -> list[dict[str, Any]]:
        order = list(order_by) if order_by is not None else [(self.order_field, "desc")]
        docs = self.store.list(self.collection_path(), where=where, order_by=order, limit=limit)
        return [self.from_storage(d.id, d.data) for d in docs]

    # ``modified_at`` registra quando a mudança aconteceu de fato (no aparelho,
    # para registros sincronizados offline). O sync usa esse campo para decidir
    # qual versão vale quando mudanças chegam fora de ordem.

    def storage_for_create(
        self, item_id: str, data: dict[str, Any], modified_at: dt.datetime | None = None
    ) -> dict[str, Any]:
        now = utcnow()
        record = {**data, "created_at": now, "updated_at": now, "modified_at": modified_at or now}
        return self.to_storage(item_id, record)

    def storage_for_update(
        self, item_id: str, data: dict[str, Any], modified_at: dt.datetime | None = None
    ) -> dict[str, Any]:
        now = utcnow()
        return self.to_storage(item_id, {**data, "updated_at": now, "modified_at": modified_at or now})

    def create(self, data: dict[str, Any], item_id: str | None = None) -> dict[str, Any]:
        item_id = item_id or new_id()
        record = self.storage_for_create(item_id, data)
        try:
            self.store.create(self.path(item_id), record)
        except DocumentAlreadyExists as exc:
            raise Conflict() from exc
        return self.from_storage(item_id, record)

    def update(self, item_id: str, data: dict[str, Any]) -> dict[str, Any]:
        path = self.path(item_id)
        changes = self.storage_for_update(item_id, data)

        def work(tx):
            if tx.get(path) is None:
                raise RecordNotFound()
            tx.set(path, changes, merge=True)

        self.store.run_transaction(work)
        return self.get(item_id)

    def delete(self, item_id: str) -> None:
        path = self.path(item_id)

        def work(tx):
            if tx.get(path) is None:
                raise RecordNotFound()
            tx.delete(path)

        self.store.run_transaction(work)


def local_zone() -> ZoneInfo:
    return ZoneInfo(settings.TIME_ZONE)


def local_date_of(moment: dt.datetime) -> str:
    """Dia (no fuso do app) em que algo aconteceu, usado no calendário de registros."""
    return moment.astimezone(local_zone()).date().isoformat()


def day_bounds(start: dt.date | None, end: dt.date | None) -> tuple[dt.datetime | None, dt.datetime | None]:
    """Converte um intervalo de dias locais em instantes UTC [início, fim)."""
    zone = local_zone()
    lower = dt.datetime.combine(start, dt.time.min, zone) if start else None
    upper = dt.datetime.combine(end + dt.timedelta(days=1), dt.time.min, zone) if end else None
    return lower, upper


class DateRangeQuerySerializer(serializers.Serializer):
    date_from = serializers.DateField(required=False, help_text="Primeiro dia (AAAA-MM-DD), inclusive.")
    date_to = serializers.DateField(required=False, help_text="Último dia (AAAA-MM-DD), inclusive.")
    limit = serializers.IntegerField(required=False, min_value=1, max_value=MAX_LIMIT, default=DEFAULT_LIMIT)

    def validate(self, attrs):
        if attrs.get("date_from") and attrs.get("date_to") and attrs["date_from"] > attrs["date_to"]:
            raise ValidationError({"date_from": "Deve ser anterior ou igual a date_to."})
        return attrs


DATE_RANGE_PARAMETERS = [
    OpenApiParameter("date_from", dt.date, description="Primeiro dia (AAAA-MM-DD), inclusive."),
    OpenApiParameter("date_to", dt.date, description="Último dia (AAAA-MM-DD), inclusive."),
    OpenApiParameter("limit", int, description=f"Máximo de registros (padrão {DEFAULT_LIMIT}, máximo {MAX_LIMIT})."),
]


def parse_query(serializer_class, request) -> dict[str, Any]:
    serializer = serializer_class(data=request.query_params)
    serializer.is_valid(raise_exception=True)
    return serializer.validated_data


class UserCollectionViewSet(viewsets.ViewSet):
    """CRUD genérico. Subclasses definem ``repository_class`` e ``serializer_class``."""

    repository_class: type[UserCollectionRepository]
    serializer_class: type[serializers.Serializer]
    lookup_field = "id"
    lookup_value_regex = ID_PATTERN

    def repository(self) -> UserCollectionRepository:
        return self.repository_class(self.request.user.uid)

    def get_serializer(self, *args, **kwargs):
        kwargs.setdefault("context", {"request": self.request, "view": self, "uid": self.request.user.uid})
        return self.serializer_class(*args, **kwargs)

    # Ganchos para as subclasses ------------------------------------------------

    def list_query(self, request) -> dict[str, Any]:
        return {}

    def prepare_create(self, data: dict[str, Any]) -> dict[str, Any]:
        return data

    def prepare_update(self, existing: dict[str, Any], data: dict[str, Any]) -> dict[str, Any]:
        return data

    # Ações ---------------------------------------------------------------------

    def list(self, request):
        items = self.repository().list(**self.list_query(request))
        return Response({"results": self.get_serializer(items, many=True).data})

    def create(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = dict(serializer.validated_data)
        item_id = data.pop("id", None)
        item = self.repository().create(self.prepare_create(data), item_id)
        return Response(self.get_serializer(item).data, status=status.HTTP_201_CREATED)

    def retrieve(self, request, id=None):
        return Response(self.get_serializer(self._get_or_404(id)).data)

    def partial_update(self, request, id=None):
        existing = self._get_or_404(id)
        serializer = self.get_serializer(instance=existing, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        data = dict(serializer.validated_data)
        data.pop("id", None)
        item = self.repository().update(id, self.prepare_update(existing, data))
        return Response(self.get_serializer(item).data)

    def destroy(self, request, id=None):
        self.repository().delete(id)
        return Response(status=status.HTTP_204_NO_CONTENT)

    def _get_or_404(self, item_id: str) -> dict[str, Any]:
        item = self.repository().get(item_id)
        if item is None:
            raise RecordNotFound()
        return item


def crud_schema(tag: str, serializer, noun: str, list_parameters=(), list_description: str = ""):
    """Documentação Swagger padrão de um UserCollectionViewSet."""
    item_id = OpenApiParameter("id", str, OpenApiParameter.PATH, description="Id do registro.")
    list_response = inline_serializer(f"{serializer.__name__.removesuffix('Serializer')}List", {
        "results": serializer(many=True),
    })
    errors = {400: ErrorSerializer, 401: ErrorSerializer}
    return extend_schema_view(
        list=extend_schema(tags=[tag], summary=f"Listar {noun}", description=list_description,
                           parameters=list(list_parameters), responses={200: list_response, **errors}),
        create=extend_schema(tags=[tag], summary=f"Criar {noun}",
                             description="O campo `id` é opcional: o app pode enviar o UUID gerado offline.",
                             request=serializer, responses={201: serializer, 409: ErrorSerializer, **errors}),
        retrieve=extend_schema(tags=[tag], summary=f"Detalhar {noun}", parameters=[item_id],
                               responses={200: serializer, 404: ErrorSerializer, 401: ErrorSerializer}),
        partial_update=extend_schema(tags=[tag], summary=f"Editar {noun}", parameters=[item_id],
                                     request=serializer, responses={200: serializer, 404: ErrorSerializer, **errors}),
        destroy=extend_schema(tags=[tag], summary=f"Excluir {noun}", parameters=[item_id],
                              responses={204: None, 404: ErrorSerializer, 401: ErrorSerializer}),
    )
