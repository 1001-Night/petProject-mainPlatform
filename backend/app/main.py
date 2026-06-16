from fastapi import FastAPI

app = FastAPI(title="DevOps Fullstack Platform API")


@app.get("/")
def root() -> dict[str, str]:
    return {
        "service": "backend-api",
        "status": "running",
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}