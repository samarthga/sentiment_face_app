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

    logger.info("Running sentiment aggregation job...")
    try:
        aggregator = EmotionAggregator()
        await aggregator.aggregate_all()
        logger.info("Sentiment aggregation completed successfully")
    except Exception as e:
        logger.error(f"Sentiment aggregation failed: {e}")


def start_scheduler():
    """Start the background scheduler."""
    scheduler.add_job(
        aggregate_sentiment_job,
        trigger=IntervalTrigger(minutes=settings.scrape_interval_minutes),
        id="sentiment_aggregation",
        name="Aggregate sentiment from all sources",
        replace_existing=True,
    )
    scheduler.start()
    logger.info(f"Scheduler started with {settings.scrape_interval_minutes} minute interval")


def stop_scheduler():
    """Stop the background scheduler."""
    scheduler.shutdown()
    logger.info("Scheduler stopped")
