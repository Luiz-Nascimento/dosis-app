from django.urls import path

from profiles import views

urlpatterns = [
    path("profile", views.ProfileView.as_view(), name="profile"),
]
