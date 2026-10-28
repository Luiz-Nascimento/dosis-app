from django.core.management.base import BaseCommand

from apps.core.auth import get_auth_provider


class Command(BaseCommand):
    help = "Dá (ou tira) acesso aos endpoints de monitoramento via custom claim admin."

    def add_arguments(self, parser):
        parser.add_argument("uid", help="uid da conta no Firebase Auth.")
        parser.add_argument("--revoke", action="store_true", help="Remove o acesso de admin.")

    def handle(self, *args, **options):
        claims = {} if options["revoke"] else {"admin": True}
        get_auth_provider().set_custom_claims(options["uid"], claims)
        action = "removido de" if options["revoke"] else "concedido a"
        self.stdout.write(self.style.SUCCESS(
            f"Acesso de admin {action} {options['uid']}. Vale a partir do próximo /auth/refresh."
        ))
