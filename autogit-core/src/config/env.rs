//! Environment-based configuration

use serde::Deserialize;

use crate::error::{Error, Result};
use crate::gitlab::{AuthMethod, Token};

/// Application configuration loaded from environment
#[derive(Debug, Clone, Deserialize)]
pub struct Config {
    /// GitLab instance URL
    #[serde(default = "default_gitlab_url")]
    pub gitlab_url: String,

    /// GitLab API token
    pub gitlab_token: Option<String>,

    /// Log level
    #[serde(default = "default_log_level")]
    pub log_level: String,
}

fn default_gitlab_url() -> String {
    "http://localhost:8080".to_string()
}

fn default_log_level() -> String {
    "info".to_string()
}

impl Config {
    /// Load configuration from environment variables
    ///
    /// Variables:
    /// - `GITLAB_URL` - GitLab instance URL (default: http://localhost:8080)
    /// - `GITLAB_TOKEN` - Personal access token (required)
    /// - `LOG_LEVEL` - Log level (default: info)
    pub fn from_env() -> Result<Self> {
        // Load .env file if present (ignore errors)
        let _ = dotenvy::dotenv();

        // Try to get individual values with fallbacks
        let gitlab_url = std::env::var("GITLAB_URL")
            .or_else(|_| std::env::var("AUTOGIT_GITLAB_URL"))
            .unwrap_or_else(|_| default_gitlab_url());

        let gitlab_token = std::env::var("GITLAB_TOKEN")
            .or_else(|_| std::env::var("AUTOGIT_GITLAB_TOKEN"))
            .ok();

        let log_level = std::env::var("LOG_LEVEL")
            .or_else(|_| std::env::var("AUTOGIT_LOG_LEVEL"))
            .unwrap_or_else(|_| default_log_level());

        Ok(Self {
            gitlab_url,
            gitlab_token,
            log_level,
        })
    }

    /// Load from a specific .env file
    pub fn from_env_file(path: impl AsRef<std::path::Path>) -> Result<Self> {
        dotenvy::from_path(path.as_ref())
            .map_err(|e| Error::Config(format!("Failed to load env file: {}", e)))?;
        Self::from_env()
    }

    /// Get auth method from config
    pub fn auth(&self) -> Result<AuthMethod> {
        let token = self
            .gitlab_token
            .as_ref()
            .ok_or_else(|| Error::Config("GITLAB_TOKEN not set".into()))?;

        Ok(AuthMethod::PrivateToken(Token::new(token)))
    }

    /// Initialize tracing subscriber
    pub fn init_tracing(&self) {
        use tracing_subscriber::{fmt, prelude::*, EnvFilter};

        let filter =
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new(&self.log_level));

        tracing_subscriber::registry()
            .with(fmt::layer().with_target(true))
            .with(filter)
            .init();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn config_defaults() {
        // Clear any existing env vars
        std::env::remove_var("GITLAB_URL");
        std::env::remove_var("GITLAB_TOKEN");

        let config = Config::from_env().unwrap();
        assert_eq!(config.gitlab_url, "http://localhost:8080");
        assert!(config.gitlab_token.is_none());
    }
}
