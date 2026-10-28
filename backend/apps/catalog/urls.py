from rest_framework.routers import SimpleRouter

from apps.catalog import views

router = SimpleRouter()
router.register("products", views.ProductViewSet, basename="product")
router.register("articles", views.ArticleViewSet, basename="article")

urlpatterns = router.urls
