"""Base scraper interface."""
from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from typing import List


@dataclass
class ScrapedContent:
    """Content scraped from a source."""

    text: str
    source: str
    url: str
    timestamp: datetime
    score: int = 0  # Upvotes, likes, etc.
    comment_count: int = 0
    title: str = ""


class BaseScraper(ABC):
    """Abstract base class for content scrapers."""

    @property
    @abstractmethod
    def source_name(self) -> str:
        """Return the name of this source."""
        pass

    @abstractmethod
    async def scrape(self, limit: int = 100) -> List[ScrapedContent]:
        """Scrape content from the source."""
        pass

    def _clean_text(self, text: str) -> str:
        """Clean and normalize text content."""
        if not text:
            return ""

        # Remove excessive whitespace
        text = " ".join(text.split())

        # Remove common noise
        text = text.replace("[deleted]", "").replace("[removed]", "")

        return text.strip()
