"""Bluesky content scraper using the AT Protocol API with authentication."""
import asyncio
import logging
import os
from datetime import datetime
from typing import List, Optional
import httpx

from app.services.scrapers.base_scraper import BaseScraper, ScrapedContent

logger = logging.getLogger(__name__)


class BlueskyScraper(BaseScraper):
    """Scraper for Bluesky content using authenticated AT Protocol API."""

    AUTH_URL = "https://bsky.social/xrpc"
    API_URL = "https://bsky.social/xrpc"

    # Trending/popular search terms to get diverse content
    SEARCH_TERMS = [
        "news",
        "politics",
        "technology",
        "breaking",
        "world",
    ]

    def __init__(self):
        self._access_token: Optional[str] = None
        self._did: Optional[str] = None

    @property
    def source_name(self) -> str:
        return "bluesky"

    async def _authenticate(self, client: httpx.AsyncClient) -> bool:
        """Authenticate with Bluesky and get access token."""
        identifier = os.getenv("BLUESKY_IDENTIFIER")
        password = os.getenv("BLUESKY_APP_PASSWORD")

        if not identifier or not password:
            logger.warning("Bluesky credentials not configured (BLUESKY_IDENTIFIER, BLUESKY_APP_PASSWORD)")
            return False

        try:
            response = await client.post(
                f"{self.AUTH_URL}/com.atproto.server.createSession",
                json={
                    "identifier": identifier,
                    "password": password,
                },
                timeout=15.0,
            )

            if response.status_code == 200:
                data = response.json()
                self._access_token = data.get("accessJwt")
                self._did = data.get("did")
                logger.info("Bluesky authentication successful")
                return True
            else:
                logger.error(f"Bluesky auth failed: {response.status_code} - {response.text}")
                return False

        except Exception as e:
            logger.error(f"Bluesky authentication error: {e}")
            return False

    async def scrape(self, limit: int = 100) -> List[ScrapedContent]:
        """Scrape posts from Bluesky using authenticated API."""
        contents = []
        per_term_limit = limit // len(self.SEARCH_TERMS)

        async with httpx.AsyncClient() as client:
            # Authenticate first
            if not await self._authenticate(client):
                logger.warning("Skipping Bluesky scrape - authentication failed")
                return contents

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

        if not self._access_token:
            return contents

        try:
            response = await client.get(
                f"{self.API_URL}/app.bsky.feed.searchPosts",
                params={
                    "q": query,
                    "limit": min(limit, 100),
                    "sort": "latest",
                },
                headers={
                    "Authorization": f"Bearer {self._access_token}",
                    "Accept": "application/json",
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

    def _parse_post(self, post: dict) -> Optional[ScrapedContent]:
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
