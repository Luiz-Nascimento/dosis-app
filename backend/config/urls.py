"""Rotas da API. Cada app recebe sua rota aqui e lista os próprios endpoints em ``apps/<app>/urls.py``."""
from django.urls import include, path
from django.views.generic import RedirectView
from drf_spectacular.views import SpectacularAPIView, SpectacularRedocView, SpectacularSwaggerView

API = 'api/v1/'

urlpatterns = [
    path('', RedirectView.as_view(url='/api/docs/', permanent=False)),
    path(f'{API}system/', include('apps.core.urls')),
    path(f'{API}auth/', include('apps.accounts.urls')),
    path(f'{API}profile/', include('apps.profiles.urls')),
    path(f'{API}catalog/', include('apps.catalog.urls')),
    path(f'{API}tracking/', include('apps.tracking.urls')),
    path(f'{API}sync/', include('apps.sync.urls')),
    path(f'{API}backups/', include('apps.backups.urls')),
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
]
