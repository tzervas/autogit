# autogit

Automated self-hosted version control with fully lifecycle-managed automated runners for GPU and compute.

## Overview

Autogit is a containerized solution providing:
- Self-hosted Git server with SSH and HTTP access
- Runner coordinator for managing GPU and compute workloads
- Automated lifecycle management for runners
- App-level coordination via Docker Compose

## Architecture

```
┌─────────────────────────────────────────────┐
│         Docker Compose Orchestration         │
├──────────────────┬──────────────────────────┤
│   Git Server     │   Runner Coordinator     │
│   Port: 3000     │   Port: 8080             │
│   SSH: 2222      │   Manages: Runners       │
└──────────────────┴──────────────────────────┘
```

## Quick Start

1. **Setup environment**
   ```bash
   ./scripts/setup.sh
   ```

2. **Configure** (optional)
   Edit `.env` file with your settings

3. **Start services**
   ```bash
   docker-compose up -d
   ```

4. **Check status**
   ```bash
   docker-compose ps
   docker-compose logs -f
   ```

## Project Structure

```
autogit/
├── docker-compose.yml          # Service orchestration
├── .env.example                # Environment template
├── services/                   # Service implementations
│   ├── git-server/            # Git server service
│   └── runner-coordinator/    # Runner management service
├── config/                     # Configuration files
├── scripts/                    # Utility scripts
│   └── setup.sh               # Initial setup
└── docs/                       # Documentation
```

## Services

### Git Server
- **Purpose**: Version control system
- **Ports**: 3000 (HTTP), 2222 (SSH)
- **Features**: Repository management, SSH access

### Runner Coordinator
- **Purpose**: Manage automated runners
- **Port**: 8080
- **Features**: Runner lifecycle, GPU/compute coordination

## Development

Ready for implementation! This repository provides the containerized foundation with app-level coordination. Implement service logic in:
- `services/git-server/` - Git server implementation
- `services/runner-coordinator/` - Runner coordination logic

## License

MIT
