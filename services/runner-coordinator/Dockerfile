# =============================================================================
# AutoGit Runner Coordinator - Production Dockerfile
# =============================================================================
# Dynamic GitLab runner lifecycle manager with auto-scaling
# Part of the AutoGit CI/CD platform
#
# Image: ghcr.io/tzervas/autogit/runner-coordinator:{version}-{arch}-{variant}
# Docs:  https://github.com/tzervas/autogit/blob/main/docs/runners/AUTONOMOUS_RUNNERS.md
#
# This image is designed to be:
# - Pre-compiled with all dependencies
# - Free of any secrets or sensitive data
# - Configurable entirely via environment variables
# - Optimized for size and startup time
# =============================================================================

# =============================================================================
# Build Arguments for Dynamic Labeling
# =============================================================================
ARG BUILD_DATE
ARG VERSION=0.2.0
ARG VCS_REF
ARG ARCH=amd64
ARG VARIANT=release

# -----------------------------------------------------------------------------
# Stage 1: Builder - Install and compile dependencies
# -----------------------------------------------------------------------------
FROM python:3.14-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment for clean dependency isolation
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies (cached layer)
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Pre-compile Python files for faster startup
COPY app/ ./app/
RUN python -m compileall -b app/

# -----------------------------------------------------------------------------
# Stage 2: Runtime - Minimal production image
# -----------------------------------------------------------------------------
FROM python:3.14-slim AS runtime

# Re-declare build args for this stage
ARG BUILD_DATE
ARG VERSION=0.2.0
ARG VCS_REF
ARG ARCH=amd64
ARG VARIANT=release

# =============================================================================
# OCI Image Specification Labels
# https://github.com/opencontainers/image-spec/blob/main/annotations.md
# =============================================================================
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.authors="tzervas <tz-dev@vectorweight.com>" \
      org.opencontainers.image.url="https://github.com/tzervas/autogit" \
      org.opencontainers.image.documentation="https://github.com/tzervas/autogit/blob/main/docs/runners/AUTONOMOUS_RUNNERS.md" \
      org.opencontainers.image.source="https://github.com/tzervas/autogit" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.vendor="AutoGit" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.ref.name="${VERSION}-${ARCH}-${VARIANT}" \
      org.opencontainers.image.title="AutoGit Runner Coordinator" \
      org.opencontainers.image.description="Dynamic GitLab runner lifecycle manager with auto-scaling and intelligent resource allocation" \
      org.opencontainers.image.base.name="python:3.11-slim"

# =============================================================================
# Custom AutoGit Labels
# =============================================================================
LABEL com.autogit.component="runner-coordinator" \
      com.autogit.architecture="${ARCH}" \
      com.autogit.variant="${VARIANT}" \
      com.autogit.registry.ghcr="ghcr.io/tzervas/autogit/runner-coordinator" \
      com.autogit.registry.gitlab="192.168.1.170:5050/root/autogit/runner-coordinator"

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    docker.io \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user for security (optional, can run as root for docker socket access)
RUN useradd --create-home --shell /bin/bash autogit

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy pre-compiled application
COPY --from=builder /build/app/ ./app/

# =============================================================================
# ENVIRONMENT VARIABLE CONFIGURATION
# =============================================================================
# All configuration is done via environment variables - NO secrets in image!
#
# Required:
#   GITLAB_URL                        - GitLab server URL (e.g., http://gitlab:3000)
#   GITLAB_TOKEN                      - GitLab API token (admin access)
#   GITLAB_RUNNER_REGISTRATION_TOKEN  - Runner registration token
#
# Optional:
#   RUNNER_COOLDOWN_MINUTES   - Minutes before idle runner cleanup (default: 5)
#   MAX_IDLE_RUNNERS          - Maximum idle runners to keep (default: 0)
#   RUNNER_NETWORK            - Docker network for runners (default: autogit-network)
#   RUNNER_DOCKER_SOCKET      - Host docker socket path (default: /var/run/docker.sock)
#   RUNNER_CPU_LIMIT          - CPU cores per runner (default: 4.0)
#   RUNNER_MEMORY_LIMIT       - Memory per runner (default: 6g)
#   LOG_LEVEL                 - Logging level (default: INFO)
# =============================================================================

# Default environment values (non-sensitive only)
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    RUNNER_COOLDOWN_MINUTES=5 \
    MAX_IDLE_RUNNERS=0 \
    RUNNER_NETWORK=autogit-network \
    RUNNER_DOCKER_SOCKET=/var/run/docker.sock \
    RUNNER_CPU_LIMIT=4.0 \
    RUNNER_MEMORY_LIMIT=6g \
    LOG_LEVEL=INFO

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run as the application
CMD ["python", "-m", "app.main"]
