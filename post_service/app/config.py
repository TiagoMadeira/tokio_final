import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DEBUG: bool = False #default
    ENABLE_MONOTORING: bool = True #default
    OTEL_EXPORTER_OTLP_ENDPOINT: str = "http://jaeger:4317"
    OTEL_SERVICE_NAME: str ="post-service"
    AUTH_SERVICE_URL : str = "http://127.0.0.1:8888"
    class Config:
        env_file = f".env.local"
        
settings = Settings()