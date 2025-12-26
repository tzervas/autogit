# Changelog

All notable changes to autogit-core will be documented in this file.

## [0.1.0] - 2025-12-25

### Added

#### Core Infrastructure
- GitLab API client with builder pattern and connection pooling
- Type-safe authentication (PrivateToken, OAuth, JobToken)
- Automatic retry logic with exponential backoff
- Security: HTTP only allowed for localhost/LAN IPs

#### Bootstrap Command
- User provisioning from TOML config
- Service account creation with scoped tokens
- Credential output to env file
- Dry-run support

#### Mirror Management
- `mirror add` - GitHub → GitLab pull mirroring
- `mirror list` - Show all configured mirrors
- `mirror sync` - Trigger immediate pull
- `mirror remove` - Disable mirroring or purge project
- `--purge` flag with two-level confirmation for destructive deletion

#### Runner Management
- `runner register` - Register new runners
- `runner list` - List all runners with status
- `runner status` - Detailed runner information
- `runner remove` - Deregister runners
- GPU auto-detection via nvidia-smi
- Tag management

#### Configuration
- `config show` - Display current settings
- `config validate` - Schema validation against TOML
- `config init` - Generate template config file
- Full TOML config parsing (AutogitConfig struct)

#### Output & UX
- `--format` flag: text, json, quiet
- JSON output for all list/status commands
- Human-readable text with emoji indicators
- Global `--dry-run` flag
- Verbose logging levels (-v, -vv)

#### Shell Integration
- Completions: bash, zsh, fish, powershell, elvish, nushell
- Starship prompt integration via `_starship` command
- 30-second cache for fast prompt response

### API Types
- `Project`, `CreateProjectRequest`, `MirrorConfig`
- `Runner`, `RunnerDetail`, `RegisterRunnerRequest`
- `User`, `CreateUserRequest`, `UserState`
- `Token`, `CreateTokenRequest`, `TokenScope`

### Dependencies
- clap 4.5 (CLI framework)
- clap_complete 4.5 (shell completions)
- clap_complete_nushell 4.5 (nushell support)
- reqwest (HTTP client)
- tokio (async runtime)
- serde/serde_json (serialization)
- toml (config parsing)
- tracing (structured logging)
- secrecy (secret handling)
- chrono (datetime)
