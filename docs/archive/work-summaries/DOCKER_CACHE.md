# Docker Image Build & Cache Strategy

## Quick Reference

### Build Images Locally

```bash
# With caching from GHCR
docker build --cache-from ghcr.io/tzervas/autogit/git-server:cache \
             -t autogit-git-server:local \
             services/git-server/

# Or use docker-compose
docker compose build
```

### Pull Images

```bash
# Latest release
docker pull ghcr.io/tzervas/autogit/git-server:latest

# Development version
docker pull ghcr.io/tzervas/autogit/git-server:dev

# Specific version
docker pull ghcr.io/tzervas/autogit/git-server:v0.1.0
```

## Automated Builds

### PR Builds (Test Only)

- **Workflow**: `.github/workflows/docker-build.yml`
- **Trigger**: Pull requests
- **Action**: Build locally, no push
- **Cache**: Uses GHCR + GHA cache for speed

### Dev Builds (Push to Registry)

- **Workflow**: `.github/workflows/docker-dev-build.yml`
- **Trigger**: Push to `dev` branch
- **Tags**: `dev`, `dev-<sha>`, `cache`
- **Cache**: Full layer cache pushed to GHCR

### Release Builds (Production)

- **Workflow**: `.github/workflows/release.yml`
- **Trigger**: Version tags (v\*.*.*)
- **Tags**: `v0.1.0`, `0.1`, `0`, `latest`, `<sha>`
- **Cache**: Multi-tier (cache, dev, latest)

## Cache Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GHCR Cache Strategy                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  PR Build (Test)                                            │
│  └─ Pulls from: cache tag, GHA cache                       │
│     └─ Saves to: GHA cache only                            │
│                                                              │
│  Dev Build (dev branch)                                     │
│  └─ Pulls from: cache tag, GHA cache                       │
│     └─ Saves to: cache tag, GHA cache                      │
│     └─ Tags: dev, dev-<sha>, cache                         │
│                                                              │
│  Release Build (tag)                                        │
│  └─ Pulls from: cache, dev, latest, GHA cache              │
│     └─ Saves to: cache tag, GHA cache                      │
│     └─ Tags: v0.1.0, 0.1, 0, latest, <sha>                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Layer Caching Benefits

**Without Cache**:

- Build time: ~12 minutes
- Network: ~1.5 GB download
- All layers rebuilt from scratch

**With Cache** (warm):

- Build time: ~2-3 minutes (75% faster)
- Network: ~100 MB (93% less)
- Only changed layers rebuilt

## Image Tags

### Semantic Versions (Releases)

- `v0.1.0` - Exact version
- `0.1` - Major.minor (tracks patches)
- `0` - Major (tracks minor updates)
- `latest` - Current stable release

### Development Tags

- `dev` - Latest dev branch build
- `dev-<sha>` - Specific dev commit

### Cache Tags

- `cache` - Dedicated cache layers (persistent)

### Commit Tags

- `<sha>` - Full commit SHA (all builds)

## Local Development

### Quick Start

```bash
# Build with cache
docker compose build

# Run services
docker compose up -d

# View logs
docker compose logs -f git-server
```

### Force Rebuild

```bash
# Without cache
docker compose build --no-cache

# Or remove cached layers
docker builder prune -af
```

### Cache Management

```bash
# View local cache
docker buildx du

# Clean build cache
docker buildx prune -af

# Remove old images
docker image prune -af
```

## CI/CD Integration

### Workflow Permissions

All image build workflows require:

```yaml
permissions:
  contents: read
  packages: write  # For GHCR push
```

### Authentication

GitHub Actions automatically authenticates with:

```yaml
- uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

### Cache Configuration

**Pull cache** (build faster):

```yaml
cache-from: |
  type=registry,ref=ghcr.io/repo/service:cache
  type=gha
```

**Push cache** (help future builds):

```yaml
cache-to: |
  type=registry,ref=ghcr.io/repo/service:cache,mode=max
  type=gha,mode=max
```

## Troubleshooting

### Build is Slow

```bash
# Check if cache exists
docker pull ghcr.io/tzervas/autogit/git-server:cache

# If not, trigger dev build to warm cache
git push origin dev
```

### Cannot Push to GHCR

```bash
# Verify permissions in workflow
permissions:
  packages: write

# Check repo settings
# Settings > Actions > Workflow permissions > Read and write
```

### Cache Not Working

```bash
# Verify cache tags exist
docker pull ghcr.io/tzervas/autogit/git-server:cache

# Check workflow logs for:
# "CACHED" = layer from cache
# "RUN..." = layer rebuilt
```

## Documentation

- [GHCR Setup Guide](../../docs/development/ghcr-setup.md) - Complete GHCR documentation
- [Docker Compose Setup](../../docs/installation/docker-compose.md) - Installation guide
- [Development Guide](../../docs/development/README.md) - Development workflow

## Performance

Expected metrics with GHCR caching:

| Stage                | Time      | Bandwidth |
| -------------------- | --------- | --------- |
| First build (cold)   | 10-12 min | 1.5 GB    |
| PR build (warm)      | 2-3 min   | 100 MB    |
| Dev build (warm)     | 2-3 min   | 100 MB    |
| Release build (warm) | 2-4 min   | 150 MB    |

Cache hit rate: **70-90%**

## Support

For issues or questions:

1. Check [GHCR Setup Guide](../../docs/development/ghcr-setup.md)
1. Review workflow logs in GitHub Actions
1. Open an issue with build logs
