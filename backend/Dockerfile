FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DJANGO_STATIC_ROOT=/app/staticfiles

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
RUN python manage.py collectstatic --noinput \
    && useradd --create-home --uid 1000 dosis \
    && mkdir -p /data /app/secrets \
    && chown dosis /data

USER dosis
EXPOSE 8000
ENTRYPOINT ["python", "docker/entrypoint.py"]
