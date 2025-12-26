# syntax=docker/dockerfile:1.7
# ═══════════════════════════════════════════════════════════════════════════════
# autogit-core Multi-Stage Rust Builder
# ═══════════════════════════════════════════════════════════════════════════════
#
# Strategy:
# 1. Chef layer: cargo-chef for dependency caching
# 2. Deps layer: Build dependencies only (cached unless Cargo.toml changes)
# 3. Build layer: Compile source (cached unless src/ changes)
# 4. Runtime layer: Minimal distroless/static binary
#
# Parallelism: Uses all available cores via CARGO_BUILD_JOBS
# Cache: Cargo registry + git deps mounted as cache volumes
# ═══════════════════════════════════════════════════════════════════════════════

ARG RUST_VERSION=1.83
ARG DEBIAN_VERSION=bookworm

# ─────────────────────────────────────────────────────────────────────────────
# Stage 0: Chef - Generate dependency recipe
# ─────────────────────────────────────────────────────────────────────────────
FROM rust:${RUST_VERSION}-${DEBIAN_VERSION} AS chef

RUN cargo install cargo-chef --locked
WORKDIR /app

# ─────────────────────────────────────────────────────────────────────────────
# Stage 1: Planner - Analyze dependencies
# ─────────────────────────────────────────────────────────────────────────────
FROM chef AS planner

COPY Cargo.toml Cargo.lock* ./
COPY src ./src

# Generate recipe.json (dependency graph without source)
RUN cargo chef prepare --recipe-path recipe.json

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2: Builder - Compile with cached deps
# ─────────────────────────────────────────────────────────────────────────────
FROM chef AS builder

# Build args for parallelism
ARG CARGO_BUILD_JOBS=0
ARG CARGO_INCREMENTAL=1
ARG RUSTFLAGS="-C target-cpu=native"

# Environment for faster builds
ENV CARGO_BUILD_JOBS=${CARGO_BUILD_JOBS} \
    CARGO_INCREMENTAL=${CARGO_INCREMENTAL} \
    RUSTFLAGS="${RUSTFLAGS}" \
    CARGO_NET_GIT_FETCH_WITH_CLI=true

# Copy recipe and build dependencies ONLY (cached layer)
COPY --from=planner /app/recipe.json recipe.json

# Mount cache volumes for cargo registry and git deps
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=/app/target \
    cargo chef cook --release --recipe-path recipe.json

# Now copy actual source and build
COPY Cargo.toml Cargo.lock* ./
COPY src ./src

RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=/app/target \
    cargo build --release && \
    # Copy binaries out of cache mount
    mkdir -p /out && \
    cp target/release/bootstrap /out/ 2>/dev/null || true && \
    cp target/release/autogit-core /out/ 2>/dev/null || true && \
    # List what we built
    ls -la /out/

# ─────────────────────────────────────────────────────────────────────────────
# Stage 3: Runtime - Minimal image with just binaries
# ─────────────────────────────────────────────────────────────────────────────
FROM gcr.io/distroless/cc-debian12:nonroot AS runtime

LABEL org.opencontainers.image.source="https://github.com/tzervas/autogit"
LABEL org.opencontainers.image.description="Autogit GitLab automation"
LABEL org.opencontainers.image.licenses="MIT"

COPY --from=builder /out/ /usr/local/bin/

# Default to bootstrap command
ENTRYPOINT ["/usr/local/bin/bootstrap"]

# ─────────────────────────────────────────────────────────────────────────────
# Stage 4: Dev - Full toolchain for development
# ─────────────────────────────────────────────────────────────────────────────
FROM chef AS dev

# Install useful dev tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install cargo tools (watch for auto-rebuild, nextest for parallel tests)
RUN cargo install cargo-watch --locked && \
    curl -LsSf https://get.nexte.st/latest/linux | tar zxf - -C /usr/local/cargo/bin

# Development environment
ENV RUST_BACKTRACE=1 \
    RUST_LOG=debug

WORKDIR /workspace

# Mount point for source
VOLUME ["/workspace"]

# Keep container running for exec
CMD ["sleep", "infinity"]
