#!/usr/bin/env python3
"""
Alert Worker Runner

This script runs the background worker that generates automated alerts
for the Licitaciones system.

Usage:
    python run_worker.py                    # Run scheduler continuously
    python run_worker.py --once             # Run all alerts once and exit
    python run_worker.py --job <job_id>     # Run specific job once and exit

Available job IDs:
    - documento_alerts
    - licitacion_alerts
    - contrato_alerts
    - garantia_alerts
    - seguimiento_alerts
    - ampliacion_alerts
    - all_alerts
    - cleanup_alerts
"""
import sys
import signal
import argparse
import logging
from time import sleep

from app.workers.scheduler import start_scheduler, shutdown_scheduler, get_scheduler

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def signal_handler(signum, frame):
    """Handle shutdown signals gracefully."""
    logger.info(f"Received signal {signum}, shutting down...")
    shutdown_scheduler()
    sys.exit(0)


def run_continuous():
    """Run the scheduler continuously."""
    # Register signal handlers for graceful shutdown
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    logger.info("=" * 60)
    logger.info("ALERT WORKER STARTING")
    logger.info("=" * 60)

    try:
        scheduler = start_scheduler()

        logger.info("")
        logger.info("Scheduler is now running. Press Ctrl+C to stop.")
        logger.info("")

        # Keep the script running
        while True:
            sleep(60)

    except KeyboardInterrupt:
        logger.info("Keyboard interrupt received")
    finally:
        shutdown_scheduler()
        logger.info("Alert worker stopped")


def run_once(job_id: str = None):
    """
    Run alerts once and exit.

    Args:
        job_id: Optional specific job ID to run. If None, runs all alerts.
    """
    logger.info("=" * 60)
    logger.info("RUNNING ALERTS ONCE")
    logger.info("=" * 60)

    scheduler = get_scheduler()

    try:
        if job_id:
            logger.info(f"Running job: {job_id}")
            scheduler.run_now(job_id)
        else:
            logger.info("Running all alerts...")
            scheduler.run_now()

        logger.info("Done!")
    except Exception as e:
        logger.error(f"Error running alerts: {str(e)}")
        sys.exit(1)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Alert Worker for Licitaciones System",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )

    parser.add_argument(
        '--once',
        action='store_true',
        help='Run all alerts once and exit (instead of continuous)'
    )

    parser.add_argument(
        '--job',
        type=str,
        help='Run specific job once and exit (use with --once)'
    )

    parser.add_argument(
        '--list-jobs',
        action='store_true',
        help='List all available jobs and exit'
    )

    args = parser.parse_args()

    if args.list_jobs:
        logger.info("Available jobs:")
        scheduler = get_scheduler()
        for job in scheduler.scheduler.get_jobs():
            logger.info(f"  - {job.id}: {job.name}")
            logger.info(f"    Trigger: {job.trigger}")
            logger.info(f"    Next run: {job.next_run_time}")
            logger.info("")
        return

    if args.once or args.job:
        run_once(args.job)
    else:
        run_continuous()


if __name__ == "__main__":
    main()
