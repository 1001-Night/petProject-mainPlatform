from fastapi import FastAPI
from psycopg import connect

from app.config import settings

app = FastAPI(title=settings.app_name)


@app.get("/")
def root() -> dict[str, str]:
    return {
        "service": "backend-api",
        "status": "running",
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/ready")
def ready() -> dict[str, str]:
    with connect(settings.database_url, connect_timeout=3) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
            cur.fetchone()

    return {"status": "ready"}