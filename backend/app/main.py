from typing import Any

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel
from psycopg import connect
from psycopg.rows import dict_row

from app.config import settings


API_VERSION = "v1"


class NoteCreate(BaseModel):
    title: str
    content: str


class Note(BaseModel):
    id: int
    title: str
    content: str


def get_connection():
    database_url = settings.database_url.replace("postgresql+psycopg://", "postgresql://")
    return connect(database_url, row_factory=dict_row)

app = FastAPI(title=settings.app_name)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Instrumentator().instrument(app).expose(
    app,
    endpoint="/metrics",
    include_in_schema=False,
)

@app.get("/")
def root() -> dict[str, str]:
    return {
        "service": "backend-api",
        "status": "running",
        "version": API_VERSION,
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/ready")
def ready() -> dict[str, str]:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
            cur.fetchone()

    return {"status": "ready"}


@app.post("/notes", response_model=Note, status_code=201)
def create_note(note: NoteCreate) -> Any:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO notes (title, content)
                VALUES (%s, %s)
                RETURNING id, title, content
                """,
                (note.title, note.content),
            )
            return cur.fetchone()


@app.get("/notes", response_model=list[Note])
def list_notes() -> Any:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, title, content FROM notes ORDER BY id")
            return cur.fetchall()
