# Runner Coordinator Service

Placeholder for runner coordinator implementation.

## Responsibilities

- Manage runner lifecycle
- Schedule jobs to runners
- Monitor runner health
- Handle GPU/compute allocation
- Coordinate with Git server

## API Endpoints

To be implemented:

- `GET /health` - Health check
- `GET /runners` - List active runners
- `POST /runners` - Spawn new runner
- `DELETE /runners/:id` - Terminate runner
- `GET /jobs` - List jobs
- `POST /jobs` - Submit new job

## Configuration

Environment variables:

- `SERVICE_NAME` - Service identifier
- Additional config as needed

# Runner Coordinator Documentation

## Overview

The Runner Coordinator is a FastAPI-based service responsible for managing the lifecycle of
ephemeral Docker runners. It handles job queuing, architecture-aware scheduling, and GPU allocation.

## Architecture

The service consists of several key components:

- **FastAPI App**: Provides the REST API and webhook endpoints.
- **JobManager**: A background task that processes the job queue and dispatches runners.
- **DockerDriver**: Manages the creation, monitoring, and cleanup of Docker containers.
- **PlatformManager**: Detects host architecture and available GPU hardware.
- **SecurityManager**: Handles token generation and environment sanitization.

## Setup

1. Install dependencies using `uv`:
   ```bash
   uv sync
   ```
1. Run the service:
   ```bash
   export PYTHONPATH=$PYTHONPATH:$(pwd)/services/runner-coordinator
   uv run python3 services/runner-coordinator/app/main.py
   ```

## API Endpoints

- `GET /health`: Health check.
- `GET /status`: Get current status of runners and jobs.
- `POST /webhook/job`: Webhook for receiving new jobs from GitLab.

## Security

- Runners are spawned with dropped capabilities (`CAP_DROP=["ALL"]`).
- `no-new-privileges` is enabled for all runner containers.
- Environment variables are sanitized before being passed to runners.
- Secure tokens are generated for runner-to-coordinator communication.

## Multi-arch & GPU Support

- Automatically detects `amd64`, `arm64`, and `riscv64`.
- Supports NVIDIA (via `DeviceRequest`), AMD, and Intel GPUs (via device mapping).
- Jobs can request specific architectures and GPU counts.
