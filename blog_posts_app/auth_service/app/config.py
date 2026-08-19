import os
from pydantic_settings import BaseSettings

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

class Settings(BaseSettings):
    DEBUG: bool = False #default
    ENABLE_MONOTORING: bool = True #default
    OTEL_EXPORTER_OTLP_ENDPOINT: str = "http://jaeger:4317"
    OTEL_SERVICE_NAME: str ="auth-service"
    SECRET_KEY : str
    ALGORITHM : str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES : int = 30
    DATABASE_URL : str = "data/database.db"
    class Config:
        env_file = os.path.join(BASE_DIR, "..", ".env.local")
        env_file_encoding = "utf-8"
        
settings = Settings()