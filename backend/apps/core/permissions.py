from rest_framework.permissions import BasePermission


class IsAdmin(BasePermission):
    """Conta com a custom claim ``admin: true`` no Firebase (veja ``manage.py set_admin``)."""

    message = "Acesso restrito à equipe do Dosis."

    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.claims.get("admin") is True)
