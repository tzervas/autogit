//! autogit-core: Type-safe GitLab automation
//!
//! # Security Model
//! - All tokens wrapped in `secrecy::SecretString` (zeroed on drop)
//! - No credentials in Debug output
//! - TLS required for non-localhost connections

pub mod config;
pub mod credentials;
pub mod error;
pub mod gitlab;

pub use error::{Error, Result};
pub use gitlab::GitLabClient;
