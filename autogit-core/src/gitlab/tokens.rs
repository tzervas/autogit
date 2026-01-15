//! Personal Access Token management

use chrono::NaiveDate;
use serde::{Deserialize, Serialize};

use super::auth::Token;

/// Token scope (permission)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TokenScope {
    /// Full API access
    Api,
    /// Read-only API access
    ReadApi,
    /// Read user profile
    ReadUser,
    /// Read repository
    ReadRepository,
    /// Write repository
    WriteRepository,
    /// Read registry
    ReadRegistry,
    /// Write registry
    WriteRegistry,
    /// Admin sudo (impersonate users)
    Sudo,
    /// Create runner
    CreateRunner,
    /// Manage runner
    ManageRunner,
    /// AI features
    AiFeatures,
    /// Kubernetes agent
    K8sProxy,
}

impl TokenScope {
    /// Get all scopes for full automation
    pub fn automation() -> Vec<Self> {
        vec![Self::Api, Self::ReadRepository, Self::WriteRepository]
    }

    /// Get scopes for read-only service
    pub fn readonly() -> Vec<Self> {
        vec![Self::ReadApi, Self::ReadRepository]
    }

    /// Get scopes for backup service
    pub fn backup() -> Vec<Self> {
        vec![Self::Api, Self::ReadRepository, Self::Sudo]
    }

    /// Get scopes for CI service
    pub fn ci() -> Vec<Self> {
        vec![Self::Api, Self::ReadRepository, Self::WriteRepository]
    }
}

/// Request to create a personal access token
#[derive(Debug, Clone, Serialize)]
pub struct CreateTokenRequest {
    pub name: String,
    pub scopes: Vec<TokenScope>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub expires_at: Option<NaiveDate>,
}

impl CreateTokenRequest {
    /// Create a new token request
    pub fn new(name: impl Into<String>, scopes: Vec<TokenScope>) -> Self {
        Self {
            name: name.into(),
            scopes,
            expires_at: None,
        }
    }

    /// Set expiration date
    pub fn expires_at(mut self, date: NaiveDate) -> Self {
        self.expires_at = Some(date);
        self
    }

    /// Set expiration to N days from now
    pub fn expires_in_days(mut self, days: i64) -> Self {
        self.expires_at = Some(
            chrono::Utc::now()
                .date_naive()
                .checked_add_days(chrono::Days::new(days as u64))
                .expect("valid date"),
        );
        self
    }
}

/// Personal Access Token response from API
#[derive(Debug, Clone, Deserialize)]
pub struct PersonalAccessToken {
    pub id: u64,
    pub name: String,
    pub revoked: bool,
    pub created_at: String,
    pub scopes: Vec<String>,
    #[serde(default)]
    pub expires_at: Option<String>,
    /// Only present on creation
    #[serde(default)]
    token: Option<String>,
}

impl PersonalAccessToken {
    /// Get the token value (only available immediately after creation)
    pub fn token(&self) -> Option<Token> {
        self.token.as_ref().map(|t| Token::new(t.clone()))
    }

    /// Check if token is active
    pub fn is_active(&self) -> bool {
        !self.revoked
    }

    /// Check if token is expired
    pub fn is_expired(&self) -> bool {
        if let Some(expires) = &self.expires_at {
            if let Ok(date) = chrono::NaiveDate::parse_from_str(expires, "%Y-%m-%d") {
                return date < chrono::Utc::now().date_naive();
            }
        }
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn token_scopes_serialization() {
        let request =
            CreateTokenRequest::new("test", vec![TokenScope::Api, TokenScope::ReadRepository]);
        let json = serde_json::to_string(&request).unwrap();
        assert!(json.contains("\"api\""));
        assert!(json.contains("\"read_repository\""));
    }

    #[test]
    fn expires_in_days() {
        let request = CreateTokenRequest::new("test", vec![TokenScope::Api]).expires_in_days(365);
        assert!(request.expires_at.is_some());
    }
}
