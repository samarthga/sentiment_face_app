"""Truth Social content scraper using truthbrush library."""
import asyncio
import logging
import os
from datetime import datetime
from typing import List, Optional

from app.services.scrapers.base_scraper import BaseScraper, ScrapedContent

logger = logging.getLogger(__name__)


class TruthSocialScraper(BaseScraper):
    """Scraper for Truth Social content using truthbrush library."""

    @property
    def source_name(self) -> str:
        return "truthsocial"

    async def scrape(self, limit: int = 100) -> List[ScrapedContent]:
        """Scrape trending posts from Truth Social."""
        contents = []

        # Check for credentials
        username = os.getenv("TRUTHSOCIAL_USERNAME")
        password = os.getenv("TRUTHSOCIAL_PASSWORD")

        if not username or not password:
            logger.warning("Truth Social credentials not configured (TRUTHSOCIAL_USERNAME, TRUTHSOCIAL_PASSWORD)")
            return contents

        try:
            # truthbrush is synchronous, run in executor
            loop = asyncio.get_event_loop()
            contents = await loop.run_in_executor(
                None,
                self._scrape_sync,
                limit,
                username,
                password,
            )
        except Exception as e:
            logger.error(f"Error scraping Truth Social: {e}")

        logger.info(f"Scraped {len(contents)} posts from Truth Social")
        return contents

    def _scrape_sync(self, limit: int, username: str, password: str) -> List[ScrapedContent]:
        """Synchronous scraping using truthbrush."""
        contents = []

        try:
            from truthbrush import Api

            # Initialize API with credentials
            api = Api(username=username, password=password)

            # Get trending truths
            try:
                trends = api.trending(limit=min(limit, 40))
                for status in trends:
                    content = self._parse_status(status)
                    if content:
                        contents.append(content)
            except Exception as e:
                logger.debug(f"Error fetching trends: {e}")

            # Also search for news-related content
            if len(contents) < limit:
                try:
                    search_results = api.search("news", kind="statuses", limit=min(limit - len(contents), 40))
                    for status in search_results:
                        content = self._parse_status(status)
                        if content:
                            contents.append(content)
                except Exception as e:
                    logger.debug(f"Error searching Truth Social: {e}")

        except ImportError:
            logger.error("truthbrush library not installed. Run: pip install truthbrush")
        except Exception as e:
            logger.error(f"Truth Social API error: {e}")

        return contents

    def _parse_status(self, status: dict) -> Optional[ScrapedContent]:
        """Parse a Truth Social status into ScrapedContent."""
        try:
            # Get content and clean it
            content = status.get("content", "")
            text = self._strip_html(content)
            cleaned_text = self._clean_text(text)

            if not cleaned_text or len(cleaned_text) < 10:
                return None

            # Skip replies
            if status.get("in_reply_to_id"):
                return None

            # Get URL
            url = status.get("url", status.get("uri", ""))

            # Parse timestamp
            created_at = status.get("created_at", "")
            try:
                timestamp = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
            except Exception:
                timestamp = datetime.utcnow()

            # Get engagement metrics
            favourites = status.get("favourites_count", 0) or 0
            reblogs = status.get("reblogs_count", 0) or 0
            replies = status.get("replies_count", 0) or 0

            return ScrapedContent(
                text=cleaned_text[:1000],
                source=self.source_name,
                url=url,
                timestamp=timestamp,
                score=favourites + reblogs,
                comment_count=replies,
                title="",
            )

        except Exception as e:
            logger.debug(f"Error parsing Truth Social status: {e}")
            return None

    def _strip_html(self, html: str) -> str:
        """Remove HTML tags from content."""
        if not html:
            return ""

        import re

        # Remove HTML tags
        text = re.sub(r'<[^>]+>', ' ', html)

        # Decode common HTML entities
        text = text.replace("&amp;", "&")
        text = text.replace("&lt;", "<")
        text = text.replace("&gt;", ">")
        text = text.replace("&quot;", '"')
        text = text.replace("&#39;", "'")
        text = text.replace("&nbsp;", " ")

        return text.strip()
