from django.apps import AppConfig


class CoreConfig(AppConfig):
    name = 'core'

    def ready(self):
        from core import schema  # noqa: F401  (registra a autenticação no Swagger)
