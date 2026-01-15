//! Config command - configuration management

use crate::ConfigCommands;
use autogit_core::config::AutogitConfig;
use autogit_core::Result;
use std::path::Path;
use tracing::info;

pub async fn run(action: ConfigCommands, config_path: &str) -> Result<()> {
    match action {
        ConfigCommands::Show => show_config(config_path).await,
        ConfigCommands::Validate => validate_config(config_path).await,
        ConfigCommands::Init { force } => init_config(config_path, force).await,
    }
}

async fn show_config(config_path: &str) -> Result<()> {
    info!("📋 Configuration: {}", config_path);

    if !Path::new(config_path).exists() {
        info!("  Config file not found, using environment variables");

        // Show env-based config
        let config = autogit_core::config::Config::from_env()?;
        info!("  gitlab_url: {}", config.gitlab_url);
        info!(
            "  gitlab_token: {}",
            if config.gitlab_token.is_some() {
                "[SET]"
            } else {
                "[NOT SET]"
            }
        );
        info!("  log_level: {}", config.log_level);
        return Ok(());
    }

    // Read and display TOML config
    let content = std::fs::read_to_string(config_path)?;
    info!("---");
    for line in content.lines() {
        // Redact any token values
        if line.contains("token") && line.contains('=') {
            let parts: Vec<&str> = line.splitn(2, '=').collect();
            if parts.len() == 2 {
                info!("{} = [REDACTED]", parts[0].trim());
                continue;
            }
        }
        info!("{}", line);
    }
    info!("---");

    Ok(())
}

async fn validate_config(config_path: &str) -> Result<()> {
    info!("🔍 Validating configuration: {}", config_path);

    if !Path::new(config_path).exists() {
        info!("  ⚠️  Config file not found: {}", config_path);
        info!("  Using environment variables instead");

        // Validate env-based config
        match autogit_core::config::Config::from_env() {
            Ok(config) => {
                info!("  ✅ Environment configuration valid");
                if config.gitlab_token.is_none() {
                    info!("  ⚠️  GITLAB_TOKEN not set");
                }
            }
            Err(e) => {
                info!("  ❌ Environment configuration invalid: {}", e);
                return Err(e);
            }
        }
        return Ok(());
    }

    // Parse and validate TOML config
    let config = AutogitConfig::from_file(config_path)?;
    info!("  ✅ TOML syntax valid");

    // Apply validation rules
    config.validate()?;
    info!("  ✅ Configuration schema valid");

    // Summary
    info!("");
    info!("Configuration summary:");
    info!("  GitLab URL: {}", config.gitlab.url);
    info!("  Users: {}", config.bootstrap.users.len());
    info!("  Service accounts: {}", config.bootstrap.services.len());
    info!("  GitHub mirrors: {}", config.mirrors.github.len());
    info!("  GitLab mirrors: {}", config.mirrors.gitlab.len());
    if config
        .runners
        .gpu
        .as_ref()
        .map(|g| g.enabled)
        .unwrap_or(false)
    {
        info!("  GPU runners: enabled");
    }

    info!("");
    info!("  ✅ Configuration valid");
    Ok(())
}

async fn init_config(config_path: &str, force: bool) -> Result<()> {
    info!("📝 Initializing configuration: {}", config_path);

    if Path::new(config_path).exists() && !force {
        return Err(autogit_core::Error::Config(format!(
            "Config file already exists: {}. Use --force to overwrite.",
            config_path
        )));
    }

    let template = r#"# Autogit Configuration
# See: https://github.com/tzervas/autogit

[gitlab]
# GitLab instance URL
url = "http://localhost:8080"

# Token is loaded from GITLAB_TOKEN environment variable for security
# DO NOT put tokens in this file

[bootstrap]
# Users to create during bootstrap
[[bootstrap.users]]
username = "sysadmin"
email = "sysadmin@example.com"
name = "System Admin"
admin = true

[[bootstrap.users]]
username = "dev"
email = "dev@example.com"
name = "Developer"
admin = false

# Service accounts with tokens
[[bootstrap.services]]
username = "autogit-ci"
email = "ci@example.com"
scopes = ["api", "read_repository", "write_repository"]

[[bootstrap.services]]
username = "autogit-backup"
email = "backup@example.com"
scopes = ["api", "read_repository", "sudo"]
admin = true

[mirrors]
# Default target namespace for mirrored repos
default_namespace = "mirrors"

# GitHub mirrors
[[mirrors.github]]
repo = "owner/repo"
# PAT loaded from GITHUB_PAT_MIRROR env var

[runners]
# Default runner configuration
default_executor = "docker"
default_image = "docker:24.0"

# GPU runner configuration
[runners.gpu]
enabled = true
tags = ["gpu", "cuda"]
devices = ["all"]
"#;

    std::fs::write(config_path, template)?;
    info!("  ✅ Created: {}", config_path);
    info!("");
    info!("Next steps:");
    info!("  1. Edit {} with your settings", config_path);
    info!("  2. Set GITLAB_TOKEN environment variable");
    info!("  3. Run: autogit config validate");

    Ok(())
}
