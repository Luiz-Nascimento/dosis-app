from django.apps import AppConfig


class CoreConfig(AppConfig):
    name = 'apps.core'

    def ready(self):
        from apps.core import schema  # noqa: F401  (registra a autenticação no Swagger)
