"""Aggregates sentiment from multiple sources into a unified emotion state."""
import logging
from datetime import datetime
from typing import Dict, List, Tuple

from app.models.emotion import EmotionState
from app.services.sentiment_analyzer import SentimentAnalyzer, AnalysisResult
from app.services.scrapers.base_scraper import ScrapedContent
from app.services.scrapers.reddit_scraper import RedditScraper
from app.services.scrapers.hackernews_scraper import HackerNewsScraper
from app.services.scrapers.rss_scraper import RSSScraper
from app.services.history_store import history_store, topic_extractor

logger = logging.getLogger(__name__)


class EmotionAggregator:
    """Aggregates emotions from multiple content sources."""

    def __init__(self):
        self.analyzer = SentimentAnalyzer()
        self.scrapers = [
            RedditScraper(),
            HackerNewsScraper(),
            RSSScraper(),
        ]

    async def aggregate_all(self) -> EmotionState:
        """Scrape and aggregate sentiment from all sources."""
        all_content: List[ScrapedContent] = []
        source_content: Dict[str, List[ScrapedContent]] = {}

        # Scrape from all sources
        for scraper in self.scrapers:
            try:
                content = await scraper.scrape(limit=50)
                all_content.extend(content)
                source_content[scraper.source_name] = content
                logger.info(f"Scraped {len(content)} items from {scraper.source_name}")
            except Exception as e:
                logger.error(f"Error scraping {scraper.source_name}: {e}")

        if not all_content:
            logger.warning("No content scraped from any source")
            return EmotionState(timestamp=datetime.utcnow())

        # Analyze all content
        texts = [c.text for c in all_content]
        results = self.analyzer.analyze_batch(texts)

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
        age_hours = (datetime.utcnow() - timestamp).total_seconds() / 3600

        # Exponential decay: halve weight every 24 hours
        decay_rate = 0.693 / 24  # ln(2) / 24 hours
        return max(0.1, 2.718 ** (-decay_rate * age_hours))
