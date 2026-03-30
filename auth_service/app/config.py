import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DEBUG: bool = False #default
    ENABLE_MONOTORING: bool = True #default
    OTEL_EXPORTER_OTLP_ENDPOINT: str = "http://jaeger:4317"
    OTEL_SERVICE_NAME: str ="auth-service"
    SECRET_KEY : str
    ALGORITHM : str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES : int = 30
    class Config:
        env_file = f".env.local"
        
settings = Settings()