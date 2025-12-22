# API Documentation

This guide covers the AutoGit APIs for programmatic access.

## Overview

AutoGit exposes several APIs:
- **Runner Manager API** - For managing runner lifecycle
- **GPU Detector API** - For querying GPU availability
- **Configuration API** - For runtime configuration
- **Fleeting Plugin API** - For custom autoscaling implementations

## API Authentication

All APIs require authentication via API tokens.

```bash
curl -H "Authorization: Bearer <token>" \
  https://api.autogit.local/v1/runners
```

See [Authentication](authentication.md) for details.

## Runner Manager API

Manage runner instances programmatically.

### Endpoints

- `GET /v1/runners` - List all runners
- `POST /v1/runners` - Provision new runner
- `GET /v1/runners/:id` - Get runner details
- `DELETE /v1/runners/:id` - Deprovision runner

See [Runner Manager API](runner-manager.md) for complete reference.

## GPU Detector API

Query available GPU resources.

### Endpoints

- `GET /v1/gpus` - List all GPUs
- `GET /v1/gpus/:id` - Get GPU details
- `GET /v1/gpus/available` - List available GPUs

See [GPU Detector API](gpu-detector.md) for complete reference.

## Configuration API

Query and update configuration at runtime.

### Endpoints

- `GET /v1/config` - Get current configuration
- `PATCH /v1/config` - Update configuration
- `GET /v1/config/schema` - Get configuration schema

See [Configuration API](configuration.md) for complete reference.

## Fleeting Plugin API

Interface for implementing custom autoscaling plugins.

### Plugin Protocol

Fleeting plugins must implement:
- `Init()` - Initialize plugin
- `Provision()` - Provision new instance
- `Deprovision()` - Remove instance
- `List()` - List all instances
- `Status()` - Get instance status

See [Fleeting Plugin API](fleeting-plugin.md) for complete reference.

## REST API

Additional REST endpoints for web UI and integrations.

See [REST API](rest.md) for complete reference.

## Client Libraries

Official client libraries:
- **Python** - `pip install autogit-client`
- **Go** - `go get github.com/yourusername/autogit-go`
- **JavaScript** - `npm install autogit-client`

See [Client Libraries](clients.md) for usage examples.

## Webhooks

AutoGit can send webhooks for events:
- Runner provisioned
- Runner deprovisioned
- Job started
- Job completed
- GPU allocated

See [Webhooks](webhooks.md) for configuration.

## API Versioning

AutoGit uses semantic versioning for APIs:
- `/v1/` - Current stable API
- `/v2/` - Next major version (when available)

See [Versioning Policy](versioning.md) for details.

## Rate Limiting

API requests are rate limited:
- 100 requests per minute (authenticated)
- 10 requests per minute (unauthenticated)

See [Rate Limiting](rate-limiting.md) for details.

## Examples

Common API usage examples:

### Provision a Runner

```bash
curl -X POST https://api.autogit.local/v1/runners \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "architecture": "amd64",
    "gpu_type": "nvidia"
  }'
```

### List Available GPUs

```bash
curl https://api.autogit.local/v1/gpus/available \
  -H "Authorization: Bearer <token>"
```

See [API Examples](examples.md) for more examples.
