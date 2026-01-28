"""Aggregates sentiment from multiple sources into a unified emotion state."""
import logging
import time
from datetime import datetime
from typing import Dict, List, Tuple, Optional

from app.models.emotion import EmotionState
from app.models.source_emotion import SourceEmotionState
from app.services.sentiment_analyzer import SentimentAnalyzer, AnalysisResult
from app.services.scrapers.base_scraper import ScrapedContent
from app.services.scrapers.reddit_scraper import RedditScraper
from app.services.scrapers.hackernews_scraper import HackerNewsScraper
from app.services.scrapers.rss_scraper import RSSScraper
from app.services.scrapers.bluesky_scraper import BlueskyScraper
from app.services.scrapers.truthsocial_scraper import TruthSocialScraper
from app.services.history_store import history_store, topic_extractor

logger = logging.getLogger(__name__)

# Cache for scraped content per source (source_name -> (timestamp, content, analysis))
_content_cache: Dict[str, Tuple[float, List[ScrapedContent], List[AnalysisResult]]] = {}
CACHE_TTL_SECONDS = 120  # 2 minutes cache


class EmotionAggregator:
    """Aggregates emotions from multiple content sources."""

    def __init__(self):
        self.analyzer = SentimentAnalyzer()
        self.scrapers = [
            RedditScraper(),
            HackerNewsScraper(),
            RSSScraper(),
            BlueskyScraper(),
            TruthSocialScraper(),
        ]

    def get_available_sources(self) -> List[str]:
        """Get list of available source names."""
        return [scraper.source_name for scraper in self.scrapers]

    async def aggregate_all(self, sources: Optional[List[str]] = None) -> EmotionState:
        """Scrape and aggregate sentiment from all sources.

        Args:
            sources: Optional list of source names to include. If None, uses all sources.
        """
        global _content_cache

        all_content: List[ScrapedContent] = []
        all_results: List[AnalysisResult] = []
        source_content: Dict[str, List[ScrapedContent]] = {}

        # Filter scrapers if sources specified
        active_scrapers = self.scrapers
        if sources:
            valid_sources = set(s.lower() for s in sources)
            active_scrapers = [s for s in self.scrapers if s.source_name.lower() in valid_sources]

        if not active_scrapers:
            logger.warning("No valid scrapers selected, using all sources")
            active_scrapers = self.scrapers

        # Scrape from selected sources (with caching)
        current_time = time.time()
        for scraper in active_scrapers:
            source_name = scraper.source_name
            try:
                # Check if we have valid cached data
                if source_name in _content_cache:
                    cache_time, cached_content, cached_results = _content_cache[source_name]
                    if current_time - cache_time < CACHE_TTL_SECONDS:
                        # Use cached data
                        all_content.extend(cached_content)
                        all_results.extend(cached_results)
                        source_content[source_name] = cached_content
                        logger.info(f"Using cached {len(cached_content)} items from {source_name}")
                        continue

                # Cache miss or expired - scrape fresh data
                content = await scraper.scrape(limit=25)  # Reduced from 50
                all_content.extend(content)
                source_content[source_name] = content

                # Analyze this source's content and cache it
                if content:
                    texts = [c.text for c in content]
                    results = self.analyzer.analyze_batch(texts)
                    all_results.extend(results)
                    # Store in cache
                    _content_cache[source_name] = (current_time, content, results)

                logger.info(f"Scraped {len(content)} items from {source_name}")
            except Exception as e:
                logger.error(f"Error scraping {source_name}: {e}")

        if not all_content:
            logger.warning("No content scraped from any source")
            return EmotionState(timestamp=datetime.utcnow())

        # Use pre-analyzed results (from cache or fresh analysis in loop above)
        results = all_results

        # Extract topics from content
        content_dicts = [{"title": c.title, "text": c.text} for c in all_content]
        result_dicts = [{"sentiment_score": r.sentiment_score} for r in results]
        topics = topic_extractor.extract_topics(content_dicts, result_dicts, limit=10)

        # Aggregate results
        emotion_state = self._aggregate_results(all_content, results, source_content)

        # Store in history
        sources_summary = {source: len(items) for source, items in source_content.items()}
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
            topics=topics,
            sources_summary=sources_summary,
        )

        # Store topics on the emotion state for API access
        self._last_topics = topics

        return emotion_state

    def get_last_topics(self) -> List[Dict]:
        """Get topics from the last aggregation."""
        return getattr(self, '_last_topics', [])

    async def aggregate_per_source(
        self, sources: Optional[List[str]] = None
    ) -> Dict[str, SourceEmotionState]:
        """Get emotion state for each source individually with topic information.

        Args:
            sources: Optional list of source names to include. If None, uses all sources.

        Returns:
            Dictionary mapping source name to SourceEmotionState.
        """
        global _content_cache

        result: Dict[str, SourceEmotionState] = {}

        # Filter scrapers if sources specified
        active_scrapers = self.scrapers
        if sources:
            valid_sources = set(s.lower() for s in sources)
            active_scrapers = [s for s in self.scrapers if s.source_name.lower() in valid_sources]

        if not active_scrapers:
            logger.warning("No valid scrapers selected, using all sources")
            active_scrapers = self.scrapers

        current_time = time.time()

        for scraper in active_scrapers:
            source_name = scraper.source_name
            try:
                content: List[ScrapedContent] = []
                results: List[AnalysisResult] = []

                # Check cache first
                if source_name in _content_cache:
                    cache_time, cached_content, cached_results = _content_cache[source_name]
                    if current_time - cache_time < CACHE_TTL_SECONDS:
                        content = cached_content
                        results = cached_results
                        logger.info(f"Using cached {len(content)} items from {source_name}")

                # Scrape if no cache
                if not content:
                    content = await scraper.scrape(limit=25)
                    if content:
                        texts = [c.text for c in content]
                        results = self.analyzer.analyze_batch(texts)
                        _content_cache[source_name] = (current_time, content, results)
                    logger.info(f"Scraped {len(content)} items from {source_name}")

                if not content or not results:
                    continue

                # Calculate emotion state for this source
                source_emotion = self._aggregate_single_source(content, results)

                # Extract top topic for this source
                content_dicts = [{"title": c.title, "text": c.text} for c in content]
                result_dicts = [{"sentiment_score": r.sentiment_score} for r in results]
                topics = topic_extractor.extract_topics(content_dicts, result_dicts, limit=1)

                top_topic = topics[0]["topic"] if topics else source_name
                topic_sentiment = topics[0].get("sentiment", 0.0) if topics else 0.0

                # Get sample titles (first 3)
                sample_titles = [c.title for c in content[:3] if c.title]

                result[source_name] = SourceEmotionState(
                    source=source_name,
                    emotion=source_emotion,
                    top_topic=top_topic,
                    topic_sentiment=topic_sentiment,
                    sample_titles=sample_titles,
                    post_count=len(content),
                    last_updated=datetime.utcnow(),
                )

            except Exception as e:
                logger.error(f"Error processing {source_name}: {e}")

        return result

    def _aggregate_single_source(
        self,
        content: List[ScrapedContent],
        results: List[AnalysisResult],
    ) -> EmotionState:
        """Aggregate analysis results from a single source into an emotion state."""
        if not results:
            return EmotionState(timestamp=datetime.utcnow())

        total_weight = 0.0
        weighted_emotions: Dict[str, float] = {
            "happiness": 0.0,
            "sadness": 0.0,
            "anger": 0.0,
            "fear": 0.0,
            "surprise": 0.0,
            "disgust": 0.0,
        }
        weighted_sentiment = 0.0

        for item, result in zip(content, results):
            engagement_weight = 1.0 + (item.score / 1000)
            recency_weight = self._calculate_recency_weight(item.timestamp)
            confidence_weight = result.confidence

            weight = engagement_weight * recency_weight * confidence_weight
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
        loneliness = min(1.0, weighted_emotions["sadness"] * 0.5)
        pain = min(1.0, weighted_emotions["sadness"] * 0.3 + weighted_emotions["fear"] * 0.2)

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

    def _aggregate_results(
        self,
        content: List[ScrapedContent],
        results: List[AnalysisResult],
        source_content: Dict[str, List[ScrapedContent]],
    ) -> EmotionState:
        """Aggregate analysis results into a single emotion state."""
        if not results:
            return EmotionState(timestamp=datetime.utcnow())

        # Weighted aggregation based on engagement (score) and recency
        total_weight = 0.0
        weighted_emotions: Dict[str, float] = {
            "happiness": 0.0,
            "sadness": 0.0,
            "anger": 0.0,
            "fear": 0.0,
            "surprise": 0.0,
            "disgust": 0.0,
        }
        weighted_sentiment = 0.0

        for i, (item, result) in enumerate(zip(content, results)):
            # Weight based on engagement and recency
            engagement_weight = 1.0 + (item.score / 1000)  # Normalize score
            recency_weight = self._calculate_recency_weight(item.timestamp)
            confidence_weight = result.confidence

            weight = engagement_weight * recency_weight * confidence_weight
            total_weight += weight

            # Accumulate weighted emotions
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

        # Calculate source contributions
        source_contributions = {}
        total_items = len(content)
        for source, items in source_content.items():
            source_contributions[source] = len(items) / total_items if total_items > 0 else 0

        # Calculate secondary emotions
        confusion = min(1.0, weighted_emotions["surprise"] * 0.5 + weighted_emotions["fear"] * 0.3)
        pride = min(1.0, weighted_emotions["happiness"] * 0.3)
        loneliness = min(1.0, weighted_emotions["sadness"] * 0.5)
        pain = min(1.0, weighted_emotions["sadness"] * 0.3 + weighted_emotions["fear"] * 0.2)

        # Calculate intensity based on variance of emotions
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
            source_contributions=source_contributions,
        )

    def _calculate_recency_weight(self, timestamp: datetime) -> float:
        """Calculate weight based on how recent the content is."""
        # Handle both timezone-aware and naive datetimes
        now = datetime.utcnow()
        ts = timestamp

        # If timestamp has timezone, remove it for comparison
        if ts.tzinfo is not None:
            ts = ts.replace(tzinfo=None)

        try:
            age_hours = (now - ts).total_seconds() / 3600
        except TypeError:
            # Fallback if datetime comparison fails
            age_hours = 1.0

        # Exponential decay: halve weight every 24 hours
        decay_rate = 0.693 / 24  # ln(2) / 24 hours
        return max(0.1, 2.718 ** (-decay_rate * age_hours))
