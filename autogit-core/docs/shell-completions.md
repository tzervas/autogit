# Shell Completions & Starship Integration

## Shell Completions

autogit supports shell completions for all major shells including nushell.

### Available Shells

| Shell      | Command                           |
| ---------- | --------------------------------- |
| Bash       | `autogit completions bash`        |
| Zsh        | `autogit completions zsh`         |
| Fish       | `autogit completions fish`        |
| PowerShell | `autogit completions power-shell` |
| Elvish     | `autogit completions elvish`      |
| Nushell    | `autogit completions nushell`     |

### Installation

#### Bash

```bash
# Add to ~/.bashrc
source <(autogit completions bash)

# Or generate to file (faster shell startup)
autogit completions bash > ~/.local/share/bash-completion/completions/autogit
```

#### Zsh

```zsh
# Add to ~/.zshrc (before compinit)
source <(autogit completions zsh)

# Or generate to fpath location
autogit completions zsh > ~/.zsh/completions/_autogit
# Ensure ~/.zsh/completions is in fpath:
# fpath=(~/.zsh/completions $fpath)
```

#### Fish

```fish
# Add to ~/.config/fish/config.fish
autogit completions fish | source

# Or generate to completions directory
autogit completions fish > ~/.config/fish/completions/autogit.fish
```

#### Nushell

```nu
# Generate completions module
autogit completions nushell | save ~/.config/nushell/autogit-completions.nu

# Add to your config.nu
use ~/.config/nushell/autogit-completions.nu *
```

#### PowerShell

```powershell
# Add to $PROFILE
Invoke-Expression (& autogit completions power-shell | Out-String)
```

______________________________________________________________________

## Starship Prompt Integration

autogit includes a hidden `_starship` command optimized for prompt integration.

### Features

- **Fast**: Caches results for 30 seconds to avoid API hammering
- **Minimal**: Single-line output with status indicators
- **Smart**: Shows connection status, mirror count, runner count

### Status Indicators

| Symbol | Meaning                              |
| ------ | ------------------------------------ |
| `⬡`    | GitLab connected                     |
| `⬢`    | GitLab disconnected / not configured |
| `M:N`  | N mirrors configured                 |
| `R:N`  | N runners online                     |

Example output: `⬡ M:3 R:2` = connected, 3 mirrors, 2 runners active

### Starship Configuration

Add to `~/.config/starship.toml`:

```toml
[custom.autogit]
command = "autogit _starship"
when = "command -v autogit"
format = "[$output]($style) "
style = "bold purple"
# Cache handled by autogit internally, but starship also caches
```

### Environment Variables Required

The `_starship` command reads from environment variables:

```bash
export GITLAB_URL="http://192.168.1.170:8080"
export GITLAB_TOKEN="glpat-your-token-here"
```

Add these to your shell profile (`.bashrc`, `.zshrc`, `config.fish`, etc.)

### Alternative: Show Only When Connected

```toml
[custom.autogit]
command = "autogit _starship"
when = "[[ -n $GITLAB_URL ]] && command -v autogit"
format = "[$output]($style) "
style = "bold purple"
```

### Nushell + Starship

For nushell users with starship, add to `env.nu`:

```nu
$env.GITLAB_URL = "http://192.168.1.170:8080"
$env.GITLAB_TOKEN = (open ~/.gitlab-token | str trim)

# Starship init (if not already configured)
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
```

______________________________________________________________________

## Cache Location

The starship integration caches status at `/tmp/autogit-starship-cache` with a 30-second TTL. This
prevents excessive API calls when your prompt refreshes frequently.

To force a fresh status check, delete the cache:

```bash
rm /tmp/autogit-starship-cache
```
