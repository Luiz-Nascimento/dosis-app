"""Validação dos registros do usuário: rotina (stack), doses, sintomas e água.

Os serializers recebem ``uid`` no contexto para validar referências (item da
rotina, produto do catálogo) e completar dados: ao registrar uma dose só com
``routine_item_id``, nome, dose, unidade e protocolo vêm do item da rotina
(fluxo de 3 toques do Figma).
"""
from __future__ import annotations

from typing import Any

from django.utils import timezone
from rest_framework import serializers

from core.choices import KIND_CHOICES, PROTOCOL_CHOICES, SYMPTOM_CHOICES, SYMPTOM_STATUS_CHOICES, UNIT_CHOICES
from core.fields import IsoDateField, TimeOfDayField
from core.resources import ID_PATTERN, local_date_of
from core.store import get_store

from .repositories import RoutineItemRepository

ID_FIELD = dict(
    regex=rf"^{ID_PATTERN}$",
    required=False,
    help_text="Opcional na criação: UUID gerado pelo app (offline-first).",
)


class TrackingSerializer(serializers.Serializer):
    id = serializers.RegexField(**ID_FIELD)
    created_at = serializers.DateTimeField(read_only=True)
    updated_at = serializers.DateTimeField(read_only=True)

    @property
    def uid(self) -> str:
        return self.context["uid"]

    def to_representation(self, instance):
        # Campos opcionais ausentes saem como null: o app sempre recebe o mesmo formato.
        if isinstance(instance, dict):
            instance = {**dict.fromkeys(self.fields), **instance}
        return super().to_representation(instance)

    def merged(self, attrs: dict[str, Any]) -> dict[str, Any]:
        """Estado final do registro (útil em edições parciais)."""
        return {**(self.instance or {}), **attrs}

    @staticmethod
    def require(data: dict[str, Any], *fields: str) -> None:
        missing = {f: "Este campo é obrigatório." for f in fields if data.get(f) in (None, "")}
        if missing:
            raise serializers.ValidationError(missing)


def get_product(product_id: str) -> dict[str, Any]:
    product = get_store().get(f"products/{product_id}")
    if product is None:
        raise serializers.ValidationError({"product_id": "Produto não encontrado no catálogo."})
    return product


class RoutineItemSerializer(TrackingSerializer):
    product_id = serializers.CharField(
        required=False, allow_null=True, max_length=60,
        help_text="Id do catálogo (/products). Nulo para item cadastrado à mão (\"Adicionar outro\").",
    )
    name = serializers.CharField(required=False, max_length=80, help_text="Padrão: nome do produto.")
    brand = serializers.CharField(required=False, allow_null=True, allow_blank=True, max_length=60)
    kind = serializers.ChoiceField(KIND_CHOICES, required=False, help_text="Padrão: tipo do produto.")
    protocol = serializers.ChoiceField(PROTOCOL_CHOICES, required=False, help_text="Padrão: continuous.")
    dose_amount = serializers.FloatField(required=False, allow_null=True, min_value=0, max_value=100000)
    dose_unit = serializers.ChoiceField(UNIT_CHOICES, required=False, help_text="Padrão: unidade do produto.")
    schedule_times = serializers.ListField(
        child=TimeOfDayField(), required=False, max_length=12, help_text="Horários do lembrete (HH:MM)."
    )
    start_date = IsoDateField(required=False, allow_null=True)
    end_date = IsoDateField(required=False, allow_null=True)
    active = serializers.BooleanField(required=False, help_text="Itens ativos aparecem no \"Stack de hoje\".")
    notes = serializers.CharField(required=False, allow_null=True, allow_blank=True, max_length=500)

    def validate(self, attrs):
        if self.instance is None:
            if attrs.get("product_id"):
                product = get_product(attrs["product_id"])
                attrs.setdefault("name", product["name"])
                attrs.setdefault("kind", product["kind"])
                attrs.setdefault("dose_unit", product["default_unit"])
                attrs.setdefault("dose_amount", product.get("default_dose"))
            attrs.setdefault("protocol", "continuous")
            attrs.setdefault("active", True)
            attrs.setdefault("schedule_times", [])
        elif attrs.get("product_id") and attrs["product_id"] != self.instance.get("product_id"):
            get_product(attrs["product_id"])

        data = self.merged(attrs)
        self.require(data, "name", "kind", "dose_unit")
        if data.get("start_date") and data.get("end_date") and data["end_date"] < data["start_date"]:
            raise serializers.ValidationError({"end_date": "Deve ser igual ou posterior a start_date."})
        if "schedule_times" in attrs:
            attrs["schedule_times"] = sorted(set(attrs["schedule_times"]))
        return attrs


class DoseLogSerializer(TrackingSerializer):
    routine_item_id = serializers.RegexField(
        rf"^{ID_PATTERN}$", required=False, allow_null=True,
        help_text="Item do stack. Basta enviar só ele: o resto é preenchido a partir do item.",
    )
    product_id = serializers.CharField(required=False, allow_null=True, max_length=60)
    name = serializers.CharField(required=False, max_length=80)
    kind = serializers.ChoiceField(KIND_CHOICES, required=False)
    protocol = serializers.ChoiceField(PROTOCOL_CHOICES, required=False)
    amount = serializers.FloatField(required=False, min_value=0, max_value=100000)
    unit = serializers.ChoiceField(UNIT_CHOICES, required=False)
    taken_at = serializers.DateTimeField(required=False, help_text="Padrão: agora.")
    local_date = IsoDateField(required=False, help_text="Dia do registro no calendário. Padrão: dia de taken_at.")
    notes = serializers.CharField(required=False, allow_null=True, allow_blank=True, max_length=500)

    def validate(self, attrs):
        if self.instance is None:
            attrs.setdefault("taken_at", timezone.now())
            if attrs.get("routine_item_id"):
                item = RoutineItemRepository(self.uid).get(attrs["routine_item_id"])
                if item is None:
                    raise serializers.ValidationError({"routine_item_id": "Item da rotina não encontrado."})
                attrs.setdefault("product_id", item.get("product_id"))
                attrs.setdefault("name", item["name"])
                attrs.setdefault("kind", item["kind"])
                attrs.setdefault("protocol", item.get("protocol", "continuous"))
                attrs.setdefault("unit", item["dose_unit"])
                if item.get("dose_amount") is not None:
                    attrs.setdefault("amount", item["dose_amount"])
            attrs.setdefault("protocol", "continuous")
        if "taken_at" in attrs and "local_date" not in attrs:
            attrs["local_date"] = local_date_of(attrs["taken_at"])

        self.require(self.merged(attrs), "name", "kind", "amount", "unit")
        return attrs


class SymptomLogSerializer(TrackingSerializer):
    status = serializers.ChoiceField(
        SYMPTOM_STATUS_CHOICES, required=False, help_text="normal = \"Não senti nada de diferente\"."
    )
    symptoms = serializers.ListField(
        child=serializers.ChoiceField(SYMPTOM_CHOICES), required=False, max_length=len(SYMPTOM_CHOICES),
        help_text="Pode marcar mais de um. Obrigatório quando status=different.",
    )
    other_description = serializers.CharField(
        required=False, allow_null=True, allow_blank=True, max_length=120,
        help_text="Obrigatório quando symptoms inclui \"other\".",
    )
    notes = serializers.CharField(required=False, allow_null=True, allow_blank=True, max_length=500)
    logged_at = serializers.DateTimeField(required=False, help_text="Padrão: agora.")
    local_date = IsoDateField(required=False)

    def validate(self, attrs):
        if self.instance is None:
            attrs.setdefault("logged_at", timezone.now())
            attrs.setdefault("symptoms", [])
        if "symptoms" in attrs:
            attrs["symptoms"] = list(dict.fromkeys(attrs["symptoms"]))
        if "logged_at" in attrs and "local_date" not in attrs:
            attrs["local_date"] = local_date_of(attrs["logged_at"])

        data = self.merged(attrs)
        self.require(data, "status")
        symptoms = data.get("symptoms") or []
        if data["status"] == "normal" and symptoms:
            raise serializers.ValidationError({"symptoms": "Deixe vazio quando status=normal."})
        if data["status"] == "different" and not symptoms:
            raise serializers.ValidationError({"symptoms": "Marque pelo menos um sintoma."})
        if "other" in symptoms and not (data.get("other_description") or "").strip():
            raise serializers.ValidationError({"other_description": "Descreva o que você sentiu."})
        if "other" not in symptoms and data.get("other_description"):
            attrs["other_description"] = None
        return attrs


class HydrationLogSerializer(TrackingSerializer):
    amount_ml = serializers.IntegerField(min_value=1, max_value=5000)
    logged_at = serializers.DateTimeField(required=False, help_text="Padrão: agora.")
    local_date = IsoDateField(required=False)

    def validate(self, attrs):
        if self.instance is None:
            attrs.setdefault("logged_at", timezone.now())
        if "logged_at" in attrs and "local_date" not in attrs:
            attrs["local_date"] = local_date_of(attrs["logged_at"])
        return attrs
