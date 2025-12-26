import asyncio
import datetime
import logging
from typing import Any, Dict, List

from sqlalchemy.orm import Session

from .driver import DockerDriver
from .models import Job, Runner
from .platform_manager import PlatformManager

logger = logging.getLogger(__name__)


class JobManager:
    """
    Manages the job queue and runner lifecycle.
    """

    def __init__(self, db: Session, driver: DockerDriver):
        self.db = db
        self.driver = driver
        self.platform = PlatformManager()

    async def process_queue(self):
        """
        Background task to process the job queue and dispatch to runners.
        """
        while True:
            try:
                # 1. Get queued jobs
                queued_jobs = (
                    self.db.query(Job).filter(Job.status == "queued").order_by(Job.created_at).all()
                )

                for job in queued_jobs:
                    await self.dispatch_job(job)

                # 2. Cleanup finished runners
                await self.cleanup_runners()

                await asyncio.sleep(5)  # Poll every 5 seconds
            except Exception as e:
                logger.error(f"Error in process_queue: {e}")
                await asyncio.sleep(10)

    async def dispatch_job(self, job: Job):
        """
        Find or provision a runner for a job.
        """
        logger.info(f"Dispatching job {job.gitlab_job_id} for project {job.project_name}")

        # 1. Check for idle runner matching requirements
        runner = (
            self.db.query(Runner)
            .filter(
                Runner.status == "idle",
                Runner.architecture == job.architecture_req,
                Runner.gpu_enabled == job.gpu_req,
            )
            .first()
        )

        if not runner:
            # 2. Provision new runner
            runner_name = f"runner-{job.gitlab_job_id}"
            try:
                container_info = self.driver.spawn_runner(
                    name=runner_name,
                    platform=self.platform.get_docker_platform(job.architecture_req),
                    gpu_vendor="nvidia" if job.gpu_req else None,  # Simplified for now
                )

                runner = Runner(
                    id=container_info["id"],
                    name=runner_name,
                    status="provisioning",
                    architecture=job.architecture_req,
                    gpu_enabled=job.gpu_req,
                    container_id=container_info["id"],
                    ip_address=container_info["ip_address"],
                )
                self.db.add(runner)
                self.db.commit()
            except Exception as e:
                logger.error(f"Failed to provision runner for job {job.id}: {e}")
                job.status = "failed"
                self.db.commit()
                return

        # 3. Assign job to runner
        job.status = "running"
        job.runner_id = runner.id
        job.started_at = datetime.datetime.utcnow()
        runner.status = "busy"
        self.db.commit()
        logger.info(f"Job {job.gitlab_job_id} assigned to runner {runner.name}")

    async def cleanup_runners(self):
        """
        Check for finished jobs and teardown runners.
        """
        # This is a simplified cleanup logic
        # In a real scenario, we'd check if the container is still running
        busy_runners = self.db.query(Runner).filter(Runner.status == "busy").all()
        for runner in busy_runners:
            status = self.driver.get_runner_status(runner.container_id)
            if status in ["exited", "not_found"]:
                logger.info(f"Runner {runner.name} finished, tearing down.")
                self.driver.stop_runner(runner.container_id)
                runner.status = "offline"

                # Update associated job
                job = (
                    self.db.query(Job)
                    .filter(Job.runner_id == runner.id, Job.status == "running")
                    .first()
                )
                if job:
                    job.status = "completed" if status == "exited" else "failed"
                    job.finished_at = datetime.datetime.utcnow()

                self.db.commit()
