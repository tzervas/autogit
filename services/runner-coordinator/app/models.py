import datetime

from sqlalchemy import Boolean, Column, DateTime, Float, Integer, String
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()


class Runner(Base):
    __tablename__ = "runners"

    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    status = Column(String, default="offline")  # idle, busy, provisioning, offline
    architecture = Column(String, nullable=False)  # amd64, arm64, riscv
    gpu_enabled = Column(Boolean, default=False)
    gpu_vendor = Column(String, nullable=True)  # nvidia, amd, intel
    container_id = Column(String, nullable=True)
    ip_address = Column(String, nullable=True)
    last_seen = Column(DateTime, default=datetime.datetime.utcnow)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)


class Job(Base):
    __tablename__ = "jobs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    gitlab_job_id = Column(Integer, unique=True, nullable=False)
    project_id = Column(Integer, nullable=False)
    project_name = Column(String, nullable=False)
    status = Column(String, default="queued")  # queued, running, completed, failed
    runner_id = Column(String, nullable=True)
    architecture_req = Column(String, default="amd64")
    gpu_req = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    started_at = Column(DateTime, nullable=True)
    finished_at = Column(DateTime, nullable=True)
