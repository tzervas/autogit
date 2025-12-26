//! Authentication types with secure token handling

use secrecy::{ExposeSecret, SecretString};
use serde::{Deserialize, Serialize};
use std::fmt;

/// Authentication method for GitLab API
#[derive(Clone)]
pub enum AuthMethod {
    /// Personal Access Token (most common)
    PrivateToken(Token),
    /// OAuth2 Bearer Token
    OAuth2(Token),
    /// Job Token (CI/CD context)
    JobToken(Token),
}

impl AuthMethod {
    /// Get header name for this auth method
    pub fn header_name(&self) -> &'static str {
        match self {
            Self::PrivateToken(_) => "PRIVATE-TOKEN",
            Self::OAuth2(_) => "Authorization",
            Self::JobToken(_) => "JOB-TOKEN",
        }
    }

    /// Get header value (exposes secret - use carefully)
    pub fn header_value(&self) -> String {
        match self {
            Self::PrivateToken(t) | Self::JobToken(t) => t.expose().to_string(),
            Self::OAuth2(t) => format!("Bearer {}", t.expose()),
        }
    }
}

// Custom Debug to avoid leaking tokens
impl fmt::Debug for AuthMethod {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::PrivateToken(_) => write!(f, "AuthMethod::PrivateToken([REDACTED])"),
            Self::OAuth2(_) => write!(f, "AuthMethod::OAuth2([REDACTED])"),
            Self::JobToken(_) => write!(f, "AuthMethod::JobToken([REDACTED])"),
        }
    }
}

/// Secure token wrapper - zeroes memory on drop
#[derive(Clone)]
pub struct Token(SecretString);

impl Token {
    /// Create new token from string
    pub fn new(value: impl Into<String>) -> Self {
        Self(SecretString::from(value.into()))
    }

    /// Expose the secret value (use sparingly)
    pub fn expose(&self) -> &str {
        self.0.expose_secret()
    }

    /// Check if token looks valid (basic format check)
    pub fn is_valid_format(&self) -> bool {
        let s = self.expose();
        // GitLab PAT format: glpat-XXXX or older format
        s.starts_with("glpat-") || s.len() >= 20
    }
}

// Never print token values
impl fmt::Debug for Token {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Token([REDACTED])")
    }
}

impl fmt::Display for Token {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "[REDACTED]")
    }
}

// Allow deserializing tokens from config
impl<'de> Deserialize<'de> for Token {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        Ok(Token::new(s))
    }
}

// Serialize as redacted (never write actual token)
impl Serialize for Token {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_str("[REDACTED]")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn token_never_prints_value() {
        let token = Token::new("glpat-supersecret123");
        let debug = format!("{:?}", token);
        let display = format!("{}", token);

        assert!(!debug.contains("supersecret"));
        assert!(!display.contains("supersecret"));
        assert!(debug.contains("REDACTED"));
    }

    #[test]
    fn token_validates_format() {
        assert!(Token::new("glpat-abcdefghij123456").is_valid_format());
        assert!(Token::new("12345678901234567890").is_valid_format());
        assert!(!Token::new("short").is_valid_format());
    }
}
