from rest_framework.routers import SimpleRouter

from tracking import views

router = SimpleRouter(trailing_slash=False)
router.register("routine-items", views.RoutineItemViewSet, basename="routine-item")
router.register("doses", views.DoseLogViewSet, basename="dose")
router.register("symptoms", views.SymptomLogViewSet, basename="symptom")
router.register("hydration", views.HydrationLogViewSet, basename="hydration")

urlpatterns = router.urls
