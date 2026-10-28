from django.urls import path

from sync import views

urlpatterns = [
    path("policy", views.SyncPolicyView.as_view(), name="sync-policy"),
    path("batches", views.SyncBatchView.as_view(), name="sync-batches"),
]
