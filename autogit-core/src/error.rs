//! Error types for autogit-core

use thiserror::Error;

/// Primary error type
#[derive(Error, Debug)]
pub enum Error {
    #[error("GitLab API error: {status} - {message}")]
    GitLabApi {
        status: u16,
        message: String,
        #[source]
        source: Option<Box<dyn std::error::Error + Send + Sync>>,
    },

    #[error("Authentication failed: {0}")]
    Authentication(String),

    #[error("User not found: {0}")]
    UserNotFound(String),

    #[error("User already exists: {0}")]
    UserExists(String),

    #[error("Invalid configuration: {0}")]
    Config(String),

    #[error("Credential error: {0}")]
    Credential(String),

    #[error("HTTP request failed")]
    Http(#[from] reqwest::Error),

    #[error("JSON serialization error")]
    Json(#[from] serde_json::Error),

    #[error("URL parse error")]
    Url(#[from] url::ParseError),

    #[error("IO error")]
    Io(#[from] std::io::Error),
}

impl Error {
    /// Create GitLab API error from response
    pub fn gitlab_api(status: u16, message: impl Into<String>) -> Self {
        Self::GitLabApi {
            status,
            message: message.into(),
            source: None,
        }
    }

    /// Check if error is retryable (rate limit, server error)
    pub fn is_retryable(&self) -> bool {
        match self {
            Self::GitLabApi { status, .. } => {
                *status == 429 || *status >= 500
            }
            Self::Http(e) => e.is_timeout() || e.is_connect(),
            _ => false,
        }
    }
}

/// Result type alias
pub type Result<T> = std::result::Result<T, Error>;
