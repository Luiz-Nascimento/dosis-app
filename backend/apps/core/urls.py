from django.urls import path

from apps.core import views

urlpatterns = [
    path("health/", views.HealthView.as_view(), name="health"),
    path("diagnostics/firestore/", views.FirestoreCheckView.as_view(), name="diagnostics-firestore"),
]
