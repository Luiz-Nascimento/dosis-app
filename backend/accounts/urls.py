from django.urls import path

from accounts import views

urlpatterns = [
    path("anonymous", views.AnonymousView.as_view(), name="auth-anonymous"),
    path("register", views.RegisterView.as_view(), name="auth-register"),
    path("login", views.LoginView.as_view(), name="auth-login"),
    path("refresh", views.RefreshView.as_view(), name="auth-refresh"),
    path("link", views.LinkAccountView.as_view(), name="auth-link"),
    path("me", views.MeView.as_view(), name="auth-me"),
    path("verify-email", views.VerifyEmailView.as_view(), name="auth-verify-email"),
    path("verify-email/confirm", views.VerifyEmailConfirmView.as_view(), name="auth-verify-email-confirm"),
    path("password-reset", views.PasswordResetView.as_view(), name="auth-password-reset"),
    path("password-reset/confirm", views.PasswordResetConfirmView.as_view(), name="auth-password-reset-confirm"),
]
