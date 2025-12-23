# GitHub Container Registry (GHCR) Setup

## Overview

AutoGit uses GitHub Container Registry (GHCR) for storing and distributing Docker images with efficient layer caching to minimize build times and bandwidth usage.

## Architecture

### Registry Structure

```
ghcr.io/tzervas/autogit/
├── git-server/          # GitLab CE server images
│   ├── :latest          # Latest stable release
│   ├── :dev             # Latest dev branch build
│   ├── :cache           # Dedicated cache layers
│   ├── :v0.1.0          # Specific version tags
│   ├── :0.1             # Major.minor tags
│   ├── :0               # Major version tags
│   └── :dev-<sha>       # Dev builds by commit SHA
└── runner-coordinator/  # Runner management service images
    ├── :latest
    ├── :dev
    ├── :cache
    └── (same tag structure as git-server)
```

### Caching Strategy

**Multi-tier Cache Sources** (checked in order):
1. **Registry cache tag** (`ghcr.io/.../service:cache`) - Dedicated cache layers
2. **Dev branch images** (`ghcr.io/.../service:dev`) - Recent development builds
3. **Latest release** (`ghcr.io/.../service:latest`) - Production images
4. **GitHub Actions cache** (GHA) - Workflow-specific cache

**Cache Destinations**:
- Registry cache (mode=max) - Full layer cache stored in GHCR
- GitHub Actions cache (mode=max) - Workflow-level cache

**Benefits**:
- ✅ Only changed layers are rebuilt and pushed
- ✅ Pulls cached layers from previous builds
- ✅ Reduces build time by 60-80% after initial build
- ✅ Reduces bandwidth usage significantly
- ✅ Faster CI/CD pipeline execution

## Workflows

### 1. PR Builds (`docker-build.yml`)

**Triggers**: Pull requests to main/dev/feature branches

**Behavior**:
- Builds images locally (no push to registry)
- Uses GHCR cache for layer reuse
- Validates build success
- Runs integration tests

**Caching**:
- Pulls from: `ghcr.io/.../service:cache`, GHA cache
- Saves to: GHA cache only (no registry push)

### 2. Dev Branch Builds (`docker-dev-build.yml`)

**Triggers**: Push to dev branch

**Behavior**:
- Builds and pushes images to GHCR
- Tags: `dev`, `dev-<sha>`, `cache`
- Updates cache layers for future builds

**Caching**:
- Pulls from: `ghcr.io/.../service:cache`, GHA cache
- Saves to: `ghcr.io/.../service:cache`, GHA cache

**Purpose**: Development testing and cache warming

### 3. Release Builds (`release.yml`)

**Triggers**: Version tags (v*.*.*) or manual dispatch

**Behavior**:
- Creates GitHub release
- Builds and pushes images with version tags
- Updates `latest` tag
- Uses multi-tier cache for efficiency

**Tags Created**:
- `v0.1.0` (exact version)
- `0.1` (major.minor)
- `0` (major)
- `latest` (current release)
- `<sha>` (commit hash)

**Caching**:
- Pulls from: `cache`, `dev`, `latest` tags, GHA cache
- Saves to: `ghcr.io/.../service:cache`, GHA cache

## Layer Caching Explained

### How It Works

Docker images are built in layers. Each Dockerfile instruction creates a layer:

```dockerfile
FROM gitlab/gitlab-ce:16.11.0-ce.0        # Layer 1 (base)
RUN apt-get update && apt-get install...  # Layer 2 (packages)
EXPOSE 22 80 443                          # Layer 3 (metadata)
```

**Without Caching**:
- Every build downloads all base layers
- All instructions re-execute
- Full rebuild takes 10-15 minutes

**With Layer Caching**:
- Base layers pulled from cache (seconds)
- Unchanged layers reused
- Only modified layers rebuilt
- Typical build time: 2-3 minutes

### Cache Efficiency

**First Build** (cold cache):
```
[====================================] 100% - 12 minutes
All layers built from scratch
```

**Second Build** (warm cache, no changes):
```
[==] 100% - 30 seconds
All layers from cache
```

**Third Build** (warm cache, code change):
```
[==========] 100% - 2 minutes
Base layers from cache, only app layer rebuilt
```

## Usage

### Pulling Images

**Latest stable release**:
```bash
docker pull ghcr.io/tzervas/autogit/git-server:latest
docker pull ghcr.io/tzervas/autogit/runner-coordinator:latest
```

**Development build**:
```bash
docker pull ghcr.io/tzervas/autogit/git-server:dev
docker pull ghcr.io/tzervas/autogit/runner-coordinator:dev
```

**Specific version**:
```bash
docker pull ghcr.io/tzervas/autogit/git-server:v0.1.0
docker pull ghcr.io/tzervas/autogit/runner-coordinator:0.1
```

### Authentication

**For public images** (no auth required):
```bash
docker pull ghcr.io/tzervas/autogit/git-server:latest
```

**For private images** (requires PAT):
```bash
# Create a Personal Access Token with read:packages scope
# https://github.com/settings/tokens

echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
docker pull ghcr.io/tzervas/autogit/git-server:dev
```

### Local Development

Images are automatically cached during builds:

```bash
# Build with cache
docker build \
  --cache-from ghcr.io/tzervas/autogit/git-server:cache \
  --cache-from ghcr.io/tzervas/autogit/git-server:dev \
  -t autogit-git-server:local \
  services/git-server/
```

Or use docker-compose which pulls from cache automatically:

```bash
docker compose build  # Uses cache if available
docker compose up -d
```

## Monitoring

### Image Size

Check pushed image sizes:
```bash
# Via GitHub Package page
https://github.com/tzervas/autogit/pkgs/container/autogit%2Fgit-server

# Via Docker
docker images ghcr.io/tzervas/autogit/git-server
```

### Cache Hit Rate

Monitor in GitHub Actions logs:
```
#8 CACHED
#9 CACHED
#10 [3/5] RUN apt-get update...
```

- `CACHED` = Layer pulled from cache (fast)
- `[3/5] RUN...` = Layer rebuilt (slower)

### Build Duration

Compare build times in Actions:
- First build: ~10-12 minutes
- Cached builds: ~2-3 minutes
- Cache hit rate: 70-90%

## Maintenance

### Cache Cleanup

**Manual cleanup** (if needed):
```bash
# Delete old cache tags (keep latest)
gh api repos/tzervas/autogit/packages/container/autogit%2Fgit-server/versions \
  | jq '.[] | select(.metadata.container.tags[] == "cache") | .id' \
  | xargs -I {} gh api -X DELETE /user/packages/container/autogit%2Fgit-server/versions/{}
```

**Automatic cleanup**:
- GHCR retains untagged layers for 30 days
- Old SHA tags automatically cleaned up
- Keep `cache`, `dev`, `latest` tags perpetually

### Cache Invalidation

**When to invalidate**:
- Major base image updates
- Dockerfile structure changes
- Build arguments modified

**How to invalidate**:
```bash
# Option 1: Delete cache tag
gh api -X DELETE /user/packages/container/autogit%2Fgit-server/versions/<VERSION_ID>

# Option 2: Update Dockerfile comment (forces rebuild)
# Add a comment or change build args
```

## Troubleshooting

### Cache Not Being Used

**Symptoms**: Every build takes 10+ minutes

**Causes**:
1. No previous builds in GHCR
2. Authentication issues
3. Cache tag deleted
4. Base image updated

**Solutions**:
```bash
# 1. Check if cache exists
docker pull ghcr.io/tzervas/autogit/git-server:cache

# 2. Verify authentication
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 3. Trigger dev build to warm cache
# Push to dev branch or manually trigger docker-dev-build.yml

# 4. Check workflow logs for cache misses
# Look for "Cache not found" messages
```

### Image Too Large

**Symptoms**: Image size > 2GB

**Causes**:
1. Unnecessary packages installed
2. Build artifacts not cleaned
3. Multiple package manager caches

**Solutions**:
```dockerfile
# Clean up in same layer
RUN apt-get update && apt-get install -y pkg \
    && rm -rf /var/lib/apt/lists/*

# Use .dockerignore
echo "node_modules" >> .dockerignore
echo "*.log" >> .dockerignore

# Multi-stage builds (if applicable)
FROM base AS builder
RUN build...
FROM base AS final
COPY --from=builder /app /app
```

### Permission Denied

**Symptoms**: Cannot push to GHCR

**Causes**:
1. `packages: write` permission missing
2. GITHUB_TOKEN expired
3. Repository visibility conflict

**Solutions**:
```yaml
# Update workflow permissions
permissions:
  contents: read
  packages: write  # Required for GHCR push

# Verify token has packages scope
# Check repo settings > Actions > General > Workflow permissions
```

## Performance Metrics

Expected performance improvements with GHCR caching:

| Metric | Without Cache | With Cache | Improvement |
|--------|---------------|------------|-------------|
| **Build Time** | 10-12 min | 2-3 min | 75-80% faster |
| **Bandwidth** | ~1.5 GB | ~100 MB | 93% reduction |
| **Layer Pulls** | All layers | Changed only | 70-90% cache hit |
| **CI Cost** | High | Low | 75% reduction |

## Best Practices

1. **Always use multi-tier caching**:
   ```yaml
   cache-from: |
     type=registry,ref=ghcr.io/.../service:cache
     type=registry,ref=ghcr.io/.../service:dev
     type=registry,ref=ghcr.io/.../service:latest
   ```

2. **Structure Dockerfile for caching**:
   ```dockerfile
   # 1. Base image (rarely changes)
   FROM gitlab/gitlab-ce:16.11.0-ce.0

   # 2. Dependencies (changes occasionally)
   RUN apt-get update && apt-get install...

   # 3. Application code (changes frequently)
   COPY . /app
   ```

3. **Use cache tags persistently**:
   - Always include `:cache` in tags
   - Push to cache on every dev build
   - Keep cache tags alive

4. **Monitor cache hit rates**:
   - Check Actions logs regularly
   - Aim for >70% cache hit rate
   - Investigate frequent cache misses

5. **Clean up old images**:
   - Remove old SHA tags (>30 days)
   - Keep semantic version tags
   - Retain cache, dev, latest tags

## References

- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Docker Layer Caching](https://docs.docker.com/build/cache/)
- [GHCR Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [BuildKit Cache Backends](https://github.com/moby/buildkit#cache)
