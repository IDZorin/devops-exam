# syntax=docker/dockerfile:1.7
ARG PYTHON_VERSION=3.11-slim

FROM python:${PYTHON_VERSION} AS builder
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /src
COPY requirements.txt .

# cache pip wheels
RUN --mount=type=cache,target=/root/.cache/pip \
    pip wheel --no-cache-dir -r requirements.txt -w /wheels

COPY src ./src

# Устанавливаем зависимости и обучаем модель на этапе сборки
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-index --find-links=/wheels -r requirements.txt \
    && python src/train.py

FROM python:${PYTHON_VERSION} AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# non-root user
RUN useradd -m -u 10001 appuser
WORKDIR /app

COPY --from=builder /wheels /wheels
COPY requirements.txt .

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-index --find-links=/wheels -r requirements.txt \
    && rm -rf /wheels

COPY app/ /app
COPY --from=builder /src/models /app/models

USER appuser
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health').read()"

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}"]
