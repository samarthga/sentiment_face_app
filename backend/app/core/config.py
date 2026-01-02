"""Application configuration."""
from typing import List
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # API
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    debug: bool = True

    # CORS
    cors_origins: List[str] = ["*"]

    # Database
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/sentiment_face"

    # Reddit API
    reddit_client_id: str = ""
    reddit_client_secret: str = ""
    reddit_user_agent: str = "SentimentFace/1.0"

    # Scraping settings
    scrape_interval_minutes: int = 5
    max_posts_per_source: int = 100

    # Sentiment analysis
    sentiment_model: str = "cardiffnlp/twitter-roberta-base-emotion"
    emotion_model: str = "j-hartmann/emotion-english-distilroberta-base"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
