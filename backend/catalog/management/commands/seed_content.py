from django.core.management.base import BaseCommand

from catalog.seed import seed_content
from core.store import get_store


class Command(BaseCommand):
    help = "Grava o catálogo de produtos e os artigos educativos no Firestore."

    def add_arguments(self, parser):
        parser.add_argument(
            "--overwrite", action="store_true", help="Sobrescreve documentos que já existem."
        )

    def handle(self, *args, **options):
        written = seed_content(get_store(), overwrite=options["overwrite"])
        self.stdout.write(self.style.SUCCESS(f"{written} documento(s) gravado(s)."))
