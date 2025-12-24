from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import List
import datetime
import asyncio
from sqlalchemy.orm import Session

from .driver import DockerDriver
from .job_manager import JobManager
from .models import Base, Job
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "sqlite:///./runner_coordinator.db"
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="AutoGit Runner Coordinator", version="0.1.0")
driver = DockerDriver()

@app.on_event("startup")
async def startup_event():
    # Start the job queue processor in the background
    db = SessionLocal()
    job_manager = JobManager(db, driver)
    asyncio.create_task(job_manager.process_queue())

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
async def get_system_status():
    # Placeholder for actual system status logic
    return {
        "active_runners": 0,
        "queued_jobs": 0,
        "system_load": 0.0
    }

@app.get("/runners", response_model=List[RunnerStatus])
async def list_runners():
    # Placeholder for actual runner listing logic
    return []

@app.post("/runners/register")
async def register_runner(request: RunnerRegistrationRequest):
    """
    Register a new GitLab runner and spawn it as a container.
    """
    import string
    import random

    # Generate unique runner name
    runner_id = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
    runner_name = f"autogit-runner-{runner_id}"

    try:
        # Spawn the runner container
        result = driver.spawn_runner(
            name=runner_name,
            image="gitlab/gitlab-runner:alpine",
            cpu_limit=4.0,
            mem_limit="4g",
            network="autogit_autogit-network",
            platform="linux/amd64"
        )

        # Register the runner with GitLab
        registration = driver.register_gitlab_runner(
            container_id=result["id"],
            gitlab_url=request.gitlab_url,
            registration_token=request.registration_token,
            description=request.description,
            tags=",".join(request.tags),
            executor=request.executor,
            docker_image=request.docker_image
        )

        return {
            "status": "registered",
            "runner_id": result["id"],
            "runner_name": runner_name,
            "container_id": result["short_id"],
            "registration_output": registration["output"]
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
        gitlab_job_id=payload.checkout_sha, # Using SHA as placeholder for job ID
        project_id=payload.project_id,
        project_name=payload.project_name,
        status="queued",
        architecture_req="amd64", # Default
        gpu_req=False # Default
    )
    db.add(new_job)
    db.commit()

    return {"message": "Job received and queued", "job_id": payload.checkout_sha}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
