import environ
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env(
    DJANGO_DEBUG=(bool, False),
    DJANGO_ALLOWED_HOSTS=(list, ["localhost", "127.0.0.1", "10.0.2.2"]),
)

env.read_env(BASE_DIR / ".env")

# Em produção, defina DJANGO_SECRET_KEY no .env. O valor padrão serve apenas
# para desenvolvimento local e para os testes.
SECRET_KEY = env("DJANGO_SECRET_KEY", default="django-insecure-dosis-dev-only")

DEBUG = env("DJANGO_DEBUG")

# 10.0.2.2 é o endereço do computador visto de dentro do emulador Android.
ALLOWED_HOSTS = env("DJANGO_ALLOWED_HOSTS")

# Application definition

INSTALLED_APPS = [
    'django.contrib.contenttypes',
    'django.contrib.auth',
    'django.contrib.staticfiles',
    'rest_framework',
    'drf_spectacular',
    'core',
    'accounts',
    'profiles',
    'catalog',
    'tracking',
    'sync',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'


# Database
# Todos os dados do Dosis ficam no Firestore (exigência da disciplina), acessado
# pelo core.store. O Django não usa banco relacional.

DATABASES = {}


# Internationalization
# https://docs.djangoproject.com/en/6.1/topics/i18n/

LANGUAGE_CODE = 'pt-br'

TIME_ZONE = 'America/Sao_Paulo'

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/6.1/howto/static-files/

STATIC_URL = 'static/'


# Email
# https://docs.djangoproject.com/en/6.1/topics/email/#topic-email-configuration

MAILERS = {
    'default': {
        'BACKEND': 'django.core.mail.backends.console.EmailBackend',
    },
}


# Django REST Framework

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'core.authentication.FirebaseAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
    'DEFAULT_PARSER_CLASSES': [
        'rest_framework.parsers.JSONParser',
    ],
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
    'EXCEPTION_HANDLER': 'core.exceptions.exception_handler',
    'UNAUTHENTICATED_USER': None,
    'DEFAULT_THROTTLE_RATES': {
        'auth': env('AUTH_THROTTLE_RATE', default='30/min'),
    },
}

SPECTACULAR_SETTINGS = {
    'TITLE': 'Dosis API',
    'DESCRIPTION': (
        'API do Dosis para o app Flutter. Autenticação via Firebase Auth '
        '(use POST /api/v1/auth/anonymous ou /api/v1/auth/login, copie o '
        '`id_token` e clique em **Authorize**). Os dados ficam no Firestore.\n\n'
        'Erros seguem sempre o formato `{"error": {"code", "message", "details"}}`.'
    ),
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
    'COMPONENT_SPLIT_REQUEST': True,
    'SCHEMA_PATH_PREFIX': r'/api/v1',
    'ENUM_NAME_OVERRIDES': {
        'UnitEnum': 'core.choices.UNIT_CHOICES',
        'KindEnum': 'core.choices.KIND_CHOICES',
        'ProtocolEnum': 'core.choices.PROTOCOL_CHOICES',
        'SymptomEnum': 'core.choices.SYMPTOM_CHOICES',
        'SymptomStatusEnum': 'core.choices.SYMPTOM_STATUS_CHOICES',
        'SyncResultStatusEnum': 'sync.serializers.RESULT_CHOICES',
        'SyncBatchStatusEnum': 'sync.serializers.BATCH_STATUS_CHOICES',
    },
    'SWAGGER_UI_SETTINGS': {
        'persistAuthorization': True,
        'displayRequestDuration': True,
    },
}


# Firebase
# FIREBASE_MODE=mock    -> Auth e Firestore simulados em memória, sem credenciais.
# FIREBASE_MODE=firebase -> Firebase real (ou emuladores, se FIRESTORE_EMULATOR_HOST
#                           e FIREBASE_AUTH_EMULATOR_HOST estiverem definidos).

FIREBASE_MODE = env('FIREBASE_MODE', default='mock')
FIREBASE_PROJECT_ID = env('FIREBASE_PROJECT_ID', default='dosis-app')
FIREBASE_WEB_API_KEY = env('FIREBASE_WEB_API_KEY', default='')
FIREBASE_CREDENTIALS = env('FIREBASE_CREDENTIALS', default='')
FIREBASE_AUTH_EMULATOR_HOST = env('FIREBASE_AUTH_EMULATOR_HOST', default='')
FIRESTORE_EMULATOR_HOST = env('FIRESTORE_EMULATOR_HOST', default='')

# Chave AES-256 (32 bytes em base64) dos campos sensíveis gravados no Firestore.
# Sem ela, uma chave é derivada da SECRET_KEY (aceitável só em desenvolvimento).
FIELD_ENCRYPTION_KEY = env('FIELD_ENCRYPTION_KEY', default='')

# Arquivo opcional para o mock sobreviver a reinícios do runserver.
MOCK_STORE_PATH = env('MOCK_STORE_PATH', default='')

# Validade dos tokens emitidos pelo modo mock (no Firebase real é 1 hora).
MOCK_ID_TOKEN_TTL_SECONDS = 3600
MOCK_REFRESH_TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30


# Sincronização (fila offline do app)
SYNC_WIFI_ONLY = env.bool('SYNC_WIFI_ONLY', default=True)
SYNC_MAX_BATCH_SIZE = env.int('SYNC_MAX_BATCH_SIZE', default=50)


LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {'class': 'logging.StreamHandler'},
    },
    'loggers': {
        'dosis': {'handlers': ['console'], 'level': 'INFO'},
    },
}
