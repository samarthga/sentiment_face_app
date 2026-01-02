"""Sentiment API endpoints."""
import asyncio
import json
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query

from app.models.emotion import EmotionState, SourceSentiment
from app.services.emotion_aggregator import EmotionAggregator

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


@router.get("/current", response_model=EmotionState)
async def get_current_sentiment():
    """Get the current aggregated emotion state."""
    return get_current_emotion()


@router.get("/history")
async def get_sentiment_history(
    from_date: Optional[datetime] = Query(None, alias="from"),
    to_date: Optional[datetime] = Query(None, alias="to"),
    limit: int = Query(100, ge=1, le=1000),
):
    """Get historical sentiment data."""
    # TODO: Implement database query
    # For now, return mock data
    current = get_current_emotion()
    return {
        "data": [current.model_dump(by_alias=True)],
        "count": 1,
        "from": from_date,
        "to": to_date,
    }


@router.get("/sources")
async def get_sentiment_by_source():
    """Get sentiment breakdown by source."""
    current = get_current_emotion()

    # Generate per-source states (mock data for now)
    sources = {
        "reddit": EmotionState(
            happiness=0.35,
            sadness=0.15,
            anger=0.2,
            overall_sentiment=0.15,
            timestamp=datetime.utcnow(),
        ),
        "hackernews": EmotionState(
            happiness=0.25,
            sadness=0.1,
            anger=0.1,
            surprise=0.3,
            overall_sentiment=0.25,
            timestamp=datetime.utcnow(),
        ),
        "rss": EmotionState(
            happiness=0.3,
            sadness=0.2,
            anger=0.15,
            fear=0.1,
            overall_sentiment=0.1,
            timestamp=datetime.utcnow(),
        ),
    }

    return {
        "sources": {k: v.model_dump(by_alias=True) for k, v in sources.items()},
        "aggregate": current.model_dump(by_alias=True),
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
async def refresh_sentiment():
    """Manually trigger sentiment aggregation."""
    aggregator = EmotionAggregator()
    emotion = await aggregator.aggregate_all()
    update_current_emotion(emotion)
    return {"status": "refreshed", "emotion": emotion.model_dump(by_alias=True)}
