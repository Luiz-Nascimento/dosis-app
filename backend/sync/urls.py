from django.urls import path, re_path

from core.resources import ID_PATTERN
from sync import views

urlpatterns = [
    path("policy", views.SyncPolicyView.as_view(), name="sync-policy"),
    path("consent", views.SyncConsentView.as_view(), name="sync-consent"),
    path("keys", views.SyncKeyView.as_view(), name="sync-keys"),
    path("batches", views.SyncBatchView.as_view(), name="sync-batches"),
    re_path(rf"^batches/(?P<batch_id>{ID_PATTERN})$", views.SyncBatchStatusView.as_view(), name="sync-batch-status"),
]
