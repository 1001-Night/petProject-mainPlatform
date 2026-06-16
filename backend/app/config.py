from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "DevOps Fullstack Platform API"
    database_url: str = "postgresql://app:app_password@localhost:5432/app"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()