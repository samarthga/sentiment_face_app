"""Reddit content scraper using the official API."""
import logging
from datetime import datetime
from typing import List
import httpx

from app.core.config import settings
from app.services.scrapers.base_scraper import BaseScraper, ScrapedContent

logger = logging.getLogger(__name__)


class RedditScraper(BaseScraper):
    """Scraper for Reddit content using the official API."""

    # Popular subreddits for general sentiment
    DEFAULT_SUBREDDITS = [
        "all",
        "popular",
        "news",
        "worldnews",
        "technology",
        "science",
    ]

    def __init__(self, subreddits: List[str] = None):
        self.subreddits = subreddits or self.DEFAULT_SUBREDDITS
        self._access_token = None
        self._token_expires = None

    @property
    def source_name(self) -> str:
        return "reddit"

    async def _get_access_token(self) -> str:
        """Get OAuth access token for Reddit API."""
        if self._access_token and self._token_expires and datetime.utcnow() < self._token_expires:
            return self._access_token

        # If no credentials, use public API (limited)
        if not settings.reddit_client_id or not settings.reddit_client_secret:
            return ""

        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://www.reddit.com/api/v1/access_token",
                auth=(settings.reddit_client_id, settings.reddit_client_secret),
                data={"grant_type": "client_credentials"},
                headers={"User-Agent": settings.reddit_user_agent},
            )
            data = response.json()
            self._access_token = data.get("access_token", "")
            # Token expires in 1 hour, refresh a bit earlier
            self._token_expires = datetime.utcnow()
            return self._access_token

    async def scrape(self, limit: int = 100) -> List[ScrapedContent]:
        """Scrape hot posts from configured subreddits."""
        contents = []
        posts_per_sub = max(10, limit // len(self.subreddits))

        async with httpx.AsyncClient() as client:
            token = await self._get_access_token()
            headers = {"User-Agent": settings.reddit_user_agent}

            if token:
                headers["Authorization"] = f"Bearer {token}"
                base_url = "https://oauth.reddit.com"
            else:
                base_url = "https://www.reddit.com"

            for subreddit in self.subreddits:
                try:
                    url = f"{base_url}/r/{subreddit}/hot.json"
                    response = await client.get(
                        url,
                        headers=headers,
                        params={"limit": posts_per_sub},
                        timeout=10.0,
                    )

                    if response.status_code != 200:
                        logger.warning(f"Reddit API error for r/{subreddit}: {response.status_code}")
                        continue

                    data = response.json()
                    posts = data.get("data", {}).get("children", [])

                    for post in posts:
                        post_data = post.get("data", {})

                        # Combine title and selftext for analysis
                        title = post_data.get("title", "")
                        selftext = post_data.get("selftext", "")
                        text = self._clean_text(f"{title} {selftext}")

                        if not text or len(text) < 10:
                            continue

                        contents.append(ScrapedContent(
                            text=text[:1000],  # Limit text length
                            source=self.source_name,
                            url=f"https://reddit.com{post_data.get('permalink', '')}",
                            timestamp=datetime.fromtimestamp(post_data.get("created_utc", 0)),
                            score=post_data.get("score", 0),
                            comment_count=post_data.get("num_comments", 0),
                            title=title,
                        ))

                except Exception as e:
                    logger.error(f"Error scraping r/{subreddit}: {e}")
                    continue

        logger.info(f"Scraped {len(contents)} posts from Reddit")
        return contents[:limit]
