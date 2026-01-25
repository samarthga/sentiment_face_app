"""Truth Social content scraper using Mastodon-compatible API."""
import asyncio
import logging
import re
from datetime import datetime
from typing import List
import httpx

from app.services.scrapers.base_scraper import BaseScraper, ScrapedContent

logger = logging.getLogger(__name__)


class TruthSocialScraper(BaseScraper):
    """Scraper for Truth Social content using Mastodon-compatible API."""

    BASE_URL = "https://truthsocial.com/api/v1"

    @property
    def source_name(self) -> str:
        return "truthsocial"

    async def scrape(self, limit: int = 100) -> List[ScrapedContent]:
        """Scrape posts from Truth Social public timeline."""
        contents = []

        async with httpx.AsyncClient() as client:
            try:
                # Fetch public timeline
                posts = await self._fetch_public_timeline(client, limit)
                contents.extend(posts)
            except Exception as e:
                logger.error(f"Error scraping Truth Social: {e}")

            # Also try trending tags if available
            try:
                trending_posts = await self._fetch_trending(client, limit // 2)
                contents.extend(trending_posts)
            except Exception as e:
                logger.debug(f"Could not fetch Truth Social trending: {e}")

        # Deduplicate by URL
        seen_urls = set()
        unique_contents = []
        for content in contents:
            if content.url not in seen_urls:
                seen_urls.add(content.url)
                unique_contents.append(content)

        logger.info(f"Scraped {len(unique_contents)} posts from Truth Social")
        return unique_contents[:limit]

    async def _fetch_public_timeline(
        self, client: httpx.AsyncClient, limit: int
    ) -> List[ScrapedContent]:
        """Fetch posts from the public timeline."""
        contents = []

        try:
            response = await client.get(
                f"{self.BASE_URL}/timelines/public",
                params={
                    "limit": min(limit, 40),  # API typically limits to 40
                    "local": "true",  # Only local posts, not federated
                },
                headers={
                    "User-Agent": "SentimentFace/1.0 (sentiment analysis research)",
                },
                timeout=15.0,
            )

            if response.status_code != 200:
                logger.warning(f"Truth Social timeline returned {response.status_code}")
                return contents

            posts = response.json()

            for post in posts:
                content = self._parse_status(post)
                if content:
                    contents.append(content)

        except Exception as e:
            logger.error(f"Error fetching Truth Social timeline: {e}")

        return contents

    async def _fetch_trending(
        self, client: httpx.AsyncClient, limit: int
    ) -> List[ScrapedContent]:
        """Fetch trending posts/tags."""
        contents = []

        try:
            # Try to get trending statuses (Mastodon 3.5+ API)
            response = await client.get(
                f"{self.BASE_URL}/trends/statuses",
                params={"limit": min(limit, 20)},
                headers={
                    "User-Agent": "SentimentFace/1.0 (sentiment analysis research)",
                },
                timeout=15.0,
            )

            if response.status_code == 200:
                posts = response.json()
                for post in posts:
                    content = self._parse_status(post)
                    if content:
                        contents.append(content)

        except Exception as e:
            logger.debug(f"Error fetching Truth Social trends: {e}")

        return contents

    def _parse_status(self, status: dict) -> ScrapedContent | None:
        """Parse a Mastodon-style status into ScrapedContent."""
        try:
            # Get the content (HTML) and strip tags
            html_content = status.get("content", "")
            text = self._strip_html(html_content)

            cleaned_text = self._clean_text(text)
            if not cleaned_text or len(cleaned_text) < 10:
                return None

            # Skip if it's a reply (we want original posts)
            if status.get("in_reply_to_id"):
                return None

            # Get URL
            url = status.get("url", status.get("uri", ""))

            # Parse timestamp
            created_at = status.get("created_at", "")
            try:
                timestamp = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
            except:
                timestamp = datetime.now()

            # Get engagement metrics
            favourites_count = status.get("favourites_count", 0)
            reblogs_count = status.get("reblogs_count", 0)
            replies_count = status.get("replies_count", 0)

            return ScrapedContent(
                text=cleaned_text[:1000],
                source=self.source_name,
                url=url,
                timestamp=timestamp,
                score=favourites_count + reblogs_count,
                comment_count=replies_count,
                title="",
            )

        except Exception as e:
            logger.debug(f"Error parsing Truth Social status: {e}")
            return None

    def _strip_html(self, html: str) -> str:
        """Remove HTML tags from content."""
        if not html:
            return ""

        # Remove HTML tags
        text = re.sub(r'<[^>]+>', ' ', html)

        # Decode common HTML entities
        text = text.replace("&amp;", "&")
        text = text.replace("&lt;", "<")
        text = text.replace("&gt;", ">")
        text = text.replace("&quot;", '"')
        text = text.replace("&#39;", "'")
        text = text.replace("&nbsp;", " ")

        return text
