from django.urls import path, re_path

from apps.backups import views
from apps.core.resources import ID_PATTERN

BACKUP = rf"(?P<backup_id>{ID_PATTERN})"

urlpatterns = [
    path("", views.BackupListView.as_view(), name="backups"),
    path("restore/", views.BackupRestoreFileView.as_view(), name="backup-restore-file"),
    re_path(rf"^{BACKUP}/$", views.BackupDetailView.as_view(), name="backup-detail"),
    re_path(rf"^{BACKUP}/download/$", views.BackupDownloadView.as_view(), name="backup-download"),
    re_path(rf"^{BACKUP}/restore/$", views.BackupRestoreView.as_view(), name="backup-restore"),
]
