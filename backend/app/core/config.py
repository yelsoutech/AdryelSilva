from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Application
    PROJECT_NAME: str = "Marketplace Intelligence"
    API_V1_PREFIX: str = "/api/v1"
    DEBUG: bool = True
    ENVIRONMENT: str = "development"

    # Database (Supabase Postgres pooler)
    DATABASE_URL: str = "postgresql+asyncpg://user:password@localhost:5432/marketplace_intelligence"

    # Supabase
    SUPABASE_URL: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    SUPABASE_ANON_KEY: str = ""

    # CORS
    CORS_ORIGINS: list[str] = ["http://localhost:3000"]

    # Mercado Livre (placeholder for future integration)
    MERCADOLIVRE_CLIENT_ID: str = ""
    MERCADOLIVRE_CLIENT_SECRET: str = ""
    MERCADOLIVRE_REDIRECT_URI: str = "http://localhost:8000/api/v1/oauth/mercadolivre/callback"

    # Worker
    WORKER_POLL_INTERVAL: int = 5
    WORKER_MAX_CONCURRENT: int = 10

    model_config = {"env_file": ".env", "case_sensitive": True}


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
