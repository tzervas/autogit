# Architecture Documentation

## System Overview

Autogit is designed as a containerized platform for self-hosted version control with automated runner management.

## Components

### Git Server
- Handles repository operations
- Provides SSH and HTTP interfaces
- Manages repository lifecycle

### Runner Coordinator
- Orchestrates compute/GPU runners
- Manages runner lifecycle (spawn, monitor, cleanup)
- Interfaces with Docker daemon for container management

## Communication

Services communicate via:
- Docker network (`autogit-network`)
- REST APIs between services
- Shared volumes for data persistence

## Deployment

Uses Docker Compose for app-level coordination:
- Service dependencies managed automatically
- Network isolation
- Volume persistence
- Easy scaling and management

## Future Enhancements

- Add database for state management
- Implement job queue (Redis)
- Add monitoring and observability
- Implement authentication/authorization
- Add webhook support for CI/CD integration
