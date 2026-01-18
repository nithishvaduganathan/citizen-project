"""
Application configuration settings
"""
from typing import List, Optional
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings configuration"""
    
    # Application
    APP_NAME: str = "Citizen Civic AI"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    API_V1_PREFIX: str = "/api/v1"
    
    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # MongoDB
    MONGODB_URL: str = "mongodb://localhost:27017"
    MONGODB_DB_NAME: str = "citizen_civic_ai"
    
    # Firebase
    FIREBASE_PROJECT_ID: str = ""
    FIREBASE_PRIVATE_KEY: str = ""
    FIREBASE_CLIENT_EMAIL: str = ""
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None
    
    # OpenAI for LLM
    OPENAI_API_KEY: str = ""
    
    # Vector Database
    CHROMA_PERSIST_DIRECTORY: str = "./data/chroma_db"
    
    # File uploads
    UPLOAD_DIRECTORY: str = "./uploads"
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10 MB
    ALLOWED_IMAGE_TYPES: List[str] = ["image/jpeg", "image/png", "image/webp"]
    
    # Security
    # IMPORTANT: SECRET_KEY must be set in production via environment variable
    SECRET_KEY: str = ""
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours
    
    # CORS - IMPORTANT: Restrict to specific domains in production
    CORS_ORIGINS: List[str] = ["http://localhost:3000"]
    
    # Rate limiting
    RATE_LIMIT_PER_MINUTE: int = 60
    
    # Location defaults (India)
    DEFAULT_COUNTRY: str = "India"
    DEFAULT_LANGUAGE: str = "en"
    SUPPORTED_LANGUAGES: List[str] = ["en", "ta", "hi"]
    
    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()


settings = get_settings()
