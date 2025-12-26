# autogit-core

Type-safe, fast GitLab automation CLI for self-hosted GitOps.

## Features

- **Bootstrap**: Automated user and service account provisioning
- **Mirror**: GitHub → GitLab pull mirroring with sync management
- **Runner**: GitLab runner registration and management with GPU support
- **Config**: TOML configuration with schema validation
- **Status**: Instance health and resource overview

## Installation

```bash
# Build from source
cargo build --release

# Binary located at target/release/autogit
```

## Quick Start

```bash
# Set environment variables
export GITLAB_URL="http://192.168.1.170:8080"
export GITLAB_TOKEN="glpat-your-token-here"

# Check connection
autogit status

# Bootstrap users from config
autogit bootstrap

# Add a mirror
autogit mirror add github:owner/repo --target mirrors

# List mirrors
autogit mirror list

# Register a runner with GPU support
autogit runner register --gpu --tags "cuda,ml"
```

## Configuration

Create `autogit.toml`:

```toml
[gitlab]
url = "http://192.168.1.170:8080"
# Token from GITLAB_TOKEN env var

[bootstrap]
[[bootstrap.users]]
username = "developer"
email = "dev@example.com"
admin = false

[[bootstrap.services]]
name = "ci-runner"
scopes = ["api", "read_repository"]

[mirrors]
default_group = "mirrors"
sync_interval = "1h"

[runners]
default_tags = ["docker", "linux"]
```

## Shell Completions

```bash
# Bash
autogit completions bash > ~/.local/share/bash-completion/completions/autogit

# Zsh
autogit completions zsh > ~/.zsh/completions/_autogit

# Fish
autogit completions fish > ~/.config/fish/completions/autogit.fish

# Nushell
autogit completions nushell | save ~/.config/nushell/autogit-completions.nu
```

See [docs/shell-completions.md](docs/shell-completions.md) for full details including Starship
integration.

## Commands

| Command                        | Description                             |
| ------------------------------ | --------------------------------------- |
| `autogit status`               | Show GitLab instance status             |
| `autogit bootstrap`            | Provision users and service accounts    |
| `autogit mirror add <source>`  | Add GitHub → GitLab mirror              |
| `autogit mirror list`          | List configured mirrors                 |
| `autogit mirror sync <repo>`   | Trigger immediate sync                  |
| `autogit mirror remove <repo>` | Remove mirror (with optional `--purge`) |
| `autogit runner register`      | Register new runner                     |
| `autogit runner list`          | List registered runners                 |
| `autogit runner status [id]`   | Show runner details                     |
| `autogit runner remove <id>`   | Remove runner                           |
| `autogit config show`          | Display current config                  |
| `autogit config validate`      | Validate config file                    |
| `autogit config init`          | Generate template config                |
| `autogit completions <shell>`  | Generate shell completions              |

## Output Formats

All commands support `--format` flag:

```bash
autogit status --format=json
autogit mirror list --format=json
autogit runner list --format=json
```

## Environment Variables

| Variable         | Description                                |
| ---------------- | ------------------------------------------ |
| `GITLAB_URL`     | GitLab instance URL                        |
| `GITLAB_TOKEN`   | GitLab API token (PAT or OAuth)            |
| `AUTOGIT_CONFIG` | Config file path (default: `autogit.toml`) |

## License

MIT
