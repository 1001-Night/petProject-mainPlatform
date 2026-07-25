from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "mainPlatform"
    database_url: str = "postgresql+psycopg://app:app_password@localhost:5432/app"
    database_url_file: Path | None = None

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    def resolved_database_url(self) -> str:
        if self.database_url_file is not None:
            return self.database_url_file.read_text(encoding="utf-8").strip()

        return self.database_url


settings = Settings()
