"""Bluesky content scraper using the public AT Protocol API."""
import asyncio
import logging
from datetime import datetime
from typing import List
import httpx

from app.services.scrapers.base_scraper import BaseScraper, ScrapedContent

logger = logging.getLogger(__name__)


class BlueskyScraper(BaseScraper):
    """Scraper for Bluesky content using the public AT Protocol API."""

    BASE_URL = "https://public.api.bsky.app/xrpc"

    # Trending/popular search terms to get diverse content
    SEARCH_TERMS = [
        "news",
        "politics",
        "technology",
        "breaking",
        "world",
    ]

    @property
    def source_name(self) -> str:
        return "bluesky"

    async def scrape(self, limit: int = 100) -> List[ScrapedContent]:
        """Scrape posts from Bluesky using search API."""
        contents = []
        per_term_limit = limit // len(self.SEARCH_TERMS)

        async with httpx.AsyncClient() as client:
            for term in self.SEARCH_TERMS:
                try:
                    posts = await self._search_posts(client, term, per_term_limit)
                    contents.extend(posts)
                    await asyncio.sleep(0.2)  # Rate limiting
                except Exception as e:
                    logger.error(f"Error searching Bluesky for '{term}': {e}")

        # Deduplicate by URL
        seen_urls = set()
        unique_contents = []
        for content in contents:
            if content.url not in seen_urls:
                seen_urls.add(content.url)
                unique_contents.append(content)

        logger.info(f"Scraped {len(unique_contents)} posts from Bluesky")
        return unique_contents[:limit]

    async def _search_posts(
        self, client: httpx.AsyncClient, query: str, limit: int
    ) -> List[ScrapedContent]:
        """Search for posts matching a query."""
        contents = []

        try:
            response = await client.get(
                f"{self.BASE_URL}/app.bsky.feed.searchPosts",
                params={
                    "q": query,
                    "limit": min(limit, 100),  # API max is 100
                    "sort": "latest",
                },
                timeout=15.0,
            )

            if response.status_code != 200:
                logger.warning(f"Bluesky search returned {response.status_code}")
                return contents

            data = response.json()
            posts = data.get("posts", [])

            for post in posts:
                content = self._parse_post(post)
                if content:
                    contents.append(content)

        except Exception as e:
            logger.error(f"Error in Bluesky search: {e}")

        return contents

    def _parse_post(self, post: dict) -> ScrapedContent | None:
        """Parse a Bluesky post into ScrapedContent."""
        try:
            record = post.get("record", {})
            text = record.get("text", "")

            cleaned_text = self._clean_text(text)
            if not cleaned_text or len(cleaned_text) < 10:
                return None

            # Get post URI and convert to web URL
            uri = post.get("uri", "")
            # URI format: at://did:plc:xxx/app.bsky.feed.post/yyy
            # Web URL: https://bsky.app/profile/handle/post/yyy
            author = post.get("author", {})
            handle = author.get("handle", "")
            post_id = uri.split("/")[-1] if uri else ""
            web_url = f"https://bsky.app/profile/{handle}/post/{post_id}" if handle and post_id else uri

            # Parse timestamp
            created_at = record.get("createdAt", "")
            try:
                timestamp = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
            except:
                timestamp = datetime.now()

            # Get engagement metrics
            like_count = post.get("likeCount", 0)
            reply_count = post.get("replyCount", 0)
            repost_count = post.get("repostCount", 0)

            return ScrapedContent(
                text=cleaned_text[:1000],
                source=self.source_name,
                url=web_url,
                timestamp=timestamp,
                score=like_count + repost_count,  # Combined engagement
                comment_count=reply_count,
                title="",  # Bluesky doesn't have titles
            )

        except Exception as e:
            logger.debug(f"Error parsing Bluesky post: {e}")
            return None
