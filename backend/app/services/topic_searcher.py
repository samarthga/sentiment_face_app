"""Search and analyze sentiment for specific topics."""
import logging
from datetime import datetime
from typing import Dict, List, Optional
import httpx

from app.models.emotion import EmotionState
from app.services.sentiment_analyzer import SentimentAnalyzer
from app.services.history_store import history_store, topic_extractor

logger = logging.getLogger(__name__)


class TopicSearcher:
    """Searches news sources for specific topics and analyzes sentiment."""

    def __init__(self):
        self.analyzer = SentimentAnalyzer()

    async def search_topic(self, query: str) -> Dict:
        """Search for a topic across news sources and analyze sentiment."""
        query = query.lower().strip()
        all_content = []

        # Search Reddit
        reddit_content = await self._search_reddit(query)
        all_content.extend(reddit_content)

        # Search HackerNews
        hn_content = await self._search_hackernews(query)
        all_content.extend(hn_content)

        if not all_content:
            return {
                "query": query,
                "count": 0,
                "message": "No content found for this topic",
                "emotion": None,
                "topics": [],
            }

        # Analyze sentiment
        texts = [c["text"] for c in all_content]
        results = self.analyzer.analyze_batch(texts)

        # Aggregate emotions
        emotion_state = self._aggregate_emotions(all_content, results)

        # Extract related topics
        content_dicts = [{"title": c["title"], "text": c["text"]} for c in all_content]
        result_dicts = [{"sentiment_score": r.sentiment_score} for r in results]
        topics = topic_extractor.extract_topics(content_dicts, result_dicts, limit=10)

        # Filter out the search query itself from topics
        topics = [t for t in topics if t["topic"].lower() != query.lower()]

        # Store in history
        history_store.add_entry(
            emotion_state={
                "happiness": emotion_state.happiness,
                "sadness": emotion_state.sadness,
                "anger": emotion_state.anger,
                "fear": emotion_state.fear,
                "surprise": emotion_state.surprise,
                "disgust": emotion_state.disgust,
                "confusion": emotion_state.confusion,
                "pride": emotion_state.pride,
                "loneliness": emotion_state.loneliness,
                "pain": emotion_state.pain,
                "overall_sentiment": emotion_state.overall_sentiment,
                "intensity": emotion_state.intensity,
            },
            topics=[{"topic": query, "count": len(all_content), "sentiment": emotion_state.overall_sentiment}] + topics[:5],
            sources_summary={"reddit": len(reddit_content), "hackernews": len(hn_content)},
        )

        return {
            "query": query,
            "count": len(all_content),
            "emotion": {
                "happiness": emotion_state.happiness,
                "sadness": emotion_state.sadness,
                "anger": emotion_state.anger,
                "fear": emotion_state.fear,
                "surprise": emotion_state.surprise,
                "disgust": emotion_state.disgust,
                "confusion": emotion_state.confusion,
                "pride": emotion_state.pride,
                "loneliness": emotion_state.loneliness,
                "pain": emotion_state.pain,
                "overall_sentiment": emotion_state.overall_sentiment,
                "intensity": emotion_state.intensity,
                "timestamp": datetime.utcnow().isoformat(),
            },
            "topics": topics[:10],
            "sources": {
                "reddit": len(reddit_content),
                "hackernews": len(hn_content),
            },
        }

    async def _search_reddit(self, query: str, limit: int = 30) -> List[Dict]:
        """Search Reddit for a topic."""
        content = []
        headers = {"User-Agent": "SentimentFace/1.0"}

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                # Search Reddit
                url = f"https://www.reddit.com/search.json?q={query}&sort=relevance&limit={limit}"
                response = await client.get(url, headers=headers)

                if response.status_code == 200:
                    data = response.json()
                    posts = data.get("data", {}).get("children", [])

                    for post in posts:
                        post_data = post.get("data", {})
                        title = post_data.get("title", "")
                        selftext = post_data.get("selftext", "")[:500]
                        text = f"{title} {selftext}".strip()

                        if text and query.lower() in text.lower():
                            content.append({
                                "title": title,
                                "text": text,
                                "source": "reddit",
                                "score": post_data.get("score", 0),
                                "url": f"https://reddit.com{post_data.get('permalink', '')}",
                            })

                logger.info(f"Reddit search for '{query}': found {len(content)} posts")

        except Exception as e:
            logger.error(f"Reddit search error: {e}")

        return content

    async def _search_hackernews(self, query: str, limit: int = 30) -> List[Dict]:
        """Search HackerNews for a topic using Algolia API."""
        content = []

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                # Use HN Algolia search API
                url = f"https://hn.algolia.com/api/v1/search?query={query}&tags=story&hitsPerPage={limit}"
                response = await client.get(url)

                if response.status_code == 200:
                    data = response.json()
                    hits = data.get("hits", [])

                    for hit in hits:
                        title = hit.get("title", "")
                        text = title  # HN stories often just have titles

                        if text:
                            content.append({
                                "title": title,
                                "text": text,
                                "source": "hackernews",
                                "score": hit.get("points", 0) or 0,
                                "url": hit.get("url", f"https://news.ycombinator.com/item?id={hit.get('objectID', '')}"),
                            })

                logger.info(f"HN search for '{query}': found {len(content)} stories")

        except Exception as e:
            logger.error(f"HackerNews search error: {e}")

        return content

    def _aggregate_emotions(self, content: List[Dict], results: List) -> EmotionState:
        """Aggregate sentiment results into emotion state."""
        if not results:
            return EmotionState(timestamp=datetime.utcnow())

        total_weight = 0.0
        weighted_emotions = {
            "happiness": 0.0,
            "sadness": 0.0,
            "anger": 0.0,
            "fear": 0.0,
            "surprise": 0.0,
            "disgust": 0.0,
        }
        weighted_sentiment = 0.0

        for item, result in zip(content, results):
            # Weight by score
            weight = 1.0 + (item.get("score", 0) / 100)
            total_weight += weight

            for emotion, value in result.emotions.items():
                if emotion in weighted_emotions:
                    weighted_emotions[emotion] += value * weight

            weighted_sentiment += result.sentiment_score * weight

        if total_weight == 0:
            return EmotionState(timestamp=datetime.utcnow())

        # Normalize
        for emotion in weighted_emotions:
            weighted_emotions[emotion] /= total_weight
            weighted_emotions[emotion] = min(1.0, max(0.0, weighted_emotions[emotion]))

        weighted_sentiment /= total_weight
        weighted_sentiment = min(1.0, max(-1.0, weighted_sentiment))

        # Calculate secondary emotions
        confusion = min(1.0, weighted_emotions["surprise"] * 0.5 + weighted_emotions["fear"] * 0.3)
        pride = min(1.0, weighted_emotions["happiness"] * 0.3)
        loneliness = min(1.0, weighted_emotions["sadness"] * 0.6 + weighted_emotions["fear"] * 0.2)
        pain = min(1.0, weighted_emotions["sadness"] * 0.4 + weighted_emotions["anger"] * 0.3 + weighted_emotions["fear"] * 0.2)

        # Calculate intensity
        emotion_values = list(weighted_emotions.values())
        avg_emotion = sum(emotion_values) / len(emotion_values)
        intensity = min(1.0, sum(abs(v - avg_emotion) for v in emotion_values) / len(emotion_values) * 3)

        return EmotionState(
            happiness=weighted_emotions["happiness"],
            sadness=weighted_emotions["sadness"],
            anger=weighted_emotions["anger"],
            fear=weighted_emotions["fear"],
            surprise=weighted_emotions["surprise"],
            disgust=weighted_emotions["disgust"],
            confusion=confusion,
            pride=pride,
            loneliness=loneliness,
            pain=pain,
            overall_sentiment=weighted_sentiment,
            intensity=max(0.3, intensity),
            timestamp=datetime.utcnow(),
        )
