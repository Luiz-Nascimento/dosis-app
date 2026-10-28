from django.urls import include, path
from django.views.generic import RedirectView
from drf_spectacular.views import SpectacularAPIView, SpectacularRedocView, SpectacularSwaggerView

urlpatterns = [
    path('', RedirectView.as_view(url='/api/docs/', permanent=False)),
    path('api/v1/', include('core.urls')),
    path('api/v1/auth/', include('accounts.urls')),
    path('api/v1/', include('profiles.urls')),
    path('api/v1/', include('catalog.urls')),
    path('api/v1/', include('tracking.urls')),
    path('api/v1/sync/', include('sync.urls')),
    path('api/v1/admin/sync/', include('sync.admin_urls')),
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
]
