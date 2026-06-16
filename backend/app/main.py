from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI
from pydantic import BaseModel
from psycopg import connect
from psycopg.rows import dict_row

from app.config import settings


class NoteCreate(BaseModel):
    title: str
    content: str


class Note(BaseModel):
    id: int
    title: str
    content: str


def get_connection():
    return connect(settings.database_url, row_factory=dict_row)


def init_db() -> None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS notes (
                    id SERIAL PRIMARY KEY,
                    title TEXT NOT NULL,
                    content TEXT NOT NULL
                )
                """
            )


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(title=settings.app_name, lifespan=lifespan)


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