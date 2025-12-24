# =============================================================================
# AutoGit Runner Coordinator - Production Dockerfile
# =============================================================================
# This image is designed to be:
# - Pre-compiled with all dependencies
# - Free of any secrets or sensitive data
# - Configurable entirely via environment variables
# - Optimized for size and startup time
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Builder - Install and compile dependencies
# -----------------------------------------------------------------------------
FROM python:3.11-slim AS builder

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
FROM python:3.11-slim AS runtime

# Labels for container metadata
LABEL org.opencontainers.image.title="AutoGit Runner Coordinator"
LABEL org.opencontainers.image.description="Intelligent GitLab runner lifecycle management"
LABEL org.opencontainers.image.vendor="AutoGit"
LABEL org.opencontainers.image.source="https://github.com/tzervas/autogit"
LABEL org.opencontainers.image.licenses="MIT"

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
