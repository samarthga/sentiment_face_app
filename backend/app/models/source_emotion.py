"""Per-source emotion state with topic information."""
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel

from app.models.emotion import EmotionState


class SourceEmotionState(BaseModel):
    """Emotion state for a specific data source with topic information."""

    source: str
    """Name of the data source (e.g., 'reddit', 'hackernews')."""

    emotion: EmotionState
    """The emotion state calculated from this source's content."""

    top_topic: str
    """The most relevant/frequent topic driving the emotion."""

    topic_sentiment: float = 0.0
    """Sentiment score specifically for the top topic (-1 to 1)."""

    sample_titles: List[str] = []
    """2-3 sample headlines/titles from this source."""

    post_count: int = 0
    """Number of posts analyzed from this source."""

    last_updated: Optional[datetime] = None
    """When this source was last scraped/analyzed."""

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat() if v else None
        }
