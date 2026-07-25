from fastapi.testclient import TestClient

from app.config import Settings, settings
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


def test_database_url_can_be_read_from_file(tmp_path) -> None:
    database_url_file = tmp_path / "database-url"
    database_url_file.write_text(
        "postgresql+psycopg://app:secret@postgres:5432/app\n",
        encoding="utf-8",
    )
    file_settings = Settings(
        _env_file=None,
        database_url="postgresql+psycopg://unused",
        database_url_file=database_url_file,
    )

    assert (
        file_settings.resolved_database_url()
        == "postgresql+psycopg://app:secret@postgres:5432/app"
    )
