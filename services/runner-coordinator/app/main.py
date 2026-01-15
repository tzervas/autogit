import asyncio
import datetime
import logging
import os
from contextlib import asynccontextmanager
from typing import List

from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from .driver import DockerDriver
from .models import Base, Job, Runner
from .runner_manager import RunnerManager

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Configuration from environment
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./runner_coordinator.db")
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create tables
Base.metadata.create_all(bind=engine)

driver = DockerDriver()

# Configuration from environment
GITLAB_URL = os.getenv("GITLAB_URL", "http://autogit-git-server:3000")
GITLAB_TOKEN = os.getenv("GITLAB_TOKEN", "")
GITLAB_RUNNER_REGISTRATION_TOKEN = os.getenv("GITLAB_RUNNER_REGISTRATION_TOKEN", "")
COOLDOWN_MINUTES = int(os.getenv("RUNNER_COOLDOWN_MINUTES", "5"))
MAX_IDLE_RUNNERS = int(os.getenv("MAX_IDLE_RUNNERS", "0"))

# Global runner manager instance
runner_manager_instance = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager - starts background tasks on startup
    """
    global runner_manager_instance

    logger.info("=" * 60)
    logger.info("Starting AutoGit Runner Coordinator")
    logger.info("=" * 60)
    logger.info(f"GitLab URL: {GITLAB_URL}")
    logger.info(f"Cooldown: {COOLDOWN_MINUTES} minutes")
    logger.info(f"Max idle runners: {MAX_IDLE_RUNNERS}")

    if not GITLAB_TOKEN:
        logger.warning("⚠ GITLAB_TOKEN not set - runner manager will have limited functionality")
    else:
        logger.info(f"✓ GITLAB_TOKEN configured ({GITLAB_TOKEN[:20]}...)")

    if not GITLAB_RUNNER_REGISTRATION_TOKEN:
        logger.warning("⚠ GITLAB_RUNNER_REGISTRATION_TOKEN not set")
    else:
        logger.info(
            f"✓ GITLAB_RUNNER_REGISTRATION_TOKEN configured "
            f"({GITLAB_RUNNER_REGISTRATION_TOKEN[:20]}...)"
        )

    # Start the lifecycle manager in the background
    db = SessionLocal()
    runner_manager_instance = RunnerManager(
        db=db,
        driver=driver,
        gitlab_url=GITLAB_URL,
        gitlab_token=GITLAB_TOKEN,
        cooldown_minutes=COOLDOWN_MINUTES,
        max_idle_runners=MAX_IDLE_RUNNERS,
        runner_registration_token=GITLAB_RUNNER_REGISTRATION_TOKEN,
    )

    # Start the lifecycle manager task
    manager_task = asyncio.create_task(runner_manager_instance.start_lifecycle_manager())
    logger.info("✓ Runner lifecycle manager started")
    logger.info("=" * 60)

    yield  # Application runs here

    # Shutdown
    logger.info("Shutting down runner manager...")
    manager_task.cancel()
    try:
        await manager_task
    except asyncio.CancelledError:
        # Expected exception when cancelling the lifecycle manager task
        # The task is cleanly cancelled and resources are cleaned up
        logger.info("Runner lifecycle manager stopped gracefully")
    db.close()


app = FastAPI(title="AutoGit Runner Coordinator", version="0.2.0", lifespan=lifespan)


# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Models
class JobWebhook(BaseModel):
    object_kind: str
    project_id: int
    ref: str
    checkout_sha: str
    user_name: str
    project_name: str


class RunnerStatus(BaseModel):
    id: str
    name: str
    status: str  # idle, busy, provisioning, offline
    architecture: str
    gpu_enabled: bool
    last_seen: datetime.datetime


class RunnerRegistrationRequest(BaseModel):
    gitlab_url: str
    registration_token: str
    description: str = "AutoGit Dynamic Runner"
    tags: List[str] = ["autogit", "docker", "amd64"]
    executor: str = "docker"
    docker_image: str = "python:3.11-slim"


# Endpoints
@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.datetime.now()}


@app.get("/status")
async def get_system_status(db: Session = Depends(get_db)):
    """
    Get system status including runner and job counts
    """
    total_runners = db.query(Runner).count()
    active_runners = db.query(Runner).filter(Runner.status.in_(["idle", "busy"])).count()
    idle_runners = db.query(Runner).filter(Runner.status == "idle").count()
    provisioning_runners = db.query(Runner).filter(Runner.status == "provisioning").count()

    return {
        "total_runners": total_runners,
        "active_runners": active_runners,
        "idle_runners": idle_runners,
        "provisioning_runners": provisioning_runners,
        "cooldown_minutes": COOLDOWN_MINUTES,
        "max_idle_runners": MAX_IDLE_RUNNERS,
        "gitlab_url": GITLAB_URL,
        "gitlab_connected": bool(GITLAB_TOKEN),
    }


@app.get("/runners", response_model=List[RunnerStatus])
async def list_runners(db: Session = Depends(get_db)):
    """
    List all active runners
    """
    runners = db.query(Runner).filter(Runner.status.in_(["idle", "busy", "provisioning"])).all()

    return [
        RunnerStatus(
            id=r.id,
            name=r.name,
            status=r.status,
            architecture=r.architecture,
            gpu_enabled=r.gpu_enabled,
            last_seen=r.last_seen,
        )
        for r in runners
    ]


@app.post("/runners/register")
async def register_runner(request: RunnerRegistrationRequest):
    """
    Register a new GitLab runner and spawn it as a container.
    """
    import random
    import string

    # Generate unique runner name
    runner_id = "".join(random.choices(string.ascii_lowercase + string.digits, k=8))
    runner_name = f"autogit-runner-{runner_id}"

    # Get configuration from environment
    runner_image = os.getenv("RUNNER_IMAGE", "gitlab/gitlab-runner:alpine")
    runner_cpu_limit = float(os.getenv("RUNNER_CPU_LIMIT", "4.0"))
    runner_mem_limit = os.getenv("RUNNER_MEMORY_LIMIT", "6g")
    runner_network = os.getenv("RUNNER_NETWORK", "autogit-network")

    try:
        # Spawn the runner container
        result = driver.spawn_runner(
            name=runner_name,
            image=runner_image,
            cpu_limit=runner_cpu_limit,
            mem_limit=runner_mem_limit,
            network=runner_network,
            platform="linux/amd64",
        )

        # Register the runner with GitLab
        registration = driver.register_gitlab_runner(
            container_id=result["id"],
            gitlab_url=request.gitlab_url,
            registration_token=request.registration_token,
            description=request.description,
            tags=",".join(request.tags),
            executor=request.executor,
            docker_image=request.docker_image,
        )

        return {
            "status": "registered",
            "runner_id": result["id"],
            "runner_name": runner_name,
            "container_id": result["short_id"],
            "registration_output": registration["output"],
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to register runner: {str(e)}")


@app.post("/webhook/job")
async def handle_job_webhook(payload: JobWebhook, db: Session = Depends(get_db)):
    """
    Handle incoming job webhooks from GitLab.
    """
    if payload.object_kind != "build":
        raise HTTPException(status_code=400, detail="Only build events are supported")

    # Create job in database
    new_job = Job(
        gitlab_job_id=payload.checkout_sha,  # Using SHA as placeholder for job ID
        project_id=payload.project_id,
        project_name=payload.project_name,
        status="queued",
        architecture_req="amd64",  # Default
        gpu_req=False,  # Default
    )
    db.add(new_job)
    db.commit()

    return {"message": "Job received and queued", "job_id": payload.checkout_sha}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8080)
