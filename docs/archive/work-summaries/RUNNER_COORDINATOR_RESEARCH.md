# Milestone 3: Runner Coordinator - Research and Design Phase

**Status**: Research Phase **Date**: 2025-12-23 **Owner**: Project Manager Agent

## Overview

This document outlines the research and design phase for the Runner Coordinator, decomposed into
specialized subtasks for agentic feedback.

## Research Subtasks

### 1. Architecture & Lifecycle Design (Software Engineer)

**Objective**: Define the internal architecture of the Runner Coordinator and the lifecycle of a
runner. **Key Questions**:

- Should the coordinator be a standalone service or integrated into the Git Server?
- How will it track runner state (idle, busy, offline)?
- What is the state machine for a runner's lifecycle?
- How will it handle job queuing and dispatching?

### 2. Infrastructure & Docker Integration (DevOps Engineer)

**Objective**: Research the mechanism for spawning and managing runner containers. **Key
Questions**:

- Docker-in-Docker (DinD) vs. Docker Socket mounting?
- How to handle multi-architecture container spawning (AMD64, ARM64, RISC-V)?
- Resource isolation and limiting (CPU, Memory) for runners.
- Networking between the coordinator and spawned runners.

### 3. GPU Detection & Allocation (DevOps/SE Specialist)

**Objective**: Research vendor-specific GPU integration. **Key Questions**:

- How to detect NVIDIA, AMD, and Intel GPUs from within a container?
- How to pass GPU devices to spawned runner containers?
- How to monitor GPU utilization per runner?

### 4. Security & Isolation (Security Engineer)

**Objective**: Define the security boundaries for runners. **Key Questions**:

- How to prevent runners from accessing the host system or other runners?
- Secure handling of secrets and environment variables.
- User namespace remapping for runner containers.
- Network policy enforcement.

### 5. API & Integration (Software Engineer)

**Objective**: Define the interface between the Git Server and the Runner Coordinator. **Key
Questions**:

- REST vs. Webhooks for job notification?
- Authentication mechanism between services.
- API endpoints for status monitoring and manual intervention.

## Feedback Loop

1. Specialists provide feedback on their respective subtasks.
1. Project Manager reviews and synthesizes feedback.
1. Refined design is documented in an ADR (Architecture Decision Record).
1. Implementation subtasks are allocated.
