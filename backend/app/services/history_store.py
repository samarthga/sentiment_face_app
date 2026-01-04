"""Simple JSON-based storage for sentiment history with topics."""
import json
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict, Optional
from collections import Counter
import re

logger = logging.getLogger(__name__)

# Storage file path
HISTORY_FILE = Path(__file__).parent.parent.parent / "data" / "sentiment_history.json"


class SentimentHistoryStore:
    """Stores sentiment history with associated topics."""

    def __init__(self):
        self.history: List[Dict] = []
        self._load()

    def _load(self):
        """Load history from file."""
        try:
            if HISTORY_FILE.exists():
                with open(HISTORY_FILE, 'r') as f:
                    self.history = json.load(f)
                logger.info(f"Loaded {len(self.history)} history records")
        except Exception as e:
            logger.error(f"Failed to load history: {e}")
            self.history = []

    def _save(self):
        """Save history to file."""
        try:
            HISTORY_FILE.parent.mkdir(parents=True, exist_ok=True)
            with open(HISTORY_FILE, 'w') as f:
                json.dump(self.history, f, indent=2, default=str)
        except Exception as e:
            logger.error(f"Failed to save history: {e}")

    def add_entry(self, emotion_state: Dict, topics: List[Dict], sources_summary: Dict):
        """Add a new history entry."""
        entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "emotions": {
                "happiness": emotion_state.get("happiness", 0),
                "sadness": emotion_state.get("sadness", 0),
                "anger": emotion_state.get("anger", 0),
                "fear": emotion_state.get("fear", 0),
                "surprise": emotion_state.get("surprise", 0),
                "disgust": emotion_state.get("disgust", 0),
                "confusion": emotion_state.get("confusion", 0),
                "pride": emotion_state.get("pride", 0),
                "loneliness": emotion_state.get("loneliness", 0),
                "pain": emotion_state.get("pain", 0),
            },
            "overallSentiment": emotion_state.get("overall_sentiment", 0),
            "intensity": emotion_state.get("intensity", 0.5),
            "topics": topics,  # List of {topic, count, sentiment}
            "sources": sources_summary,  # {source: count}
            "dominantEmotion": self._get_dominant_emotion(emotion_state),
        }

        self.history.append(entry)

        # Keep last 1000 entries (about 8 hours at 30s intervals)
        if len(self.history) > 1000:
            self.history = self.history[-1000:]

        self._save()
        logger.info(f"Added history entry with {len(topics)} topics")

    def _get_dominant_emotion(self, emotion_state: Dict) -> str:
        """Get the dominant emotion name."""
        emotions = {
            "happiness": emotion_state.get("happiness", 0),
            "sadness": emotion_state.get("sadness", 0),
            "anger": emotion_state.get("anger", 0),
            "fear": emotion_state.get("fear", 0),
            "surprise": emotion_state.get("surprise", 0),
            "disgust": emotion_state.get("disgust", 0),
            "confusion": emotion_state.get("confusion", 0),
            "pride": emotion_state.get("pride", 0),
            "loneliness": emotion_state.get("loneliness", 0),
            "pain": emotion_state.get("pain", 0),
        }
        return max(emotions, key=emotions.get)

    def get_history(
        self,
        from_date: Optional[datetime] = None,
        to_date: Optional[datetime] = None,
        limit: int = 100
    ) -> List[Dict]:
        """Get history entries within date range."""
        result = self.history

        if from_date:
            result = [
                h for h in result
                if datetime.fromisoformat(h["timestamp"]) >= from_date
            ]

        if to_date:
            result = [
                h for h in result
                if datetime.fromisoformat(h["timestamp"]) <= to_date
            ]

        # Return most recent first
        return list(reversed(result[-limit:]))

    def get_trending_topics(self, hours: int = 1, limit: int = 10) -> List[Dict]:
        """Get trending topics from recent history."""
        cutoff = datetime.utcnow() - timedelta(hours=hours)

        topic_stats = {}

        for entry in self.history:
            entry_time = datetime.fromisoformat(entry["timestamp"])
            if entry_time >= cutoff:
                for topic in entry.get("topics", []):
                    name = topic["topic"]
                    if name not in topic_stats:
                        topic_stats[name] = {
                            "count": 0,
                            "sentiment_sum": 0,
                            "emotions": Counter()
                        }
                    topic_stats[name]["count"] += topic.get("count", 1)
                    topic_stats[name]["sentiment_sum"] += topic.get("sentiment", 0)
                    topic_stats[name]["emotions"][entry["dominantEmotion"]] += 1

        # Calculate averages and sort by count
        trending = []
        for name, stats in topic_stats.items():
            trending.append({
                "topic": name,
                "mentions": stats["count"],
                "avgSentiment": stats["sentiment_sum"] / max(stats["count"], 1),
                "dominantEmotion": stats["emotions"].most_common(1)[0][0] if stats["emotions"] else "neutral"
            })

        trending.sort(key=lambda x: x["mentions"], reverse=True)
        return trending[:limit]


class TopicExtractor:
    """Extracts topics from scraped content."""

    # Common stop words to filter out
    STOP_WORDS = {
        'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
        'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'been',
        'be', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would',
        'could', 'should', 'may', 'might', 'must', 'shall', 'can', 'need',
        'this', 'that', 'these', 'those', 'i', 'you', 'he', 'she', 'it',
        'we', 'they', 'what', 'which', 'who', 'whom', 'when', 'where', 'why',
        'how', 'all', 'each', 'every', 'both', 'few', 'more', 'most', 'other',
        'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so',
        'than', 'too', 'very', 's', 't', 'just', 'don', 'now', 'new', 'says',
        'said', 'get', 'got', 'like', 'also', 'one', 'two', 'first', 'after',
        'over', 'into', 'its', 'about', 'up', 'out', 'if', 'then', 'their',
        'there', 'here', 'his', 'her', 'my', 'your', 'our', 'us', 'me', 'him',
        'them', 'being', 'between', 'through', 'during', 'before', 'after',
        'above', 'below', 'while', 'because', 'against', 'without', 'within',
        'along', 'following', 'across', 'behind', 'beyond', 'plus', 'except',
        'per', 'via', 'amp', 'vs', 'via', 'etc', 'ie', 'eg', 'ask', 'hn',
        'show', 'tell', 'why', 'how', 'year', 'years', 'day', 'days', 'time',
        'way', 'make', 'made', 'people', 'world', 'back', 'much', 'even',
    }

    # Generic/vague words to filter out
    GENERIC_WORDS = {
        'low', 'high', 'big', 'small', 'good', 'bad', 'best', 'worst',
        'team', 'teams', 'event', 'events', 'thing', 'things', 'stuff',
        'part', 'parts', 'place', 'places', 'point', 'points', 'case',
        'fact', 'facts', 'issue', 'issues', 'item', 'items', 'kind',
        'lot', 'lots', 'number', 'numbers', 'group', 'groups', 'area',
        'areas', 'end', 'start', 'begin', 'side', 'sides', 'top', 'bottom',
        'left', 'right', 'front', 'back', 'line', 'lines', 'level', 'levels',
        'type', 'types', 'form', 'forms', 'state', 'states', 'action',
        'change', 'changes', 'result', 'results', 'work', 'works', 'name',
        'use', 'uses', 'user', 'users', 'data', 'info', 'information',
        'system', 'systems', 'service', 'services', 'program', 'process',
        'today', 'week', 'month', 'title', 'post', 'posts', 'comment',
        'comments', 'update', 'updates', 'report', 'reports', 'news',
        'story', 'stories', 'article', 'articles', 'video', 'videos',
        'image', 'images', 'photo', 'photos', 'link', 'links', 'source',
        'sources', 'page', 'pages', 'site', 'sites', 'web', 'online',
        'app', 'apps', 'company', 'companies', 'business', 'market',
        'price', 'prices', 'cost', 'costs', 'value', 'money', 'pay',
        'deal', 'deals', 'offer', 'offers', 'sale', 'sales', 'buy',
        'sell', 'sold', 'free', 'available', 'support', 'help', 'need',
        'want', 'look', 'looks', 'looking', 'find', 'found', 'search',
        'read', 'write', 'written', 'call', 'called', 'calling', 'run',
        'running', 'goes', 'going', 'come', 'coming', 'came', 'take',
        'takes', 'taken', 'give', 'gives', 'given', 'see', 'seen', 'saw',
        'know', 'known', 'think', 'thought', 'feel', 'felt', 'seem',
        'seems', 'try', 'tried', 'keep', 'keeps', 'let', 'put', 'set',
        'turn', 'turned', 'move', 'moved', 'open', 'close', 'closed',
        'play', 'played', 'watch', 'watched', 'live', 'lives', 'living',
        'real', 'actually', 'really', 'probably', 'maybe', 'likely',
        'possible', 'sure', 'true', 'false', 'wrong', 'right', 'long',
        'short', 'full', 'empty', 'old', 'young', 'early', 'late',
        'hard', 'easy', 'fast', 'slow', 'different', 'similar', 'same',
        'last', 'next', 'many', 'several', 'couple', 'ago', 'still',
        'yet', 'already', 'ever', 'never', 'always', 'often', 'sometimes',
        'usually', 'however', 'though', 'although', 'despite', 'instead',
        'rather', 'quite', 'pretty', 'almost', 'nearly', 'exactly',
        'simply', 'finally', 'actually', 'basically', 'essentially',
        'apparently', 'obviously', 'clearly', 'certainly', 'definitely',
        'biggest', 'largest', 'smallest', 'latest', 'newest', 'oldest',
        'electric', 'global', 'local', 'national', 'international',
        'public', 'private', 'official', 'major', 'minor', 'main',
        'total', 'average', 'general', 'specific', 'special', 'recent',
        'current', 'former', 'future', 'past', 'present', 'original',
        'million', 'billion', 'thousand', 'hundred', 'percent', 'half',
        'third', 'quarter', 'double', 'single', 'multiple', 'various',
        'loses', 'lost', 'wins', 'won', 'shows', 'shown', 'says', 'says',
        'gets', 'getting', 'makes', 'making', 'takes', 'taking', 'becomes',
        'becomes', 'capture', 'captured', 'captures', 'capturing',
        'launch', 'launched', 'launches', 'launching', 'release', 'released',
        'announce', 'announced', 'reveals', 'revealed', 'claims', 'claimed',
    }

    # Word stem mappings to normalize variations
    STEM_MAPPINGS = {
        'captured': 'capture', 'captures': 'capture', 'capturing': 'capture',
        'launched': 'launch', 'launches': 'launch', 'launching': 'launch',
        'released': 'release', 'releases': 'release', 'releasing': 'release',
        'announced': 'announce', 'announces': 'announce', 'announcing': 'announce',
        'revealed': 'reveal', 'reveals': 'reveal', 'revealing': 'reveal',
        'claimed': 'claim', 'claims': 'claim', 'claiming': 'claim',
        'reported': 'report', 'reports': 'report', 'reporting': 'report',
        'showed': 'show', 'shows': 'show', 'showing': 'show',
        'started': 'start', 'starts': 'start', 'starting': 'start',
        'ended': 'end', 'ends': 'end', 'ending': 'end',
        'killed': 'kill', 'kills': 'kill', 'killing': 'kill',
        'died': 'die', 'dies': 'die', 'dying': 'die', 'death': 'die',
        'tested': 'test', 'tests': 'test', 'testing': 'test',
        'built': 'build', 'builds': 'build', 'building': 'build',
        'created': 'create', 'creates': 'create', 'creating': 'create',
    }

    def extract_topics(
        self,
        contents: List[Dict],
        results: List[Dict],
        limit: int = 10
    ) -> List[Dict]:
        """Extract topics from scraped content with sentiment association."""
        word_stats = {}

        for content, result in zip(contents, results):
            # Get title - most important for topic extraction
            title = content.get("title", "") or content.get("text", "")[:100]

            # Extract meaningful words (2+ chars, not numbers, not stop words)
            words = self._extract_words(title)
            sentiment = result.get("sentiment_score", 0) if result else 0

            for word in words:
                if word not in word_stats:
                    word_stats[word] = {
                        "count": 0,
                        "sentiment_sum": 0,
                    }
                word_stats[word]["count"] += 1
                word_stats[word]["sentiment_sum"] += sentiment

        # Convert to list and sort by frequency
        topics = []
        for word, stats in word_stats.items():
            if stats["count"] >= 2:  # Only include words that appear 2+ times
                topics.append({
                    "topic": word,
                    "count": stats["count"],
                    "sentiment": stats["sentiment_sum"] / stats["count"]
                })

        topics.sort(key=lambda x: x["count"], reverse=True)
        return topics[:limit]

    def _extract_words(self, text: str) -> List[str]:
        """Extract meaningful words from text."""
        # Lowercase and extract words (at least 3 chars)
        text = text.lower()
        words = re.findall(r'\b[a-z]{3,}\b', text)

        # Filter stop words, generic words, and normalize stems
        filtered = []
        seen = set()
        for word in words:
            # Skip stop words and generic words
            if word in self.STOP_WORDS or word in self.GENERIC_WORDS:
                continue

            # Normalize word using stem mappings
            normalized = self.STEM_MAPPINGS.get(word, word)

            # Skip if already seen (after normalization)
            if normalized in seen:
                continue

            # Skip very short words after normalization
            if len(normalized) < 3:
                continue

            filtered.append(normalized)
            seen.add(normalized)

        return filtered


# Global instances
history_store = SentimentHistoryStore()
topic_extractor = TopicExtractor()
