"""Extensões do drf-spectacular (Swagger)."""
from drf_spectacular.extensions import OpenApiAuthenticationExtension
from rest_framework import serializers


class FirebaseAuthenticationScheme(OpenApiAuthenticationExtension):
    target_class = "core.authentication.FirebaseAuthentication"
    name = "FirebaseIdToken"

    def get_security_definition(self, auto_schema):
        return {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "Firebase ID token",
            "description": "Cole o `id_token` retornado por /api/v1/auth/anonymous, /login ou /register.",
        }


class ErrorBodySerializer(serializers.Serializer):
    code = serializers.CharField(help_text="Código estável para o app tratar o erro.")
    message = serializers.CharField(help_text="Mensagem pronta para exibir ao usuário.")
    details = serializers.JSONField(allow_null=True, help_text="Erros por campo (validação) ou null.")


class ErrorSerializer(serializers.Serializer):
    error = ErrorBodySerializer()
