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
