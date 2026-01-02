"""Sentiment and emotion analysis using Hugging Face transformers."""
import logging
from typing import Dict, List
from dataclasses import dataclass

from app.core.config import settings

logger = logging.getLogger(__name__)

# Lazy loading for heavy ML dependencies
_emotion_pipeline = None
_sentiment_pipeline = None


def get_emotion_pipeline():
    """Lazy load the emotion classification pipeline."""
    global _emotion_pipeline
    if _emotion_pipeline is None:
        try:
            from transformers import pipeline
            logger.info(f"Loading emotion model: {settings.emotion_model}")
            _emotion_pipeline = pipeline(
                "text-classification",
                model=settings.emotion_model,
                top_k=None,  # Return all labels with scores
                device=-1,  # CPU, use 0 for GPU
            )
            logger.info("Emotion model loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load emotion model: {e}")
            _emotion_pipeline = None
    return _emotion_pipeline


@dataclass
class AnalysisResult:
    """Result of analyzing a single text."""

    emotions: Dict[str, float]
    sentiment_score: float
    confidence: float


class SentimentAnalyzer:
    """Analyzes text for emotion and sentiment."""

    # Mapping from model labels to our emotion categories
    EMOTION_MAP = {
        # j-hartmann/emotion-english-distilroberta-base labels
        "joy": "happiness",
        "sadness": "sadness",
        "anger": "anger",
        "fear": "fear",
        "surprise": "surprise",
        "disgust": "disgust",
        "neutral": None,
    }

    def __init__(self):
        self.pipeline = get_emotion_pipeline()

    def analyze(self, text: str) -> AnalysisResult:
        """Analyze a single text for emotions."""
        if not text or len(text.strip()) < 5:
            return AnalysisResult(
                emotions={},
                sentiment_score=0.0,
                confidence=0.0,
            )

        if self.pipeline is None:
            # Fallback: basic keyword-based analysis
            return self._fallback_analyze(text)

        try:
            # Truncate long text
            text = text[:512]

            results = self.pipeline(text)

            # Convert model output to our emotion format
            emotions = {}
            max_score = 0.0

            for result in results[0]:
                label = result["label"].lower()
                score = result["score"]

                if label in self.EMOTION_MAP and self.EMOTION_MAP[label]:
                    mapped_label = self.EMOTION_MAP[label]
                    emotions[mapped_label] = score

                    if score > max_score:
                        max_score = score

            # Calculate overall sentiment (positive vs negative)
            positive = emotions.get("happiness", 0) + emotions.get("surprise", 0) * 0.3
            negative = (
                emotions.get("sadness", 0) +
                emotions.get("anger", 0) +
                emotions.get("fear", 0) +
                emotions.get("disgust", 0)
            )
            sentiment = (positive - negative) / max(positive + negative, 0.001)

            return AnalysisResult(
                emotions=emotions,
                sentiment_score=max(-1.0, min(1.0, sentiment)),
                confidence=max_score,
            )

        except Exception as e:
            logger.error(f"Analysis error: {e}")
            return self._fallback_analyze(text)

    def analyze_batch(self, texts: List[str]) -> List[AnalysisResult]:
        """Analyze multiple texts efficiently."""
        if not texts:
            return []

        if self.pipeline is None:
            return [self._fallback_analyze(t) for t in texts]

        try:
            # Truncate and filter texts
            valid_texts = [t[:512] for t in texts if t and len(t.strip()) >= 5]

            if not valid_texts:
                return []

            results = self.pipeline(valid_texts)

            analyzed = []
            for result in results:
                emotions = {}
                max_score = 0.0

                for item in result:
                    label = item["label"].lower()
                    score = item["score"]

                    if label in self.EMOTION_MAP and self.EMOTION_MAP[label]:
                        mapped_label = self.EMOTION_MAP[label]
                        emotions[mapped_label] = score

                        if score > max_score:
                            max_score = score

                positive = emotions.get("happiness", 0) + emotions.get("surprise", 0) * 0.3
                negative = (
                    emotions.get("sadness", 0) +
                    emotions.get("anger", 0) +
                    emotions.get("fear", 0) +
                    emotions.get("disgust", 0)
                )
                sentiment = (positive - negative) / max(positive + negative, 0.001)

                analyzed.append(AnalysisResult(
                    emotions=emotions,
                    sentiment_score=max(-1.0, min(1.0, sentiment)),
                    confidence=max_score,
                ))

            return analyzed

        except Exception as e:
            logger.error(f"Batch analysis error: {e}")
            return [self._fallback_analyze(t) for t in texts]

    def _fallback_analyze(self, text: str) -> AnalysisResult:
        """Simple keyword-based fallback when ML model unavailable."""
        text_lower = text.lower()

        # Keyword lists for basic sentiment
        positive_words = {"happy", "great", "good", "love", "amazing", "wonderful", "excellent", "joy", "excited"}
        negative_words = {"sad", "bad", "hate", "terrible", "awful", "angry", "fear", "scared", "worried", "pain"}

        words = set(text_lower.split())
        pos_count = len(words & positive_words)
        neg_count = len(words & negative_words)

        total = pos_count + neg_count
        if total == 0:
            return AnalysisResult(emotions={}, sentiment_score=0.0, confidence=0.1)

        sentiment = (pos_count - neg_count) / total

        # Very basic emotion mapping
        emotions = {}
        if pos_count > neg_count:
            emotions["happiness"] = pos_count / total
        else:
            emotions["sadness"] = neg_count / total * 0.5
            emotions["anger"] = neg_count / total * 0.3

        return AnalysisResult(
            emotions=emotions,
            sentiment_score=sentiment,
            confidence=0.3,  # Low confidence for fallback
        )
