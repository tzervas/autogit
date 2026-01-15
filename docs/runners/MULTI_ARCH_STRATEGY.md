# Multi-Architecture Support Strategy

## Overview

AutoGit supports multiple CPU architectures to enable deployment on diverse hardware platforms. This
document outlines the strategy for AMD64, ARM64, and RISC-V support.

## Supported Architectures

### 1. AMD64 (x86_64) - Primary Platform

**Status**: ✅ Full Support (MVP Focus) **Implementation**: Native **Testing**: Active

- Primary development and testing platform
- Most widely deployed architecture
- Best performance characteristics
- Full feature set available
- Primary CI/CD testing target

### 2. ARM64 (aarch64) - Hybrid Support

**Status**: 🔄 Planned (Post-MVP) **Implementation**: Native + QEMU Emulation **Testing**:
Post-Deployment

#### Native ARM64

- For users with ARM64 hosts/runners
- Full native performance
- Ideal for ARM-based servers (AWS Graviton, Ampere, Apple Silicon, Raspberry Pi 4/5)
- Native Docker builds
- Optimal resource utilization

#### ARM64 via QEMU Emulation

- Fallback for AMD64 hosts without ARM64 hardware
- Allows cross-platform development
- Slower than native but fully functional
- Useful for testing and development
- Resource overhead acceptable for testing

### 3. RISC-V - Emulation Only

**Status**: 🔮 Future (Experimental) **Implementation**: QEMU Emulation **Testing**: Future

- Emerging architecture support
- QEMU emulation on AMD64 or ARM64 hosts
- Experimental/testing purposes
- Prepares for future native RISC-V runners
- Performance not critical at this stage

## Implementation Phases

### Phase 1: MVP - AMD64 Native Only (Current)

**Timeline**: Now - Initial Deployment **Focus**: Stable AMD64 foundation

#### Deliverables

- ✅ AMD64 native Docker images
- ✅ AMD64 testing infrastructure
- ✅ AMD64 deployment documentation
- ✅ Performance benchmarks (AMD64)

#### Testing

- All testing on AMD64 native
- CI/CD on AMD64 runners
- Production deployment on AMD64 hosts

#### Rationale

- Establish stable baseline
- Ensure core functionality works
- Get to deployment faster
- Validate architecture before expanding

### Phase 2: ARM64 Support (Post-Deployment)

**Timeline**: After AMD64 deployment validated **Focus**: Native ARM64 + QEMU fallback

#### Deliverables

- [ ] ARM64 native Docker images
- [ ] ARM64 native testing (when infrastructure available)
- [ ] QEMU ARM64 emulation setup
- [ ] Architecture detection and auto-selection
- [ ] ARM64 deployment documentation
- [ ] Performance comparison (native vs QEMU)

#### Testing

- ARM64 native on ARM64 runners (when available)
- QEMU ARM64 on AMD64 hosts
- Cross-architecture compatibility
- Performance benchmarking

#### Prerequisites

- AMD64 deployment stable and running
- ARM64 infrastructure available (runners/hosts)
- Multi-arch build pipeline configured

### Phase 3: RISC-V Emulation (Future)

**Timeline**: After ARM64 validated **Focus**: Experimental RISC-V support

#### Deliverables

- [ ] RISC-V QEMU emulation setup
- [ ] RISC-V Docker images (emulated)
- [ ] Basic functional testing
- [ ] Documentation for RISC-V testing

#### Testing

- QEMU RISC-V emulation
- Functional validation only
- Performance monitoring (not critical)

#### Prerequisites

- ARM64 support stable
- QEMU infrastructure mature
- Community interest/demand

## Architecture Detection and Selection

### Automatic Detection

```bash
# Detect host architecture
ARCH=$(uname -m)

case $ARCH in
    x86_64)
        DOCKER_PLATFORM="linux/amd64"
        NATIVE=true
        ;;
    aarch64|arm64)
        DOCKER_PLATFORM="linux/arm64"
        NATIVE=true
        ;;
    riscv64)
        DOCKER_PLATFORM="linux/riscv64"
        NATIVE=false  # Always emulated for now
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac
```

### Manual Override

Users can force specific architecture:

```bash
# Force AMD64 (native or emulated)
export AUTOGIT_ARCH=amd64

# Force ARM64 native
export AUTOGIT_ARCH=arm64

# Force ARM64 via QEMU on AMD64 host
export AUTOGIT_ARCH=arm64
export AUTOGIT_EMULATION=qemu

# Force RISC-V (always emulated)
export AUTOGIT_ARCH=riscv64
```

## Docker Multi-Architecture Build

### Buildx Configuration

```yaml
# docker-bake.hcl
group "default" {
  targets = ["git-server", "runner-coordinator"]
}

target "git-server" {
  context = "./services/git-server"
  platforms = [
    "linux/amd64",     # AMD64 native (MVP)
    "linux/arm64",     # ARM64 native (Phase 2)
    "linux/riscv64"    # RISC-V QEMU (Phase 3)
  ]
  tags = [
    "autogit/git-server:latest",
    "autogit/git-server:${VERSION}"
  ]
}
```

### MVP Build (AMD64 Only)

```bash
# Build for AMD64 only during MVP
docker buildx build \
  --platform linux/amd64 \
  -t autogit/git-server:latest \
  -f services/git-server/Dockerfile \
  services/git-server/
```

### Multi-Arch Build (Post-MVP)

```bash
# Build for multiple architectures
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/riscv64 \
  -t autogit/git-server:latest \
  -f services/git-server/Dockerfile \
  services/git-server/ \
  --push
```

## QEMU Setup

### Installing QEMU for Multi-Arch

```bash
# Install QEMU user-mode emulation
sudo apt-get update
sudo apt-get install -y qemu-user-static binfmt-support

# Verify QEMU is available
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Check available platforms
docker buildx ls
```

### Docker Compose with QEMU

```yaml
# docker-compose.yml
version: '3.8'

services:
  git-server:
    image: autogit/git-server:latest
    platform: ${AUTOGIT_PLATFORM:-linux/amd64}  # Default to AMD64
    # ... rest of config
```

## Performance Considerations

### Native Performance

- **AMD64 Native**: Baseline performance (100%)
- **ARM64 Native**: ~95-105% of AMD64 (architecture dependent)
- **RISC-V Native**: TBD (future hardware)

### QEMU Emulation Performance

- **ARM64 on AMD64 via QEMU**: ~30-50% of native
- **RISC-V on AMD64 via QEMU**: ~20-40% of native
- **Overhead**: CPU-intensive operations suffer most
- **Acceptable**: For testing and development

### Recommendations

1. **Production**: Use native architecture when possible
1. **Development**: QEMU emulation acceptable
1. **Testing**: QEMU useful for cross-platform validation
1. **CI/CD**: Native runners preferred

## Testing Strategy

### Phase 1 Testing (MVP - AMD64 Only)

```bash
# Run all tests on AMD64 native
./scripts/test.sh --arch amd64
```

**Coverage**:

- ✅ Unit tests
- ✅ Integration tests
- ✅ E2E tests
- ✅ Performance tests

### Phase 2 Testing (ARM64)

```bash
# Test on ARM64 native (when available)
./scripts/test.sh --arch arm64 --native

# Test ARM64 via QEMU on AMD64
./scripts/test.sh --arch arm64 --emulated
```

**Coverage**:

- ARM64 native functionality
- QEMU emulation functionality
- Cross-architecture compatibility
- Performance comparison

### Phase 3 Testing (RISC-V)

```bash
# Test RISC-V via QEMU
./scripts/test.sh --arch riscv64 --emulated
```

**Coverage**:

- Basic functionality
- Emulation stability
- Future readiness

## Documentation Requirements

### MVP Documentation (AMD64)

- ✅ AMD64 installation guide
- ✅ AMD64 deployment guide
- ✅ AMD64 troubleshooting

### Post-MVP Documentation (ARM64)

- [ ] ARM64 native installation
- [ ] ARM64 native deployment
- [ ] QEMU setup guide
- [ ] Architecture selection guide
- [ ] Performance comparison
- [ ] Troubleshooting multi-arch issues

### Future Documentation (RISC-V)

- [ ] RISC-V emulation setup
- [ ] RISC-V testing guide
- [ ] Known limitations

## Use Cases by Architecture

### AMD64 Use Cases

- Production deployments
- Development workstations
- Cloud deployments (AWS, GCP, Azure)
- Traditional data centers

### ARM64 Native Use Cases

- AWS Graviton instances
- Ampere Altra servers
- Apple Silicon development
- ARM-based edge devices
- Raspberry Pi 4/5 (self-hosted)
- Cost-effective cloud deployments

### ARM64 QEMU Use Cases

- Cross-platform development on AMD64
- Testing ARM64 images without hardware
- CI/CD pipelines without ARM64 runners
- Development and validation

### RISC-V Use Cases

- Future-proofing
- Academic/research environments
- Experimental deployments
- Emerging platform validation

## Migration Path

### For AMD64 Users

1. Deploy on AMD64 (MVP)
1. Stay on AMD64 (no migration needed)
1. Optional: Test ARM64 QEMU for development

### For ARM64 Users

1. Wait for Phase 2 completion
1. Deploy ARM64 native images
1. Enjoy native performance
1. Fallback to QEMU if needed

### For Mixed Environments

1. Deploy AMD64 for critical services
1. Deploy ARM64 native where available
1. Use QEMU for testing/development

## FAQ

### Q: Should I use ARM64 native or QEMU?

**A**: If you have ARM64 hardware, always use native. QEMU is for development/testing only.

### Q: When will ARM64 native support be available?

**A**: After AMD64 MVP is deployed and validated. See Phase 2 timeline.

### Q: Can I test ARM64 images before Phase 2?

**A**: Yes, using QEMU emulation on AMD64 hosts.

### Q: What about RISC-V?

**A**: RISC-V is experimental for future-proofing. Not recommended for production.

### Q: Which architecture should I choose?

**A**:

- **Production**: AMD64 native (MVP) or ARM64 native (Phase 2+)
- **Development**: Your native architecture
- **Testing**: Any architecture via QEMU

### Q: Can I mix architectures in a cluster?

**A**: Future feature. MVP focuses on single-architecture deployments.

## Current Status

- ✅ **AMD64 Native**: Ready for MVP testing
- ⏳ **ARM64 Native**: Planned for Phase 2
- ⏳ **ARM64 QEMU**: Planned for Phase 2
- 🔮 **RISC-V QEMU**: Future consideration

## Next Steps

1. ✅ Complete AMD64 MVP implementation
1. ✅ Deploy and validate AMD64 in production
1. ⏳ Implement ARM64 native support
1. ⏳ Add QEMU emulation support
1. ⏳ Test ARM64 (native and QEMU)
1. 🔮 Consider RISC-V when mature

______________________________________________________________________

**Last Updated**: 2025-12-21 **Status**: MVP (AMD64 Native Only) **Next Phase**: ARM64 Support
(Post-Deployment)
