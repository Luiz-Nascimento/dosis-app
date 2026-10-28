from rest_framework import serializers

from apps.core.choices import KIND_CHOICES, PROTOCOL_CHOICES, UNIT_CHOICES
from apps.core.pagination import PageQuerySerializer


class SourceSerializer(serializers.Serializer):
    id = serializers.CharField()
    name = serializers.CharField(help_text="Sigla exibida no alerta (ANVISA, SBEM, ISSN...).")
    citation = serializers.CharField()
    url = serializers.URLField()


class DoseRangeSerializer(serializers.Serializer):
    protocol = serializers.ChoiceField(PROTOCOL_CHOICES)
    per = serializers.ChoiceField([("day", "por dia"), ("dose", "por tomada")])
    min = serializers.FloatField()
    max = serializers.FloatField()
    unit = serializers.ChoiceField(UNIT_CHOICES)
    note = serializers.CharField()
    sources = SourceSerializer(many=True)


class ProductSerializer(serializers.Serializer):
    id = serializers.CharField()
    name = serializers.CharField()
    kind = serializers.ChoiceField(KIND_CHOICES)
    default_unit = serializers.ChoiceField(UNIT_CHOICES)
    default_dose = serializers.FloatField(allow_null=True)
    dose_ranges = DoseRangeSerializer(
        many=True, help_text="Faixas usuais por protocolo. Vazio quando não há faixa de referência."
    )
    caution = serializers.CharField(help_text="Texto de cuidado, sem alarmismo, para exibir no app.")
    requires_medical_supervision = serializers.BooleanField()
    sources = SourceSerializer(many=True)


class ProductQuerySerializer(PageQuerySerializer):
    kind = serializers.ChoiceField(KIND_CHOICES, required=False)
    search = serializers.CharField(required=False, max_length=60)


class ArticleSummarySerializer(serializers.Serializer):
    id = serializers.CharField()
    title = serializers.CharField()
    summary = serializers.CharField()
    tags = serializers.ListField(child=serializers.CharField())
    reading_minutes = serializers.IntegerField()
    published_at = serializers.CharField()


class ArticleSerializer(ArticleSummarySerializer):
    body = serializers.CharField(help_text="Texto em Markdown.")
    sources = SourceSerializer(many=True)


class ArticleQuerySerializer(PageQuerySerializer):
    tag = serializers.CharField(required=False, max_length=40)
    search = serializers.CharField(required=False, max_length=60)
