import os
from typing import Optional

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(
    title="DevOps Final Service",
    version="1.0.0",
    description="FastAPI сервис с healthchecks и инференсом модели Iris.",
)


class IrisFeatures(BaseModel):
    sepal_length: float
    sepal_width: float
    petal_length: float
    petal_width: float


MODEL_PATH = os.getenv("MODEL_PATH", "models/rf_iris_model.pkl")
_model: Optional[object] = None
# Порядок признаков в запросе API (человекочитаемый)
API_FEATURE_ORDER = [
    "sepal_length",
    "sepal_width",
    "petal_length",
    "petal_width",
]
# Порядок колонок, с которыми обучалась модель (из sklearn iris)
DEFAULT_MODEL_COLUMNS = [
    "sepal length (cm)",
    "sepal width (cm)",
    "petal length (cm)",
    "petal width (cm)",
]


def load_model() -> object:
    """Lazy load модели из файловой системы."""
    global _model
    if _model is None:
        if not os.path.exists(MODEL_PATH):
            raise RuntimeError(
                f"Model file not found at {MODEL_PATH}. "
                f"Сначала запустите src/train.py или укажите MODEL_PATH."
            )
        _model = joblib.load(MODEL_PATH)
    return _model


@app.get("/")
def root() -> dict:
    return {
        "message": "DevOps Final FastAPI service is running",
        "endpoints": ["/health", "/healthz", "/predict"],
    }


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.get("/healthz")
def healthz() -> dict:
    try:
        load_model()
        return {"status": "ok", "model_loaded": True}
    except Exception as exc:  # pragma: no cover - используется в health-check
        raise HTTPException(status_code=500, detail=str(exc))


@app.post("/predict")
def predict(features: IrisFeatures) -> dict:
    model = load_model()
    values = [
        features.sepal_length,
        features.sepal_width,
        features.petal_length,
        features.petal_width,
    ]
    # Создаём DataFrame с теми колонками, с которыми обучалась модель, чтобы избежать предупреждений
    model_columns = (
        list(getattr(model, "feature_names_in_", [])) or DEFAULT_MODEL_COLUMNS
    )
    x_df = pd.DataFrame([values], columns=model_columns)

    try:
        proba = model.predict_proba(x_df)[0]
        pred_class = int(np.argmax(proba))
        probabilities = proba.tolist()
    except AttributeError:
        pred_class = int(model.predict(x_df)[0])
        probabilities = None

    return {"predicted_class": pred_class, "probabilities": probabilities}
