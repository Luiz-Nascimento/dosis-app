from django.urls import path

from apps.profiles import views

urlpatterns = [
    path("", views.ProfileView.as_view(), name="profile"),
]
