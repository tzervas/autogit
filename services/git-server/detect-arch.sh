#!/bin/bash
# Architecture Detection Script for AutoGit Git Server
# Detects host architecture and selects appropriate Dockerfile

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect architecture
detect_architecture() {
    local arch
    arch=$(uname -m)

    case "$arch" in
        x86_64 | amd64)
            echo "amd64"
            ;;
        aarch64 | arm64)
            echo "arm64"
            ;;
        riscv64)
            echo "riscv"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Get Dockerfile path for architecture
get_dockerfile() {
    local arch=$1

    case "$arch" in
        amd64)
            echo "services/git-server/Dockerfile.amd64"
            ;;
        arm64)
            echo "services/git-server/Dockerfile.arm64"
            ;;
        riscv)
            echo "services/git-server/Dockerfile.riscv"
            ;;
        *)
            echo "services/git-server/Dockerfile"
            ;;
    esac
}

# Get architecture display name
get_arch_display_name() {
    local arch=$1

    case "$arch" in
        amd64)
            echo "AMD64 (x86_64) - Native"
            ;;
        arm64)
            echo "ARM64 (aarch64) - Native"
            ;;
        riscv)
            echo "RISC-V (riscv64) - QEMU Emulation (Experimental)"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# Get architecture support status
get_arch_support() {
    local arch=$1

    case "$arch" in
        amd64)
            echo "Production Ready (MVP)"
            ;;
        arm64)
            echo "Supported (Phase 2)"
            ;;
        riscv)
            echo "Experimental (Phase 3)"
            ;;
        *)
            echo "Unsupported"
            ;;
    esac
}

# Main execution
main() {
    print_info "AutoGit Git Server - Architecture Detection"
    echo ""

    # Detect architecture
    DETECTED_ARCH=$(detect_architecture)

    if [ "$DETECTED_ARCH" == "unknown" ]; then
        print_error "Unsupported architecture: $(uname -m)"
        print_error "AutoGit supports: AMD64, ARM64, RISC-V"
        exit 1
    fi

    # Display detection results
    print_success "Detected Architecture: $(get_arch_display_name "$DETECTED_ARCH")"
    print_info "Support Status: $(get_arch_support "$DETECTED_ARCH")"

    # Get Dockerfile path
    DOCKERFILE=$(get_dockerfile "$DETECTED_ARCH")

    # Check if Dockerfile exists
    if [ ! -f "$DOCKERFILE" ]; then
        print_error "Dockerfile not found: $DOCKERFILE"
        print_error "Please ensure all architecture-specific Dockerfiles are present"
        exit 1
    fi

    print_success "Using Dockerfile: $DOCKERFILE"
    echo ""

    # Display recommendations based on architecture
    case "$DETECTED_ARCH" in
        amd64)
            print_info "Recommendations for AMD64:"
            echo "  - Native performance, no emulation needed"
            echo "  - Full GitLab CE feature support"
            echo "  - Production ready"
            echo "  - Recommended resources: 4 cores, 8GB RAM, 60GB+ storage"
            ;;
        arm64)
            print_info "Recommendations for ARM64:"
            echo "  - Native performance on ARM64 hosts"
            echo "  - Full GitLab CE feature support"
            echo "  - May require more time for first startup"
            echo "  - Recommended resources: 4 cores, 8GB RAM, 60GB+ storage"
            print_warn "Note: Ensure ARM64 GitLab CE image is available"
            ;;
        riscv)
            print_warn "RISC-V Support is Experimental:"
            echo "  - Runs via QEMU emulation"
            echo "  - Significantly slower than native"
            echo "  - Limited GitLab CE support"
            echo "  - For testing and future compatibility only"
            print_error "NOT RECOMMENDED for production use"
            ;;
    esac

    echo ""

    # Export architecture for use in scripts/docker-compose
    echo "DETECTED_ARCH=$DETECTED_ARCH"
    echo "DOCKERFILE_PATH=$DOCKERFILE"

    # Optionally create a .arch file for other scripts to read
    if [ "${CREATE_ARCH_FILE:-false}" == "true" ]; then
        echo "$DETECTED_ARCH" > .detected_arch
        print_success "Architecture saved to .detected_arch"
    fi

    # Return success
    exit 0
}

# Run main function
main "$@"
