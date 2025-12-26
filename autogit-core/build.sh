#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# autogit-core Build Script
# ═══════════════════════════════════════════════════════════════════════════════
#
# Quick commands for common operations. Run from autogit-core/ directory.
#
# Usage:
#   ./build.sh dev      # Start dev container
#   ./build.sh shell    # Shell into dev container
#   ./build.sh build    # Release build
#   ./build.sh test     # Run tests
#   ./build.sh watch    # Auto-rebuild on changes
#   ./build.sh clean    # Remove build artifacts
#   ./build.sh purge    # Remove all caches (full rebuild)
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load env if exists
[[ -f .env ]] && source .env

log() { echo "[$(date '+%H:%M:%S')] $*"; }

case "${1:-help}" in
dev)
    log "Starting dev container..."
    docker compose up -d rust-dev
    log "Dev container ready. Run: ./build.sh shell"
    ;;

shell)
    log "Opening shell in dev container..."
    docker compose exec rust-dev bash
    ;;

build)
    log "Building release binary..."
    docker compose run --rm build
    log "Binary at: target/release/bootstrap"
    ;;

test)
    log "Running tests..."
    docker compose run --rm test
    ;;

watch)
    log "Starting watch mode (Ctrl+C to stop)..."
    docker compose run --rm watch
    ;;

check)
    log "Running cargo check..."
    docker compose exec rust-dev cargo check
    ;;

clean)
    log "Cleaning build artifacts..."
    docker compose exec rust-dev cargo clean
    ;;

purge)
    log "Purging all caches (will trigger full rebuild)..."
    docker compose down -v
    docker volume rm autogit-cargo-registry autogit-cargo-git autogit-cargo-target 2>/dev/null || true
    log "Caches purged."
    ;;

status)
    docker compose ps
    echo ""
    log "Cache volumes:"
    docker volume ls | grep autogit-cargo || echo "  (none)"
    ;;

stop)
    log "Stopping containers..."
    docker compose down
    ;;

logs)
    docker compose logs -f "${2:-rust-dev}"
    ;;

*)
    cat <<'EOF'
autogit-core Build Script

Commands:
  dev       Start development container (persistent)
  shell     Open bash in dev container
  build     One-shot release build
  test      Run test suite
  watch     Auto-rebuild on file changes
  check     Quick syntax/type check
  clean     Remove build artifacts (keep deps)
  purge     Remove all caches (full rebuild)
  status    Show container and cache status
  stop      Stop all containers
  logs      Follow container logs

Examples:
  ./build.sh dev && ./build.sh shell
  ./build.sh build
  RUST_BUILD_CPUS=8 ./build.sh build
EOF
    ;;
esac
