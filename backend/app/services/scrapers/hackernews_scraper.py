"""HackerNews content scraper using the official API."""
import asyncio
import logging
from datetime import datetime
from typing import List
import httpx

from app.services.scrapers.base_scraper import BaseScraper, ScrapedContent

logger = logging.getLogger(__name__)


class HackerNewsScraper(BaseScraper):
    """Scraper for HackerNews content using the official Firebase API."""

    BASE_URL = "https://hacker-news.firebaseio.com/v0"

    @property
    def source_name(self) -> str:
        return "hackernews"

    async def scrape(self, limit: int = 100) -> List[ScrapedContent]:
        """Scrape top stories from HackerNews."""
        contents = []

        async with httpx.AsyncClient() as client:
            try:
                # Get top story IDs
                response = await client.get(
                    f"{self.BASE_URL}/topstories.json",
                    timeout=10.0,
                )
                story_ids = response.json()[:limit]

                # Fetch story details in parallel (with rate limiting)
                batch_size = 20
                for i in range(0, len(story_ids), batch_size):
                    batch = story_ids[i:i + batch_size]
                    tasks = [self._fetch_story(client, story_id) for story_id in batch]
                    results = await asyncio.gather(*tasks, return_exceptions=True)

                    for result in results:
                        if isinstance(result, ScrapedContent):
                            contents.append(result)

                    # Small delay between batches
                    await asyncio.sleep(0.1)

            except Exception as e:
                logger.error(f"Error scraping HackerNews: {e}")

        logger.info(f"Scraped {len(contents)} stories from HackerNews")
        return contents

    async def _fetch_story(self, client: httpx.AsyncClient, story_id: int) -> ScrapedContent | None:
        """Fetch a single story's details."""
        try:
            response = await client.get(
                f"{self.BASE_URL}/item/{story_id}.json",
                timeout=5.0,
            )
            data = response.json()

            if not data or data.get("type") != "story":
                return None

            title = data.get("title", "")
            text = data.get("text", "")  # For Ask HN posts

            combined_text = self._clean_text(f"{title} {text}")
            if not combined_text or len(combined_text) < 10:
                return None

            return ScrapedContent(
                text=combined_text[:1000],
                source=self.source_name,
                url=data.get("url", f"https://news.ycombinator.com/item?id={story_id}"),
                timestamp=datetime.fromtimestamp(data.get("time", 0)),
                score=data.get("score", 0),
                comment_count=data.get("descendants", 0),
                title=title,
            )

        except Exception as e:
            logger.debug(f"Error fetching HN story {story_id}: {e}")
            return None
