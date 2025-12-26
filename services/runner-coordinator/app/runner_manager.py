"""
GitLab Runner Manager - Autonomous lifecycle management for GitLab runners
"""

import asyncio
import logging
import os
from datetime import datetime, timedelta
from typing import Dict, List, Optional

import requests
from sqlalchemy.orm import Session

from .driver import DockerDriver
from .models import Runner

logger = logging.getLogger(__name__)


class RunnerManager:
    """
    Manages the complete lifecycle of GitLab runners:
    - Automatic registration with GitLab
    - Dynamic spawning based on demand
    - Health monitoring
    - Automatic cleanup after cooldown
    """

    def __init__(
        self,
        db: Session,
        driver: DockerDriver,
        gitlab_url: str,
        gitlab_token: str,
        cooldown_minutes: int = 5,
        max_idle_runners: int = 0,
        runner_registration_token: str = None,
    ):
        self.db = db
        self.driver = driver
        self.gitlab_url = gitlab_url
        self.gitlab_token = gitlab_token
        self.cooldown_minutes = cooldown_minutes
        self.max_idle_runners = max_idle_runners
        self.runner_image = os.getenv("RUNNER_IMAGE", "gitlab/gitlab-runner:alpine")

        # Get runner registration token from env or parameter
        self.runner_registration_token = runner_registration_token or os.getenv(
            "GITLAB_RUNNER_REGISTRATION_TOKEN"
        )

        # Enhanced resource limits - quad core, 4-6GB RAM for faster boot
        self.default_cpu_limit = float(os.getenv("RUNNER_CPU_LIMIT", "4.0"))
        self.default_mem_limit = os.getenv("RUNNER_MEMORY_LIMIT", "6g")

        logger.info(
            f"RunnerManager initialized: {self.default_cpu_limit} CPUs, {self.default_mem_limit} RAM per runner"
        )
        logger.info(f"Cooldown: {self.cooldown_minutes} minutes, Max idle: {self.max_idle_runners}")
        if self.runner_registration_token:
            logger.info("✓ Runner registration token configured")
        else:
            logger.warning("⚠ No runner registration token - cannot register runners!")

    async def start_lifecycle_manager(self):
        """
        Start the background lifecycle management tasks
        """
        logger.info("Starting runner lifecycle manager...")

        # Run tasks in parallel
        await asyncio.gather(
            self.monitor_gitlab_jobs(),
            self.cleanup_idle_runners(),
            self.health_check_runners(),
            return_exceptions=True,
        )

    async def monitor_gitlab_jobs(self):
        """
        Monitor GitLab for pending jobs and spawn runners as needed
        """
        logger.info("Starting GitLab job monitor...")

        while True:
            try:
                # Get all projects
                projects = self._get_gitlab_projects()

                for project in projects:
                    project_id = project["id"]

                    # Check for pending jobs
                    pending_jobs = self._get_pending_jobs(project_id)

                    if pending_jobs:
                        logger.info(
                            f"Found {len(pending_jobs)} pending job(s) for project {project_id}"
                        )

                        for job in pending_jobs:
                            await self.ensure_runner_for_job(job)

                await asyncio.sleep(10)  # Check every 10 seconds

            except Exception as e:
                logger.error(f"Error in job monitor: {e}", exc_info=True)
                await asyncio.sleep(30)

    async def ensure_runner_for_job(self, job: Dict):
        """
        Ensure a runner exists for the given job
        """
        job_id = job["id"]
        job_tags = job.get("tag_list", [])

        logger.info(f"Ensuring runner for job {job_id} with tags: {job_tags}")

        # Check if we have an idle runner that matches
        idle_runner = self.db.query(Runner).filter(Runner.status == "idle").first()

        if idle_runner:
            logger.info(f"Found idle runner: {idle_runner.name}")
            return

        # Check if a runner is already being provisioned
        provisioning = self.db.query(Runner).filter(Runner.status == "provisioning").count()

        if provisioning > 0:
            logger.info("Runner already being provisioned")
            return

        # Spawn new runner
        await self.spawn_runner(tags=job_tags or ["docker", "autogit"])

    async def spawn_runner(
        self, tags: List[str] = None, architecture: str = "amd64", gpu_enabled: bool = False
    ) -> Optional[Runner]:
        """
        Spawn a new GitLab runner and register it
        """
        import random
        import string

        runner_id = "".join(random.choices(string.ascii_lowercase + string.digits, k=8))
        runner_name = f"autogit-runner-{runner_id}"

        logger.info(f"Spawning runner: {runner_name}")

        try:
            # Create runner container with enhanced resources
            container_info = self.driver.spawn_runner(
                name=runner_name,
                image=self.runner_image,
                cpu_limit=self.default_cpu_limit,
                mem_limit=self.default_mem_limit,
                network="autogit-network",
                platform=f"linux/{architecture}",
                gpu_vendor="nvidia" if gpu_enabled else None,
            )

            # Create database entry
            runner = Runner(
                id=container_info["id"],
                name=runner_name,
                status="provisioning",
                architecture=architecture,
                gpu_enabled=gpu_enabled,
                container_id=container_info["id"],
                ip_address=container_info.get("ip_address"),
                created_at=datetime.utcnow(),
            )

            self.db.add(runner)
            self.db.commit()

            logger.info(f"Runner container created: {runner_name}")

            # Register with GitLab
            await self.register_runner_with_gitlab(runner, tags or ["docker", "autogit"])

            return runner

        except Exception as e:
            logger.error(f"Failed to spawn runner: {e}", exc_info=True)
            return None

    async def register_runner_with_gitlab(self, runner: Runner, tags: List[str]):
        """
        Register a runner with GitLab using the instance-wide registration token
        """
        try:
            # Get registration token from GitLab
            # For admin API, we need the instance runners registration token
            # This is typically found in Admin Area > CI/CD > Runners

            # For now, we'll use the API to get or create a runner token
            # In production, this should use the new runner authentication token workflow

            logger.info(f"Registering runner {runner.name} with GitLab")

            # Use the legacy registration token method
            # The registration token should be set as an environment variable
            registration_token = os.getenv("GITLAB_RUNNER_REGISTRATION_TOKEN")

            if not registration_token:
                # Try to get it from GitLab admin API
                registration_token = self._get_registration_token()

            if not registration_token:
                logger.error("No registration token available")
                runner.status = "error"
                self.db.commit()
                return

            # Use internal network URL for cloning (runners connect via Docker network)
            # This resolves the "localhost" issue where GitLab reports localhost URLs
            clone_url = self.gitlab_url  # Already uses internal hostname (autogit-git-server)

            # Execute registration command in container
            self.driver.register_gitlab_runner(
                container_id=runner.container_id,
                gitlab_url=self.gitlab_url,
                registration_token=registration_token,
                description=runner.name,
                tags=",".join(tags),
                executor="docker",
                docker_image="python:3.11-slim",
                clone_url=clone_url,
            )

            # Start the runner
            self._start_runner_service(runner.container_id)

            runner.status = "idle"
            runner.last_seen = datetime.utcnow()
            self.db.commit()

            logger.info(f"Runner {runner.name} registered and started successfully")

        except Exception as e:
            logger.error(f"Failed to register runner {runner.name}: {e}", exc_info=True)
            runner.status = "error"
            self.db.commit()

    def _start_runner_service(self, container_id: str):
        """
        Start the GitLab runner service inside the container
        """
        try:
            container = self.driver.client.containers.get(container_id)

            # Start gitlab-runner in the background
            container.exec_run(cmd=["gitlab-runner", "run"], detach=True)

            logger.info(f"Started runner service in container {container_id}")

        except Exception as e:
            logger.error(f"Failed to start runner service: {e}")
            raise

    async def cleanup_idle_runners(self):
        """
        Cleanup runners that have been idle past the cooldown period
        """
        logger.info("Starting idle runner cleanup task...")

        while True:
            try:
                # Calculate cooldown threshold
                cooldown_threshold = datetime.utcnow() - timedelta(minutes=self.cooldown_minutes)

                # Find idle runners past cooldown
                idle_runners = (
                    self.db.query(Runner)
                    .filter(Runner.status == "idle", Runner.last_seen < cooldown_threshold)
                    .all()
                )

                for runner in idle_runners:
                    # Keep minimum number of idle runners if configured
                    current_idle = self.db.query(Runner).filter(Runner.status == "idle").count()

                    if current_idle <= self.max_idle_runners:
                        logger.info(f"Keeping {current_idle} idle runner(s) as warm pool")
                        break

                    logger.info(
                        f"Cleaning up idle runner: {runner.name} (idle since {runner.last_seen})"
                    )

                    try:
                        # Unregister from GitLab first
                        self._unregister_runner_from_gitlab(runner)

                        # Stop and remove container
                        self.driver.stop_runner(runner.container_id, remove=True)

                        # Remove from database
                        self.db.delete(runner)
                        self.db.commit()

                        logger.info(f"Runner {runner.name} cleaned up successfully")

                    except Exception as e:
                        logger.error(f"Failed to cleanup runner {runner.name}: {e}")

                await asyncio.sleep(60)  # Check every minute

            except Exception as e:
                logger.error(f"Error in cleanup task: {e}", exc_info=True)
                await asyncio.sleep(60)

    async def health_check_runners(self):
        """
        Monitor runner health and update status
        """
        logger.info("Starting runner health check task...")

        while True:
            try:
                active_runners = (
                    self.db.query(Runner)
                    .filter(Runner.status.in_(["idle", "busy", "provisioning"]))
                    .all()
                )

                for runner in active_runners:
                    try:
                        # Check container status
                        container_status = self.driver.get_runner_status(runner.container_id)

                        if container_status in ["exited", "not_found", "dead"]:
                            logger.warning(f"Runner {runner.name} is {container_status}")
                            runner.status = "offline"
                            self.db.commit()
                        else:
                            runner.last_seen = datetime.utcnow()
                            self.db.commit()

                    except Exception as e:
                        logger.error(f"Health check failed for {runner.name}: {e}")

                await asyncio.sleep(30)  # Check every 30 seconds

            except Exception as e:
                logger.error(f"Error in health check task: {e}", exc_info=True)
                await asyncio.sleep(30)

    def _get_gitlab_projects(self) -> List[Dict]:
        """
        Get all projects from GitLab
        """
        try:
            response = requests.get(
                f"{self.gitlab_url}/api/v4/projects",
                headers={"PRIVATE-TOKEN": self.gitlab_token},
                timeout=10,
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to get projects: {e}")
            return []

    def _get_pending_jobs(self, project_id: int) -> List[Dict]:
        """
        Get pending jobs for a project
        """
        try:
            response = requests.get(
                f"{self.gitlab_url}/api/v4/projects/{project_id}/jobs",
                headers={"PRIVATE-TOKEN": self.gitlab_token},
                params={"scope[]": "pending"},
                timeout=10,
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.debug(f"Failed to get pending jobs for project {project_id}: {e}")
            return []

    def _get_registration_token(self) -> Optional[str]:
        """
        Get the runner registration token
        """
        # Use the configured token if available
        if self.runner_registration_token:
            return self.runner_registration_token

        # Otherwise try to get from environment
        return os.getenv("GITLAB_RUNNER_REGISTRATION_TOKEN")

    def _unregister_runner_from_gitlab(self, runner: Runner):
        """
        Unregister a runner from GitLab
        """
        try:
            # Get runner token from container if possible
            # For now, we'll just let GitLab mark it as offline
            logger.info(f"Runner {runner.name} will be marked as offline in GitLab")

        except Exception as e:
            logger.error(f"Failed to unregister runner: {e}")
