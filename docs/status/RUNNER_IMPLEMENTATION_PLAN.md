# Milestone 3: Runner Coordinator - Implementation Plan

**Status**: Planning Complete
**Date**: 2025-12-23
**Owner**: Project Manager Agent

## Refined Architecture Decision
The Runner Coordinator will be a standalone Python service (`runner-coordinator`) using FastAPI. It will manage runners via the Docker Socket and support multi-architecture and GPU workloads through a pluggable "Driver" architecture.

## Implementation Subtasks

### 1. Base Service & API Framework
**Priority**: High
**Assigned To**: Software Engineer
**Deliverables**:
- FastAPI project structure in `services/runner-coordinator/`
- Basic API endpoints (health, status, job-webhook)
- SQLite database schema for runner/job tracking

### 2. Docker Driver Implementation
**Priority**: High
**Assigned To**: DevOps Engineer
**Deliverables**:
- Python module for interacting with Docker API
- Logic for spawning, stopping, and cleaning up runner containers
- Support for resource limits and network isolation

### 3. Multi-Architecture & GPU Support
**Priority**: Medium
**Assigned To**: DevOps Engineer + SE Specialist
**Deliverables**:
- Architecture detection and platform-specific container spawning
- GPU device mapping logic (NVIDIA/AMD/Intel)
- Integration with the Docker Driver

### 4. Job Queue & Lifecycle Management
**Priority**: High
**Assigned To**: Software Engineer
**Deliverables**:
- Job queue logic (receive from webhook -> queue -> dispatch)
- Runner state machine implementation
- Cleanup worker for orphaned containers

### 5. Security Hardening
**Priority**: Medium
**Assigned To**: Security Engineer
**Deliverables**:
- User namespace configuration
- Network policy implementation
- Secure secret handling logic

### 6. Integration & Testing
**Priority**: High
**Assigned To**: Evaluator + Documentation Engineer
**Deliverables**:
- Integration tests with Git Server
- End-to-end job execution tests
- User and Admin documentation for Runners
