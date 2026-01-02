"""RSS feed scraper for news and blog content."""
import logging
from datetime import datetime
from typing import List
import httpx
import feedparser

from app.services.scrapers.base_scraper import BaseScraper, ScrapedContent

logger = logging.getLogger(__name__)


class RSSScraper(BaseScraper):
    """Scraper for RSS/Atom feeds."""

    # Default feeds covering various topics
    DEFAULT_FEEDS = [
        "https://feeds.bbci.co.uk/news/rss.xml",
        "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml",
        "https://feeds.arstechnica.com/arstechnica/index",
        "https://www.theverge.com/rss/index.xml",
        "https://techcrunch.com/feed/",
    ]

    def __init__(self, feeds: List[str] = None):
        self.feeds = feeds or self.DEFAULT_FEEDS

    @property
    def source_name(self) -> str:
        return "rss"

    async def scrape(self, limit: int = 100) -> List[ScrapedContent]:
        """Scrape content from configured RSS feeds."""
        contents = []
        items_per_feed = max(10, limit // len(self.feeds))

        async with httpx.AsyncClient() as client:
            for feed_url in self.feeds:
                try:
                    response = await client.get(
                        feed_url,
                        timeout=10.0,
                        follow_redirects=True,
                    )

                    if response.status_code != 200:
                        logger.warning(f"RSS fetch error for {feed_url}: {response.status_code}")
                        continue

                    # Parse the feed
                    feed = feedparser.parse(response.text)

                    for entry in feed.entries[:items_per_feed]:
                        title = entry.get("title", "")
                        summary = entry.get("summary", "") or entry.get("description", "")

                        # Clean HTML from summary
                        import re
                        summary = re.sub(r"<[^>]+>", " ", summary)

                        text = self._clean_text(f"{title} {summary}")
                        if not text or len(text) < 10:
                            continue

                        # Parse timestamp
                        timestamp = datetime.utcnow()
                        if "published_parsed" in entry and entry.published_parsed:
                            try:
                                timestamp = datetime(*entry.published_parsed[:6])
                            except Exception:
                                pass

                        contents.append(ScrapedContent(
                            text=text[:1000],
                            source=self.source_name,
                            url=entry.get("link", ""),
                            timestamp=timestamp,
                            score=0,
                            comment_count=0,
                            title=title,
                        ))

                except Exception as e:
                    logger.error(f"Error scraping RSS feed {feed_url}: {e}")
                    continue

        logger.info(f"Scraped {len(contents)} items from RSS feeds")
        return contents[:limit]
