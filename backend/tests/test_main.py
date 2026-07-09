from fastapi.testclient import TestClient

from app.config import settings
from app.main import app

client = TestClient(app)


def test_app_title_comes_from_settings() -> None:
    assert app.title == settings.app_name


def test_root() -> None:
    response = client.get("/")

    assert response.status_code == 200
    assert response.json()["service"] == "backend-api"
    assert response.json()["version"] == "v1"


def test_health() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_metrics() -> None:
    response = client.get("/metrics")

    assert response.status_code == 200
    assert "http_requests_total" in response.text
