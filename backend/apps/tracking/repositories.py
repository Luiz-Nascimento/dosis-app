from apps.core.resources import UserCollectionRepository


class RoutineItemRepository(UserCollectionRepository):
    """Itens do stack: ``users/{uid}/routine_items/{id}``."""

    collection = "routine_items"
    encrypted_fields = ("notes",)
    order_field = "created_at"


class DoseLogRepository(UserCollectionRepository):
    """Doses registradas: ``users/{uid}/dose_logs/{id}``.

    Guarda uma cópia de nome, tipo e unidade do item da rotina, para o
    histórico continuar legível mesmo se o item for editado ou excluído.
    """

    collection = "dose_logs"
    encrypted_fields = ("amount", "notes")
    order_field = "taken_at"


class SymptomLogRepository(UserCollectionRepository):
    """Registros de "Como você se sentiu": ``users/{uid}/symptom_logs/{id}``."""

    collection = "symptom_logs"
    encrypted_fields = ("symptoms", "other_description", "notes")
    order_field = "logged_at"


class HydrationLogRepository(UserCollectionRepository):
    """Água ingerida: ``users/{uid}/hydration_logs/{id}``."""

    collection = "hydration_logs"
    order_field = "logged_at"
