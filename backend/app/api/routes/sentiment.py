"""Sentiment API endpoints."""
import asyncio
import json
from datetime import datetime, timedelta
from typing import List, Optional, Dict
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query

from app.models.emotion import EmotionState, SourceSentiment
from app.services.emotion_aggregator import EmotionAggregator
from app.services.history_store import history_store

router = APIRouter()

# Store for connected WebSocket clients
connected_clients: List[WebSocket] = []

# Cache for current emotion state (in production, use Redis)
_current_emotion: Optional[EmotionState] = None
_last_updated: Optional[datetime] = None


def get_current_emotion() -> EmotionState:
    """Get the current aggregated emotion state."""
    global _current_emotion, _last_updated

    if _current_emotion is None:
        # Return a default state if no data yet
        _current_emotion = EmotionState(
            happiness=0.3,
            sadness=0.1,
            anger=0.15,
            fear=0.05,
            surprise=0.2,
            disgust=0.05,
            confusion=0.1,
            pride=0.05,
            overall_sentiment=0.2,
            intensity=0.5,
            timestamp=datetime.utcnow(),
            source_contributions={
                "reddit": 0.4,
                "hackernews": 0.35,
                "rss": 0.25,
            },
        )
        _last_updated = datetime.utcnow()

    return _current_emotion


def update_current_emotion(emotion: EmotionState):
    """Update the current emotion state and notify WebSocket clients."""
    global _current_emotion, _last_updated
    _current_emotion = emotion
    _last_updated = datetime.utcnow()

    # Notify connected clients
    asyncio.create_task(broadcast_emotion(emotion))


async def broadcast_emotion(emotion: EmotionState):
    """Broadcast emotion update to all connected WebSocket clients."""
    if not connected_clients:
        return

    message = emotion.model_dump_json(by_alias=True)
    disconnected = []

    for client in connected_clients:
        try:
            await client.send_text(message)
        except Exception:
            disconnected.append(client)

    # Remove disconnected clients
    for client in disconnected:
        connected_clients.remove(client)


@router.get("/available-sources")
async def get_available_sources():
    """Get list of available data sources."""
    aggregator = EmotionAggregator()
    sources = aggregator.get_available_sources()
    return {
        "sources": sources,
        "count": len(sources),
    }


@router.get("/current", response_model=EmotionState)
async def get_current_sentiment(
    sources: Optional[str] = Query(
        None,
        description="Comma-separated list of sources to include (e.g., 'reddit,bluesky')"
    )
):
    """Get the current aggregated emotion state.

    Optionally filter by specific sources.
    """
    # If no sources specified, return cached emotion
    if not sources:
        return get_current_emotion()

    # Parse sources and fetch filtered data
    source_list = [s.strip().lower() for s in sources.split(",") if s.strip()]
    if not source_list:
        return get_current_emotion()

    # For filtered requests, we need to re-aggregate with selected sources
    aggregator = EmotionAggregator()
    emotion = await aggregator.aggregate_all(sources=source_list)
    return emotion


@router.get("/history")
async def get_sentiment_history(
    from_date: Optional[datetime] = Query(None, alias="from"),
    to_date: Optional[datetime] = Query(None, alias="to"),
    limit: int = Query(100, ge=1, le=1000),
):
    """Get historical sentiment data with topics."""
    # Default to last 24 hours if no date specified
    if from_date is None:
        from_date = datetime.utcnow() - timedelta(hours=24)

    history = history_store.get_history(
        from_date=from_date,
        to_date=to_date,
        limit=limit
    )

    return {
        "data": history,
        "count": len(history),
        "from": from_date.isoformat() if from_date else None,
        "to": to_date.isoformat() if to_date else None,
    }


@router.get("/topics")
async def get_trending_topics(
    hours: int = Query(1, ge=1, le=24),
    limit: int = Query(10, ge=1, le=50),
):
    """Get trending topics from recent sentiment analysis."""
    topics = history_store.get_trending_topics(hours=hours, limit=limit)
    return {
        "topics": topics,
        "hours": hours,
        "timestamp": datetime.utcnow().isoformat(),
    }


@router.get("/current/detailed")
async def get_current_sentiment_detailed():
    """Get current emotion state with topics."""
    emotion = get_current_emotion()

    # Get recent topics from history
    recent_history = history_store.get_history(limit=1)
    topics = recent_history[0].get("topics", []) if recent_history else []

    return {
        "emotion": emotion.model_dump(by_alias=True),
        "topics": topics,
        "timestamp": datetime.utcnow().isoformat(),
    }


@router.get("/sources")
async def get_sentiment_by_source(
    sources: Optional[str] = Query(None, description="Comma-separated list of sources to include")
):
    """Get real sentiment breakdown by source with topics.

    Each source returns:
    - source: The source name
    - emotion: The EmotionState for that source
    - top_topic: The keyword/topic driving the emotion
    - topic_sentiment: Sentiment score for the topic
    - sample_titles: Sample headlines from the source
    - post_count: Number of posts analyzed
    """
    aggregator = EmotionAggregator()

    # Parse sources filter
    source_list = None
    if sources:
        source_list = [s.strip().lower() for s in sources.split(",") if s.strip()]

    # Get real per-source emotions with topics
    per_source = await aggregator.aggregate_per_source(sources=source_list)

    # Get aggregate for comparison
    current = get_current_emotion()

    return {
        "sources": {k: v.model_dump(by_alias=True) for k, v in per_source.items()},
        "aggregate": current.model_dump(by_alias=True),
        "timestamp": datetime.utcnow().isoformat(),
    }


@router.websocket("/stream")
async def sentiment_stream(websocket: WebSocket):
    """WebSocket endpoint for real-time sentiment updates."""
    await websocket.accept()
    connected_clients.append(websocket)

    try:
        # Send current state immediately
        current = get_current_emotion()
        await websocket.send_text(current.model_dump_json(by_alias=True))

        # Keep connection alive
        while True:
            try:
                # Wait for any message (ping/pong)
                await websocket.receive_text()
            except WebSocketDisconnect:
                break
    finally:
        if websocket in connected_clients:
            connected_clients.remove(websocket)


@router.post("/refresh")
async def refresh_sentiment(
    sources: Optional[str] = Query(
        None,
        description="Comma-separated list of sources to include (e.g., 'reddit,bluesky')"
    )
):
    """Manually trigger sentiment aggregation.

    Optionally filter by specific sources.
    """
    aggregator = EmotionAggregator()

    source_list = None
    if sources:
        source_list = [s.strip().lower() for s in sources.split(",") if s.strip()]

    emotion = await aggregator.aggregate_all(sources=source_list)
    update_current_emotion(emotion)
    return {"status": "refreshed", "emotion": emotion.model_dump(by_alias=True)}


# Store for active search topic
_active_search_topic: Optional[str] = None


def get_active_search_topic() -> Optional[str]:
    """Get the currently active search topic."""
    return _active_search_topic


def set_active_search_topic(topic: Optional[str]):
    """Set the active search topic."""
    global _active_search_topic
    _active_search_topic = topic


@router.post("/search")
async def search_topic(query: str = Query(..., min_length=2, max_length=100)):
    """Search and analyze sentiment for a specific topic."""
    from app.services.topic_searcher import TopicSearcher

    set_active_search_topic(query.lower())

    searcher = TopicSearcher()
    result = await searcher.search_topic(query)

    # Update current emotion with search results
    if result.get("emotion"):
        emotion = EmotionState(**result["emotion"])
        update_current_emotion(emotion)

    return result


@router.delete("/search")
async def clear_search():
    """Clear the active search topic."""
    set_active_search_topic(None)
    return {"status": "cleared"}


@router.get("/search/status")
async def get_search_status():
    """Get the current search status."""
    return {
        "active": _active_search_topic is not None,
        "topic": _active_search_topic,
    }


@router.get("/emotion-topics")
async def get_emotion_topics():
    """Get topics associated with each emotion from recent history."""
    # Get recent history entries
    recent = history_store.get_history(limit=50)

    # Map emotions to their associated topics with weighted scores
    emotion_topics: Dict[str, Dict[str, float]] = {
        "happiness": {},
        "sadness": {},
        "anger": {},
        "fear": {},
        "surprise": {},
        "disgust": {},
        "confusion": {},
        "pride": {},
        "loneliness": {},
        "pain": {},
    }

    # Threshold for considering an emotion "active" for a topic (lowered to catch more associations)
    EMOTION_THRESHOLD = 0.01

    for entry in recent:
        emotions = entry.get("emotions", {})
        topics = entry.get("topics", [])

        for topic_data in topics:
            topic_name = topic_data.get("topic", "")
            if not topic_name:
                continue

            # Associate topic with ALL emotions that are elevated
            for emotion_name, emotion_value in emotions.items():
                if emotion_name in emotion_topics and emotion_value >= EMOTION_THRESHOLD:
                    # Weight by emotion intensity
                    current = emotion_topics[emotion_name].get(topic_name, 0)
                    emotion_topics[emotion_name][topic_name] = current + emotion_value

    # Convert to sorted lists (top 5 topics per emotion)
    result = {}
    for emotion, topics in emotion_topics.items():
        sorted_topics = sorted(topics.items(), key=lambda x: x[1], reverse=True)[:5]
        result[emotion] = [t[0] for t in sorted_topics]

    return result
