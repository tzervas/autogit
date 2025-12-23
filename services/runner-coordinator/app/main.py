from fastapi import FastAPI, BackgroundTasks, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import datetime

app = FastAPI(title="AutoGit Runner Coordinator", version="0.1.0")

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

@app.post("/webhook/job")
async def handle_job_webhook(payload: JobWebhook, background_tasks: BackgroundTasks):
    """
    Handle incoming job webhooks from GitLab.
    This will eventually trigger the runner provisioning logic.
    """
    if payload.object_kind != "build":
        raise HTTPException(status_code=400, detail="Only build events are supported")

    # TODO: Add to job queue and trigger provisioning
    return {"message": "Job received and queued", "job_id": payload.checkout_sha}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
