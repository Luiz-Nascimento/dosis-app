from drf_spectacular.utils import extend_schema
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.schema import ErrorSerializer

from .repository import ProfileRepository
from .serializers import ProfileSerializer

TAG = "Perfil"


class ProfileView(APIView):
    @extend_schema(
        tags=[TAG],
        summary="Ver perfil (Meus dados, objetivo e notificações)",
        responses={200: ProfileSerializer, 401: ErrorSerializer},
    )
    def get(self, request):
        return Response(ProfileSerializer(ProfileRepository(request.user.uid).get()).data)

    @extend_schema(
        tags=[TAG],
        summary="Editar perfil",
        description=(
            "Envie só os campos alterados. Idade, peso, altura e sexo biológico ficam cifrados no "
            "Firestore. Envie `null` para apagar um dado pessoal."
        ),
        request=ProfileSerializer,
        responses={200: ProfileSerializer, 400: ErrorSerializer, 401: ErrorSerializer},
    )
    def patch(self, request):
        serializer = ProfileSerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        profile = ProfileRepository(request.user.uid).update(dict(serializer.validated_data))
        return Response(ProfileSerializer(profile).data)
