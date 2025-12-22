# GitLab CE Docker Image for AutoGit
# AMD64 native support (MVP focus)
FROM gitlab/gitlab-ce:16.11.0-ce.0

# Architecture argument for future multi-arch support
ARG ARCH=amd64

# Metadata
LABEL maintainer="AutoGit Team"
LABEL description="GitLab CE server for AutoGit platform - AMD64 native"
LABEL version="1.0.0"
LABEL architecture="${ARCH}"

# Install additional utilities
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Configure GitLab ports
# SSH: 2222 (mapped from internal 22)
# HTTP: 3000 (mapped from internal 80)
# HTTPS: 3443 (mapped from internal 443)
EXPOSE 22 80 443

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=3 \
    CMD curl -f http://localhost/-/health || exit 1

# GitLab data will be stored in volumes
VOLUME ["/etc/gitlab", "/var/log/gitlab", "/var/opt/gitlab"]

# Use GitLab's default entrypoint
# Configuration via environment variables and /etc/gitlab/gitlab.rb
