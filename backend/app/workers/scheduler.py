"""
Task scheduler for automated alert generation.

This module uses APScheduler to run periodic tasks that generate
alerts for various system events.
"""
import logging
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger
from datetime import datetime

from app.db.session import SessionLocal
from app.workers.alert_tasks import AlertGenerator

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class AlertScheduler:
    """Scheduler for automated alert generation tasks."""

    def __init__(self):
        """Initialize the scheduler."""
        self.scheduler = BackgroundScheduler()
        self._setup_jobs()

    def _setup_jobs(self):
        """Configure scheduled jobs."""

        # Run documento alerts daily at 8:00 AM
        self.scheduler.add_job(
            func=self._run_documento_alerts,
            trigger=CronTrigger(hour=8, minute=0),
            id='documento_alerts',
            name='Generate documento expiration alerts',
            replace_existing=True
        )

        # Run licitacion alerts daily at 7:00 AM
        self.scheduler.add_job(
            func=self._run_licitacion_alerts,
            trigger=CronTrigger(hour=7, minute=0),
            id='licitacion_alerts',
            name='Generate licitacion deadline alerts',
            replace_existing=True
        )

        # Run contrato alerts daily at 8:30 AM
        self.scheduler.add_job(
            func=self._run_contrato_alerts,
            trigger=CronTrigger(hour=8, minute=30),
            id='contrato_alerts',
            name='Generate contrato ending alerts',
            replace_existing=True
        )

        # Run garantia alerts daily at 9:00 AM
        self.scheduler.add_job(
            func=self._run_garantia_alerts,
            trigger=CronTrigger(hour=9, minute=0),
            id='garantia_alerts',
            name='Generate garantia expiration alerts',
            replace_existing=True
        )

        # Run seguimiento alerts every 4 hours
        self.scheduler.add_job(
            func=self._run_seguimiento_alerts,
            trigger=IntervalTrigger(hours=4),
            id='seguimiento_alerts',
            name='Generate CRM follow-up alerts',
            replace_existing=True
        )

        # Run ampliacion alerts daily at 10:00 AM
        self.scheduler.add_job(
            func=self._run_ampliacion_alerts,
            trigger=CronTrigger(hour=10, minute=0),
            id='ampliacion_alerts',
            name='Generate pending ampliacion alerts',
            replace_existing=True
        )

        # Run all alerts together daily at 6:00 AM (morning summary)
        self.scheduler.add_job(
            func=self._run_all_alerts,
            trigger=CronTrigger(hour=6, minute=0),
            id='all_alerts',
            name='Generate all alerts (morning run)',
            replace_existing=True
        )

        # Cleanup old alerts weekly on Sundays at 2:00 AM
        self.scheduler.add_job(
            func=self._cleanup_old_alerts,
            trigger=CronTrigger(day_of_week='sun', hour=2, minute=0),
            id='cleanup_alerts',
            name='Archive old resolved alerts',
            replace_existing=True
        )

        logger.info("Scheduled jobs configured successfully")

    def _run_documento_alerts(self):
        """Run documento alert generation."""
        logger.info("Starting documento alerts generation")
        db = SessionLocal()
        try:
            count = AlertGenerator.generate_documento_alerts(db)
            logger.info(f"Documento alerts completed: {count} alerts created")
        except Exception as e:
            logger.error(f"Error generating documento alerts: {str(e)}")
        finally:
            db.close()

    def _run_licitacion_alerts(self):
        """Run licitacion alert generation."""
        logger.info("Starting licitacion alerts generation")
        db = SessionLocal()
        try:
            count = AlertGenerator.generate_licitacion_alerts(db)
            logger.info(f"Licitacion alerts completed: {count} alerts created")
        except Exception as e:
            logger.error(f"Error generating licitacion alerts: {str(e)}")
        finally:
            db.close()

    def _run_contrato_alerts(self):
        """Run contrato alert generation."""
        logger.info("Starting contrato alerts generation")
        db = SessionLocal()
        try:
            count = AlertGenerator.generate_contrato_alerts(db)
            logger.info(f"Contrato alerts completed: {count} alerts created")
        except Exception as e:
            logger.error(f"Error generating contrato alerts: {str(e)}")
        finally:
            db.close()

    def _run_garantia_alerts(self):
        """Run garantia alert generation."""
        logger.info("Starting garantia alerts generation")
        db = SessionLocal()
        try:
            count = AlertGenerator.generate_garantia_alerts(db)
            logger.info(f"Garantia alerts completed: {count} alerts created")
        except Exception as e:
            logger.error(f"Error generating garantia alerts: {str(e)}")
        finally:
            db.close()

    def _run_seguimiento_alerts(self):
        """Run seguimiento alert generation."""
        logger.info("Starting seguimiento alerts generation")
        db = SessionLocal()
        try:
            count = AlertGenerator.generate_seguimiento_alerts(db)
            logger.info(f"Seguimiento alerts completed: {count} alerts created")
        except Exception as e:
            logger.error(f"Error generating seguimiento alerts: {str(e)}")
        finally:
            db.close()

    def _run_ampliacion_alerts(self):
        """Run ampliacion alert generation."""
        logger.info("Starting ampliacion alerts generation")
        db = SessionLocal()
        try:
            count = AlertGenerator.generate_ampliacion_alerts(db)
            logger.info(f"Ampliacion alerts completed: {count} alerts created")
        except Exception as e:
            logger.error(f"Error generating ampliacion alerts: {str(e)}")
        finally:
            db.close()

    def _run_all_alerts(self):
        """Run all alert generation tasks."""
        logger.info("Starting full alert generation run")
        db = SessionLocal()
        try:
            results = AlertGenerator.run_all_alert_generation(db)
            total = sum(v for k, v in results.items() if k != "archived")
            logger.info(f"Full alert generation completed: {total} total alerts created")
            logger.info(f"Breakdown: {results}")
        except Exception as e:
            logger.error(f"Error in full alert generation: {str(e)}")
        finally:
            db.close()

    def _cleanup_old_alerts(self):
        """Cleanup old resolved alerts."""
        logger.info("Starting alert cleanup")
        db = SessionLocal()
        try:
            count = AlertGenerator.cleanup_old_alerts(db, days=90)
            logger.info(f"Alert cleanup completed: {count} alerts archived")
        except Exception as e:
            logger.error(f"Error cleaning up alerts: {str(e)}")
        finally:
            db.close()

    def start(self):
        """Start the scheduler."""
        logger.info("Starting alert scheduler...")
        self.scheduler.start()
        logger.info("Alert scheduler started successfully")
        logger.info(f"Next job run times:")
        for job in self.scheduler.get_jobs():
            logger.info(f"  - {job.name}: {job.next_run_time}")

    def shutdown(self):
        """Shutdown the scheduler."""
        logger.info("Shutting down alert scheduler...")
        self.scheduler.shutdown()
        logger.info("Alert scheduler stopped")

    def run_now(self, job_id: str = None):
        """
        Run a specific job immediately (for testing).

        Args:
            job_id: ID of the job to run. If None, runs all alerts.
        """
        if job_id:
            job = self.scheduler.get_job(job_id)
            if job:
                logger.info(f"Running job '{job_id}' now...")
                job.func()
            else:
                logger.error(f"Job '{job_id}' not found")
        else:
            logger.info("Running all alerts now...")
            self._run_all_alerts()


# Global scheduler instance
_scheduler = None


def get_scheduler() -> AlertScheduler:
    """Get the global scheduler instance."""
    global _scheduler
    if _scheduler is None:
        _scheduler = AlertScheduler()
    return _scheduler


def start_scheduler():
    """Start the global scheduler."""
    scheduler = get_scheduler()
    scheduler.start()
    return scheduler


def shutdown_scheduler():
    """Shutdown the global scheduler."""
    global _scheduler
    if _scheduler:
        _scheduler.shutdown()
        _scheduler = None
