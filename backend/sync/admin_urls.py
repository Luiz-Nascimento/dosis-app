from django.urls import path

from sync import views

urlpatterns = [
    path("events", views.AdminSyncEventsView.as_view(), name="admin-sync-events"),
    path("summary", views.AdminSyncSummaryView.as_view(), name="admin-sync-summary"),
]
