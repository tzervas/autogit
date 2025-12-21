# Git Server Service

Placeholder for Git server implementation.

## Responsibilities

- Repository management (create, delete, list)
- Git protocol support (SSH, HTTP)
- Access control
- Repository metadata

## API Endpoints

To be implemented:
- `GET /health` - Health check
- `GET /repositories` - List repositories
- `POST /repositories` - Create repository
- `GET /repositories/:name` - Get repository info

## Configuration

Environment variables:
- `SERVICE_NAME` - Service identifier
- Additional config as needed
