"""Background task scheduler for sentiment aggregation."""
import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger

from app.core.config import settings

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()


async def aggregate_sentiment_job():
    """Job that runs periodically to aggregate sentiment from all sources."""
    from app.services.emotion_aggregator import EmotionAggregator
    from app.api.routes.sentiment import update_current_emotion

    logger.info("Running sentiment aggregation job...")
    try:
        aggregator = EmotionAggregator()
        emotion = await aggregator.aggregate_all()
        update_current_emotion(emotion)
        logger.info(
            f"Emotions - happy:{emotion.happiness:.3f} sad:{emotion.sadness:.3f} "
            f"angry:{emotion.anger:.3f} fear:{emotion.fear:.3f} "
            f"surprise:{emotion.surprise:.3f} disgust:{emotion.disgust:.3f}"
        )
    except Exception as e:
        logger.error(f"Sentiment aggregation failed: {e}")


def start_scheduler():
    """Start the background scheduler."""
    # Use seconds if interval is less than 1 minute, otherwise use minutes
    interval_seconds = getattr(settings, 'scrape_interval_seconds', None)
    if interval_seconds:
        trigger = IntervalTrigger(seconds=interval_seconds)
        interval_msg = f"{interval_seconds} second"
    else:
        trigger = IntervalTrigger(minutes=settings.scrape_interval_minutes)
        interval_msg = f"{settings.scrape_interval_minutes} minute"

    scheduler.add_job(
        aggregate_sentiment_job,
        trigger=trigger,
        id="sentiment_aggregation",
        name="Aggregate sentiment from all sources",
        replace_existing=True,
    )
    scheduler.start()
    logger.info(f"Scheduler started with {interval_msg} interval")


def stop_scheduler():
    """Stop the background scheduler."""
    scheduler.shutdown()
    logger.info("Scheduler stopped")
