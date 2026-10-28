from rest_framework import serializers

from apps.core.choices import BIOLOGICAL_SEX_CHOICES, GOAL_CHOICES


class NotificationPreferencesSerializer(serializers.Serializer):
    dose_reminders = serializers.BooleanField(required=False, help_text="Lembrete no horário do stack.")
    symptom_reminder = serializers.BooleanField(required=False, help_text="Lembrete diário \"Como você está hoje?\".")


class ProfileSerializer(serializers.Serializer):
    uid = serializers.CharField(read_only=True)
    email = serializers.EmailField(read_only=True, allow_null=True)
    is_anonymous = serializers.BooleanField(read_only=True)
    name = serializers.CharField(max_length=60, required=False, allow_null=True)
    age = serializers.IntegerField(min_value=10, max_value=120, required=False, allow_null=True)
    weight_kg = serializers.FloatField(min_value=30, max_value=300, required=False, allow_null=True)
    height_cm = serializers.FloatField(min_value=100, max_value=250, required=False, allow_null=True)
    biological_sex = serializers.ChoiceField(BIOLOGICAL_SEX_CHOICES, required=False, allow_null=True)
    goal = serializers.ChoiceField(GOAL_CHOICES, required=False, allow_null=True)
    notifications = NotificationPreferencesSerializer(required=False)
    terms_accepted_at = serializers.DateTimeField(read_only=True, allow_null=True)
    created_at = serializers.DateTimeField(read_only=True, allow_null=True)
    updated_at = serializers.DateTimeField(read_only=True, allow_null=True)
