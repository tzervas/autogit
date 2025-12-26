# GPU Support

AutoGit provides GPU-aware scheduling for accelerated workloads.

## Overview

AutoGit automatically detects and schedules jobs to runners with appropriate GPU resources.

## Supported GPU Vendors

- **NVIDIA** - CUDA-enabled GPUs
- **AMD** - ROCm-enabled GPUs
- **Intel** - oneAPI-enabled GPUs

## GPU Detection

AutoGit includes a GPU detection service that:

- Automatically discovers available GPUs
- Reports GPU capabilities (compute, memory, etc.)
- Tracks GPU utilization
- Assigns GPUs to appropriate runners

See [GPU Detection](detection.md) for technical details.

## GPU Scheduling

The runner coordinator schedules jobs based on:

- Required GPU vendor
- Required compute capability
- Memory requirements
- Current GPU utilization

See [GPU Scheduling](scheduling.md) for algorithm details.

## Configuration

### NVIDIA GPUs

```yaml
gpu:
  nvidia:
    enabled: true
    runtime: nvidia
    devices: all
```

See [NVIDIA Configuration](nvidia.md) for details.

### AMD GPUs

```yaml
gpu:
  amd:
    enabled: true
    runtime: rocm
    devices: all
```

See [AMD Configuration](amd.md) for details.

### Intel GPUs

```yaml
gpu:
  intel:
    enabled: true
    runtime: level-zero
    devices: all
```

See [Intel Configuration](intel.md) for details.

## Usage in CI/CD Pipelines

Example `.gitlab-ci.yml` with GPU:

```yaml
train_model:
  tags:
    - gpu
    - nvidia
    - cuda-12
  script:
    - python train.py --gpu
```

See [GPU Workloads Tutorial](../tutorials/gpu-workloads.md) for examples.

## Troubleshooting

Common GPU issues:

- [GPU not detected](../troubleshooting/gpu.md#detection)
- [Insufficient GPU memory](../troubleshooting/gpu.md#memory)
- [Driver version mismatches](../troubleshooting/gpu.md#drivers)

See [GPU Troubleshooting](../troubleshooting/gpu.md) for details.
