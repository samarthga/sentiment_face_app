"""Emotion and sentiment data models."""
from datetime import datetime
from typing import Dict, Optional
from pydantic import BaseModel, Field


class EmotionState(BaseModel):
    """Complete emotional state derived from sentiment analysis."""

    # Primary emotions (Ekman's basic emotions) - 0.0 to 1.0
    happiness: float = Field(default=0.0, ge=0.0, le=1.0)
    sadness: float = Field(default=0.0, ge=0.0, le=1.0)
    anger: float = Field(default=0.0, ge=0.0, le=1.0)
    fear: float = Field(default=0.0, ge=0.0, le=1.0)
    surprise: float = Field(default=0.0, ge=0.0, le=1.0)
    disgust: float = Field(default=0.0, ge=0.0, le=1.0)

    # Secondary/complex emotions
    confusion: float = Field(default=0.0, ge=0.0, le=1.0)
    pride: float = Field(default=0.0, ge=0.0, le=1.0)
    loneliness: float = Field(default=0.0, ge=0.0, le=1.0)
    pain: float = Field(default=0.0, ge=0.0, le=1.0)
    contempt: float = Field(default=0.0, ge=0.0, le=1.0)
    anticipation: float = Field(default=0.0, ge=0.0, le=1.0)
    trust: float = Field(default=0.0, ge=0.0, le=1.0)

    # Overall sentiment score (-1.0 to 1.0)
    overall_sentiment: float = Field(default=0.0, ge=-1.0, le=1.0, alias="overallSentiment")

    # Intensity of expression (0.0 to 1.0)
    intensity: float = Field(default=0.5, ge=0.0, le=1.0)

    # Timestamp
    timestamp: Optional[datetime] = None

    # Source breakdown
    source_contributions: Dict[str, float] = Field(default_factory=dict, alias="sourceContributions")

    class Config:
        populate_by_name = True

    @property
    def dominant_emotion(self) -> str:
        """Returns the name of the dominant emotion."""
        emotions = {
            "happiness": self.happiness,
            "sadness": self.sadness,
            "anger": self.anger,
            "fear": self.fear,
            "surprise": self.surprise,
            "disgust": self.disgust,
            "confusion": self.confusion,
            "pride": self.pride,
            "loneliness": self.loneliness,
            "pain": self.pain,
            "contempt": self.contempt,
        }
        return max(emotions, key=emotions.get)

    @property
    def dominant_intensity(self) -> float:
        """Returns the intensity of the dominant emotion."""
        emotions = [
            self.happiness, self.sadness, self.anger, self.fear,
            self.surprise, self.disgust, self.confusion, self.pride,
            self.loneliness, self.pain, self.contempt,
        ]
        return max(emotions)


class SentimentResult(BaseModel):
    """Result from analyzing a single piece of text."""

    text: str
    source: str
    emotions: Dict[str, float]
    sentiment_score: float
    confidence: float
    timestamp: datetime


class SourceSentiment(BaseModel):
    """Aggregated sentiment from a single source."""

    source: str
    post_count: int
    emotion_state: EmotionState
    last_updated: datetime
