from rest_framework.routers import SimpleRouter

from catalog import views

router = SimpleRouter(trailing_slash=False)
router.register("products", views.ProductViewSet, basename="product")
router.register("articles", views.ArticleViewSet, basename="article")

urlpatterns = router.urls
