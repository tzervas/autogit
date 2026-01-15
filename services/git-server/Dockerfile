# =============================================================================
# AutoGit Git Server - GitLab CE
# =============================================================================
# Self-hosted GitLab CE with integrated container registry
# Part of the AutoGit CI/CD platform
#
# Image: ghcr.io/tzervas/autogit/git-server:{version}-{arch}-{variant}
# Docs:  https://github.com/tzervas/autogit/blob/main/docs/git-server/README.md
# =============================================================================
FROM gitlab/gitlab-ce:18.7.1-ce.0

# =============================================================================
# Build Arguments for Dynamic Labeling
# =============================================================================
ARG BUILD_DATE
ARG VERSION=0.2.0
ARG VCS_REF
ARG ARCH=amd64
ARG VARIANT=release
ARG MAINTAINER_EMAIL=tzervas@example.com

# =============================================================================
# OCI Image Specification Labels
# https://github.com/opencontainers/image-spec/blob/main/annotations.md
# =============================================================================
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.authors="tzervas <${MAINTAINER_EMAIL}>" \
      org.opencontainers.image.url="https://github.com/tzervas/autogit" \
      org.opencontainers.image.documentation="https://github.com/tzervas/autogit/blob/main/docs/git-server/README.md" \
      org.opencontainers.image.source="https://github.com/tzervas/autogit" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.vendor="AutoGit" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.ref.name="${VERSION}-${ARCH}-${VARIANT}" \
      org.opencontainers.image.title="AutoGit Git Server" \
      org.opencontainers.image.description="GitLab CE server with integrated container registry for the AutoGit self-hosted CI/CD platform" \
      org.opencontainers.image.base.name="gitlab/gitlab-ce:18.7.0-ce.0"

# =============================================================================
# Custom AutoGit Labels
# =============================================================================
LABEL com.autogit.component="git-server" \
      com.autogit.architecture="${ARCH}" \
      com.autogit.variant="${VARIANT}" \
      com.autogit.registry.ghcr="ghcr.io/tzervas/autogit/git-server" \
      com.autogit.registry.gitlab="192.168.1.170:5050/root/autogit/git-server"

# Install additional utilities
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Internal container ports exposed by this image:
#   SSH:   22
#   HTTP:  80
#   HTTPS: 443
# Host port mappings (e.g., 2222->22, 3000->80, 3443->443) are defined in docker-compose.yml.
EXPOSE 22 80 443

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=3 \
    CMD curl -f http://localhost/-/health || exit 1

# GitLab data will be stored in volumes
VOLUME ["/etc/gitlab", "/var/log/gitlab", "/var/opt/gitlab"]

# Use GitLab's default entrypoint
# Configuration via environment variables and /etc/gitlab/gitlab.rb
