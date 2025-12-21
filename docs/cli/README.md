# CLI Reference

Command-line interface tools for AutoGit.

## Overview

AutoGit provides several CLI tools for managing and operating the platform.

## Available CLIs

### autogit CLI

Main command-line interface for AutoGit operations.

```bash
autogit [command] [options]
```

See [autogit CLI Reference](autogit.md) for detailed commands.

### runner-manager CLI

Manage runner instances and lifecycle.

```bash
runner-manager [command] [options]
```

See [runner-manager CLI Reference](runner-manager.md) for details.

### gpu-detector CLI

Query and test GPU detection.

```bash
gpu-detector [command] [options]
```

See [gpu-detector CLI Reference](gpu-detector.md) for details.

## Quick Reference

### Common Commands

#### Start AutoGit

```bash
# Docker Compose
autogit start

# With specific compose file
autogit start -f compose/dev/docker-compose.yml
```

#### Stop AutoGit

```bash
autogit stop
```

#### Check Status

```bash
autogit status
```

#### View Logs

```bash
autogit logs [service]
```

#### List Runners

```bash
runner-manager list
```

#### Provision Runner

```bash
runner-manager provision --arch amd64 --gpu nvidia
```

#### Detect GPUs

```bash
gpu-detector detect
```

### Configuration

#### View Current Configuration

```bash
autogit config show
```

#### Validate Configuration

```bash
autogit config validate
```

#### Set Configuration Value

```bash
autogit config set key=value
```

## Installation

### From Release

```bash
# Download latest release
curl -LO https://github.com/tzervas/autogit/releases/latest/download/autogit-cli

# Make executable
chmod +x autogit-cli

# Move to PATH
sudo mv autogit-cli /usr/local/bin/autogit
```

### From Source

```bash
# Clone repository
git clone https://github.com/tzervas/autogit.git
cd autogit

# Install CLI
pip install -e src/cli/
```

## Shell Completion

### Bash

```bash
# Generate completion
autogit completion bash > /etc/bash_completion.d/autogit

# Or for current user
autogit completion bash > ~/.autogit-completion.bash
echo 'source ~/.autogit-completion.bash' >> ~/.bashrc
```

### Zsh

```bash
# Generate completion
autogit completion zsh > "${fpath[1]}/_autogit"
```

### Fish

```bash
# Generate completion
autogit completion fish > ~/.config/fish/completions/autogit.fish
```

## Environment Variables

CLI tools respect these environment variables:

- `AUTOGIT_CONFIG` - Path to configuration file
- `AUTOGIT_LOG_LEVEL` - Logging level (debug, info, warn, error)
- `AUTOGIT_API_URL` - API endpoint URL
- `AUTOGIT_API_TOKEN` - API authentication token

## Output Formats

Most commands support multiple output formats:

```bash
# JSON output
autogit status --output json

# YAML output
autogit status --output yaml

# Table output (default)
autogit status --output table
```

## Scripting

### Exit Codes

- `0` - Success
- `1` - General error
- `2` - Configuration error
- `3` - Network error
- `4` - Resource not found
- `5` - Permission denied

### JSON Output for Scripts

```bash
#!/bin/bash
runners=$(autogit runners list --output json)
count=$(echo "$runners" | jq '.total')
echo "Total runners: $count"
```

## Examples

### Provision Runners for Different Architectures

```bash
# AMD64 with NVIDIA GPU
runner-manager provision --arch amd64 --gpu nvidia

# ARM64 without GPU
runner-manager provision --arch arm64

# RISC-V (emulated)
runner-manager provision --arch riscv
```

### Monitor System

```bash
# Watch runner status
watch -n 5 'runner-manager list'

# Monitor GPU usage
watch -n 2 'gpu-detector status'

# Follow logs
autogit logs --follow runner-coordinator
```

### Batch Operations

```bash
# Deprovision all idle runners
runner-manager list --status idle --output json | \
  jq -r '.[].id' | \
  xargs -I {} runner-manager deprovision {}
```

## Troubleshooting

### CLI Not Found

Ensure CLI is in your PATH:

```bash
which autogit
```

If not found, install or add to PATH.

### Permission Denied

Check file permissions:

```bash
ls -l $(which autogit)
chmod +x $(which autogit)
```

### Connection Refused

Check service is running:

```bash
autogit status
```

Verify API URL:

```bash
echo $AUTOGIT_API_URL
```

## References

- [autogit CLI](autogit.md) - Main CLI reference
- [runner-manager CLI](runner-manager.md) - Runner management
- [gpu-detector CLI](gpu-detector.md) - GPU detection
- [Configuration Guide](../configuration/README.md) - Configuration
- [API Documentation](../api/README.md) - API reference
