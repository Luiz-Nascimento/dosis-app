from django.apps import AppConfig


class CatalogConfig(AppConfig):
    name = 'apps.catalog'

    def ready(self):
        from apps.core.store import register_mock_seeder

        from .seed import seed_content

        # No modo mock o catálogo e os artigos já nascem populados.
        register_mock_seeder(seed_content)
