//! TOML configuration file parsing

use serde::{Deserialize, Serialize};
use std::path::Path;

use crate::error::{Error, Result};

/// Complete autogit configuration from TOML file
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct AutogitConfig {
    /// GitLab connection settings
    #[serde(default)]
    pub gitlab: GitLabConfig,

    /// Bootstrap configuration (users, service accounts)
    #[serde(default)]
    pub bootstrap: BootstrapConfig,

    /// Mirror configurations
    #[serde(default)]
    pub mirrors: MirrorsConfig,

    /// Runner configurations
    #[serde(default)]
    pub runners: RunnersConfig,
}

impl AutogitConfig {
    /// Load configuration from TOML file
    pub fn from_file(path: impl AsRef<Path>) -> Result<Self> {
        let path = path.as_ref();

        if !path.exists() {
            return Err(Error::Config(format!(
                "Config file not found: {}",
                path.display()
            )));
        }

        let content = std::fs::read_to_string(path)
            .map_err(|e| Error::Config(format!("Failed to read config: {}", e)))?;

        Self::from_str(&content)
    }

    /// Parse configuration from TOML string
    pub fn from_str(content: &str) -> Result<Self> {
        toml::from_str(content)
            .map_err(|e| Error::Config(format!("Invalid TOML: {}", e)))
    }

    /// Check if config file exists at path
    pub fn exists(path: impl AsRef<Path>) -> bool {
        path.as_ref().exists()
    }

    /// Merge with environment overrides
    pub fn with_env_overrides(mut self) -> Self {
        // Override GitLab URL from env
        if let Ok(url) = std::env::var("GITLAB_URL") {
            self.gitlab.url = url;
        }

        // Token always comes from env for security
        self.gitlab.token = std::env::var("GITLAB_TOKEN").ok();

        self
    }

    /// Validate the configuration
    pub fn validate(&self) -> Result<()> {
        // Validate GitLab URL
        if self.gitlab.url.is_empty() {
            return Err(Error::Config("gitlab.url is required".into()));
        }

        // Validate bootstrap users
        for user in &self.bootstrap.users {
            if user.username.is_empty() {
                return Err(Error::Config("User username cannot be empty".into()));
            }
            if user.email.is_empty() {
                return Err(Error::Config(format!(
                    "User '{}' email cannot be empty",
                    user.username
                )));
            }
        }

        // Validate service accounts
        for svc in &self.bootstrap.services {
            if svc.username.is_empty() {
                return Err(Error::Config("Service username cannot be empty".into()));
            }
            if svc.scopes.is_empty() {
                return Err(Error::Config(format!(
                    "Service '{}' must have at least one scope",
                    svc.username
                )));
            }
        }

        // Validate mirrors
        for mirror in &self.mirrors.github {
            if mirror.repo.is_empty() {
                return Err(Error::Config("Mirror repo cannot be empty".into()));
            }
            if !mirror.repo.contains('/') {
                return Err(Error::Config(format!(
                    "Mirror repo '{}' must be in 'owner/repo' format",
                    mirror.repo
                )));
            }
        }

        Ok(())
    }
}

/// GitLab connection configuration
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct GitLabConfig {
    /// GitLab instance URL
    #[serde(default = "default_gitlab_url")]
    pub url: String,

    /// API token (should come from env var GITLAB_TOKEN)
    #[serde(skip_serializing)]
    pub token: Option<String>,
}

impl Default for GitLabConfig {
    fn default() -> Self {
        Self {
            url: default_gitlab_url(),
            token: None,
        }
    }
}

fn default_gitlab_url() -> String {
    "http://localhost:8080".to_string()
}

/// Bootstrap configuration for users and service accounts
#[derive(Debug, Clone, Default, Deserialize, Serialize)]
pub struct BootstrapConfig {
    /// Human users to create
    #[serde(default)]
    pub users: Vec<UserConfig>,

    /// Service accounts with API tokens
    #[serde(default)]
    pub services: Vec<ServiceConfig>,
}

/// User configuration
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct UserConfig {
    /// Username (login name)
    pub username: String,

    /// Email address
    pub email: String,

    /// Display name
    #[serde(default)]
    pub name: Option<String>,

    /// Admin privileges
    #[serde(default)]
    pub admin: bool,

    /// User role (optional, derived from admin flag)
    #[serde(default)]
    pub role: Option<String>,
}

impl UserConfig {
    /// Get display name, falling back to username
    pub fn display_name(&self) -> &str {
        self.name.as_deref().unwrap_or(&self.username)
    }
}

/// Service account configuration
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ServiceConfig {
    /// Service account username
    pub username: String,

    /// Service account email
    pub email: String,

    /// Token scopes
    pub scopes: Vec<String>,

    /// Admin privileges
    #[serde(default)]
    pub admin: bool,

    /// Token expiry in days (0 = no expiry)
    #[serde(default = "default_token_expiry")]
    pub token_expiry_days: u32,
}

fn default_token_expiry() -> u32 {
    365 // 1 year default
}

/// Mirrors configuration
#[derive(Debug, Clone, Default, Deserialize, Serialize)]
pub struct MirrorsConfig {
    /// Default namespace for mirrored repos
    #[serde(default = "default_namespace")]
    pub default_namespace: String,

    /// GitHub mirrors
    #[serde(default)]
    pub github: Vec<GitHubMirrorConfig>,

    /// GitLab mirrors (from other instances)
    #[serde(default)]
    pub gitlab: Vec<GitLabMirrorConfig>,
}

fn default_namespace() -> String {
    "mirrors".to_string()
}

/// GitHub repository mirror configuration
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct GitHubMirrorConfig {
    /// Repository in owner/repo format
    pub repo: String,

    /// Custom target path in GitLab (optional)
    #[serde(default)]
    pub target: Option<String>,

    /// Mirror direction (pull or push)
    #[serde(default = "default_direction")]
    pub direction: String,

    /// Only mirror protected branches
    #[serde(default)]
    pub protected_only: bool,

    /// Sync schedule (cron format, optional)
    #[serde(default)]
    pub schedule: Option<String>,
}

/// GitLab-to-GitLab mirror configuration
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct GitLabMirrorConfig {
    /// Source GitLab URL
    pub url: String,

    /// Repository path
    pub repo: String,

    /// Custom target path (optional)
    #[serde(default)]
    pub target: Option<String>,

    /// Mirror direction
    #[serde(default = "default_direction")]
    pub direction: String,
}

fn default_direction() -> String {
    "pull".to_string()
}

/// Runners configuration
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct RunnersConfig {
    /// Default executor type
    #[serde(default = "default_executor")]
    pub default_executor: String,

    /// Default Docker image
    #[serde(default = "default_image")]
    pub default_image: String,

    /// GPU runner configuration
    #[serde(default)]
    pub gpu: Option<GpuRunnerConfig>,

    /// Specific runner definitions
    #[serde(default)]
    pub runners: Vec<RunnerConfig>,
}

impl Default for RunnersConfig {
    fn default() -> Self {
        Self {
            default_executor: default_executor(),
            default_image: default_image(),
            gpu: None,
            runners: Vec::new(),
        }
    }
}

fn default_executor() -> String {
    "docker".to_string()
}

fn default_image() -> String {
    "docker:24.0".to_string()
}

/// GPU-specific runner configuration
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct GpuRunnerConfig {
    /// Enable GPU support
    #[serde(default)]
    pub enabled: bool,

    /// GPU-related tags
    #[serde(default)]
    pub tags: Vec<String>,

    /// GPU device specifications ("all" or specific device IDs)
    #[serde(default)]
    pub devices: Vec<String>,

    /// NVIDIA runtime to use
    #[serde(default = "default_nvidia_runtime")]
    pub runtime: String,
}

fn default_nvidia_runtime() -> String {
    "nvidia".to_string()
}

/// Individual runner definition
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct RunnerConfig {
    /// Runner name/description
    pub name: String,

    /// Executor type (docker, shell, etc.)
    #[serde(default = "default_executor")]
    pub executor: String,

    /// Tags for this runner
    #[serde(default)]
    pub tags: Vec<String>,

    /// Run untagged jobs
    #[serde(default)]
    pub run_untagged: bool,

    /// Locked to projects
    #[serde(default)]
    pub locked: bool,

    /// Maximum job timeout in seconds
    #[serde(default)]
    pub max_timeout: Option<u64>,
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE_CONFIG: &str = r#"
[gitlab]
url = "http://192.168.1.170:8080"

[bootstrap]
[[bootstrap.users]]
username = "sysadmin"
email = "sysadmin@example.com"
name = "System Admin"
admin = true

[[bootstrap.users]]
username = "dev"
email = "dev@example.com"
name = "Developer"

[[bootstrap.services]]
username = "autogit-ci"
email = "ci@example.com"
scopes = ["api", "read_repository", "write_repository"]

[mirrors]
default_namespace = "github-mirrors"

[[mirrors.github]]
repo = "rust-lang/rust-analyzer"

[[mirrors.github]]
repo = "tokio-rs/tokio"
target = "mirrors/tokio"

[runners]
default_executor = "docker"
default_image = "alpine:latest"

[runners.gpu]
enabled = true
tags = ["gpu", "cuda"]
devices = ["all"]
"#;

    #[test]
    fn parse_sample_config() {
        let config = AutogitConfig::from_str(SAMPLE_CONFIG).unwrap();

        assert_eq!(config.gitlab.url, "http://192.168.1.170:8080");
        assert_eq!(config.bootstrap.users.len(), 2);
        assert_eq!(config.bootstrap.services.len(), 1);
        assert_eq!(config.mirrors.github.len(), 2);
        assert!(config.runners.gpu.is_some());
    }

    #[test]
    fn validate_config() {
        let config = AutogitConfig::from_str(SAMPLE_CONFIG).unwrap();
        config.validate().unwrap();
    }

    #[test]
    fn reject_invalid_mirror() {
        let bad_config = r#"
[gitlab]
url = "http://localhost"

[[mirrors.github]]
repo = "invalid-no-slash"
"#;
        let config = AutogitConfig::from_str(bad_config).unwrap();
        assert!(config.validate().is_err());
    }
}
