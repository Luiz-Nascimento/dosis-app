from __future__ import annotations

import re

from rest_framework import serializers


def validate_password_policy(value: str) -> str:
    """Regras da tela de cadastro (Figma): 8+ caracteres, uma letra e um número."""
    errors = []
    if len(value) < 8:
        errors.append("A senha precisa ter 8 ou mais caracteres.")
    if not re.search(r"[A-Za-zÀ-ÿ]", value):
        errors.append("A senha precisa ter pelo menos uma letra.")
    if not re.search(r"\d", value):
        errors.append("A senha precisa ter pelo menos um número.")
    if errors:
        raise serializers.ValidationError(errors)
    return value


def validate_terms(value: bool) -> bool:
    if value is not True:
        raise serializers.ValidationError("É preciso aceitar os termos de uso.")
    return value


class AuthSessionSerializer(serializers.Serializer):
    uid = serializers.CharField()
    id_token = serializers.CharField(help_text="Envie em `Authorization: Bearer <id_token>`.")
    refresh_token = serializers.CharField(help_text="Use em /api/v1/auth/refresh/ quando o id_token expirar.")
    expires_in = serializers.IntegerField(help_text="Validade do id_token em segundos.")
    is_anonymous = serializers.BooleanField()
    email = serializers.EmailField(allow_null=True)
    name = serializers.CharField(allow_null=True)
    email_verified = serializers.BooleanField()


class MeSerializer(serializers.Serializer):
    uid = serializers.CharField()
    email = serializers.EmailField(allow_null=True)
    name = serializers.CharField(allow_null=True)
    is_anonymous = serializers.BooleanField()
    email_verified = serializers.BooleanField()


class RegisterSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=60, help_text="Como você quer ser chamado?")
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, validators=[validate_password_policy])
    accept_terms = serializers.BooleanField(validators=[validate_terms])


class LinkAccountSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=60, required=False, allow_blank=True)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, validators=[validate_password_policy])
    accept_terms = serializers.BooleanField(validators=[validate_terms])


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)


class RefreshSerializer(serializers.Serializer):
    refresh_token = serializers.CharField()


class EmailSerializer(serializers.Serializer):
    email = serializers.EmailField()


class OobCodeSerializer(serializers.Serializer):
    oob_code = serializers.CharField(help_text="Código `oobCode` que chega no link do e-mail.")


class PasswordResetConfirmSerializer(serializers.Serializer):
    oob_code = serializers.CharField(help_text="Código `oobCode` que chega no link do e-mail.")
    new_password = serializers.CharField(write_only=True, validators=[validate_password_policy])
