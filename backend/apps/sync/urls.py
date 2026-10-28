from django.urls import path, re_path

from apps.core.resources import ID_PATTERN
from apps.sync import views

urlpatterns = [
    path("policy/", views.SyncPolicyView.as_view(), name="sync-policy"),
    path("consent/", views.SyncConsentView.as_view(), name="sync-consent"),
    path("keys/", views.SyncKeyView.as_view(), name="sync-keys"),
    path("events/", views.SyncEventsView.as_view(), name="sync-events"),
    path("batches/", views.SyncBatchView.as_view(), name="sync-batches"),
    re_path(rf"^batches/(?P<batch_id>{ID_PATTERN})/$", views.SyncBatchStatusView.as_view(), name="sync-batch-status"),
    # Monitoramento (custom claim admin)
    path("admin/events/", views.AdminSyncEventsView.as_view(), name="admin-sync-events"),
    path("admin/summary/", views.AdminSyncSummaryView.as_view(), name="admin-sync-summary"),
]
