from rest_framework import serializers

RESTORE_MODES = [
    ("merge", "Mesclar: atualiza os registros do backup e mantém os demais"),
    ("replace", "Substituir: apaga os registros atuais e deixa só os do backup"),
]
REASON_CHOICES = [("manual", "Criado pelo usuário"), ("pre_restore", "Automático, antes de uma restauração")]


class BackupCreateSerializer(serializers.Serializer):
    passphrase = serializers.CharField(
        required=False, write_only=True, min_length=8, max_length=128,
        help_text=(
            "Opcional. Com senha, nem o servidor abre o backup sem ela, e o arquivo pode ser restaurado "
            "em outra conta. Se esquecer a senha, o backup não tem como ser recuperado."
        ),
    )


class BackupSerializer(serializers.Serializer):
    id = serializers.CharField()
    created_at = serializers.DateTimeField()
    reason = serializers.ChoiceField(REASON_CHOICES)
    protected = serializers.BooleanField(help_text="true = protegido por senha do usuário.")
    counts = serializers.DictField(child=serializers.IntegerField(), help_text="Registros por coleção.")
    size_bytes = serializers.IntegerField()
    sha256 = serializers.CharField(help_text="Hash do conteúdo cifrado, para conferir o arquivo baixado.")


class KdfSerializer(serializers.Serializer):
    name = serializers.ChoiceField([("server-hkdf", "Chave do servidor"), ("scrypt", "Senha do usuário")])
    salt = serializers.CharField()
    n = serializers.IntegerField(required=False)
    r = serializers.IntegerField(required=False)
    p = serializers.IntegerField(required=False)


class BackupFileSerializer(serializers.Serializer):
    format = serializers.CharField()
    version = serializers.IntegerField()
    backup_id = serializers.CharField(max_length=64)
    protected = serializers.BooleanField()
    algorithm = serializers.CharField()
    compression = serializers.CharField()
    kdf = KdfSerializer()
    nonce = serializers.CharField(max_length=32)
    ciphertext = serializers.CharField(help_text="base64url(AES-256-GCM(gzip(JSON)))")


class RestoreSerializer(serializers.Serializer):
    mode = serializers.ChoiceField(RESTORE_MODES, default="merge")
    passphrase = serializers.CharField(required=False, write_only=True, max_length=128)


class RestoreFileSerializer(RestoreSerializer):
    file = BackupFileSerializer(help_text="Conteúdo do arquivo baixado em /api/v1/backups/{id}/download/.")


class RestoreResultSerializer(serializers.Serializer):
    mode = serializers.ChoiceField(RESTORE_MODES)
    restored = serializers.DictField(child=serializers.IntegerField())
    safety_backup_id = serializers.CharField(
        help_text="Backup automático do estado anterior. Restaure-o para desfazer."
    )
