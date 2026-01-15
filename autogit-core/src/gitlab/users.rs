//! User management types and operations

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// GitLab user representation
#[derive(Debug, Clone, Deserialize)]
pub struct User {
    pub id: u64,
    pub username: String,
    pub email: Option<String>,
    pub name: String,
    pub state: UserState,
    pub is_admin: bool,
    pub created_at: DateTime<Utc>,
    #[serde(default)]
    pub namespace: Option<Namespace>,
}

/// User namespace (personal or group)
#[derive(Debug, Clone, Deserialize)]
pub struct Namespace {
    pub id: u64,
    pub name: String,
    pub path: String,
}

/// User account state
#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum UserState {
    Active,
    Blocked,
    Deactivated,
    #[serde(other)]
    Unknown,
}

/// User role/access level
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[repr(u8)]
pub enum UserRole {
    Guest = 10,
    Reporter = 20,
    Developer = 30,
    Maintainer = 40,
    Owner = 50,
}

impl UserRole {
    pub fn as_access_level(&self) -> u8 {
        *self as u8
    }
}

/// Request to create a new user
#[derive(Debug, Clone)]
pub struct CreateUserRequest {
    pub username: String,
    pub email: String,
    pub name: String,
    password: secrecy::SecretString,
    pub is_admin: bool,
    pub skip_confirmation: bool,
    pub projects_limit: Option<u32>,
}

impl CreateUserRequest {
    /// Create a new user request
    pub fn new(
        username: impl Into<String>,
        email: impl Into<String>,
        name: impl Into<String>,
        password: impl Into<String>,
    ) -> Self {
        Self {
            username: username.into(),
            email: email.into(),
            name: name.into(),
            password: secrecy::SecretString::from(password.into()),
            is_admin: false,
            skip_confirmation: true,
            projects_limit: None,
        }
    }

    /// Set admin flag
    pub fn admin(mut self, is_admin: bool) -> Self {
        self.is_admin = is_admin;
        self
    }

    /// Set projects limit
    pub fn projects_limit(mut self, limit: u32) -> Self {
        self.projects_limit = Some(limit);
        self
    }

    /// Require email confirmation
    pub fn require_confirmation(mut self) -> Self {
        self.skip_confirmation = false;
        self
    }
}

// Custom serialization to include password in JSON but not in Debug
impl serde::Serialize for CreateUserRequest {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        use secrecy::ExposeSecret;
        use serde::ser::SerializeStruct;

        let mut state = serializer.serialize_struct("CreateUserRequest", 6)?;
        state.serialize_field("username", &self.username)?;
        state.serialize_field("email", &self.email)?;
        state.serialize_field("name", &self.name)?;
        state.serialize_field("password", self.password.expose_secret())?;
        state.serialize_field("admin", &self.is_admin)?;
        state.serialize_field("skip_confirmation", &self.skip_confirmation)?;
        if let Some(limit) = &self.projects_limit {
            state.serialize_field("projects_limit", limit)?;
        }
        state.end()
    }
}



#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn create_user_request_hides_password_in_debug() {
        let req = CreateUserRequest::new("test", "test@example.com", "Test", "secret123");
        let debug = format!("{:?}", req);
        assert!(!debug.contains("secret123"));
    }

    #[test]
    fn user_role_access_levels() {
        assert_eq!(UserRole::Guest.as_access_level(), 10);
        assert_eq!(UserRole::Developer.as_access_level(), 30);
        assert_eq!(UserRole::Owner.as_access_level(), 50);
    }
}
