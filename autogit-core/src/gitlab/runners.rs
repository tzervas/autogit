//! GitLab runner management types and operations

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Runner information
#[derive(Debug, Clone, Deserialize)]
pub struct Runner {
    pub id: u64,
    pub description: Option<String>,
    pub ip_address: Option<String>,
    pub active: bool,
    pub paused: bool,
    pub is_shared: bool,
    pub runner_type: RunnerType,
    pub name: Option<String>,
    pub online: bool,
    pub status: RunnerStatus,
    #[serde(default)]
    pub tag_list: Vec<String>,
}

/// Runner detail (extended info)
#[derive(Debug, Clone, Deserialize)]
pub struct RunnerDetail {
    pub id: u64,
    pub description: Option<String>,
    pub ip_address: Option<String>,
    pub active: bool,
    pub paused: bool,
    pub is_shared: bool,
    pub runner_type: RunnerType,
    pub name: Option<String>,
    pub online: bool,
    pub status: RunnerStatus,
    #[serde(default)]
    pub tag_list: Vec<String>,
    pub version: Option<String>,
    pub revision: Option<String>,
    pub platform: Option<String>,
    pub architecture: Option<String>,
    pub contacted_at: Option<DateTime<Utc>>,
    #[serde(default)]
    pub projects: Vec<RunnerProject>,
}

/// Project associated with a runner
#[derive(Debug, Clone, Deserialize)]
pub struct RunnerProject {
    pub id: u64,
    pub name: String,
    pub name_with_namespace: String,
    pub path: String,
    pub path_with_namespace: String,
}

/// Runner type
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum RunnerType {
    InstanceType,
    GroupType,
    ProjectType,
}

/// Runner status
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum RunnerStatus {
    Online,
    Offline,
    Stale,
    NeverContacted,
    #[serde(other)]
    Unknown,
}

/// Request to register a new runner
#[derive(Debug, Clone, Serialize)]
pub struct RegisterRunnerRequest {
    /// Registration token from GitLab
    pub token: String,
    /// Runner description
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    /// Runner info (usually hostname)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub info: Option<RunnerInfo>,
    /// Whether to run untagged jobs
    #[serde(default)]
    pub run_untagged: bool,
    /// Whether runner is locked to current project
    #[serde(default)]
    pub locked: bool,
    /// Tags for the runner
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub tag_list: Vec<String>,
    /// Access level (ref_protected, not_protected)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub access_level: Option<String>,
    /// Maximum job timeout
    #[serde(skip_serializing_if = "Option::is_none")]
    pub maximum_timeout: Option<u64>,
}

/// Runner system info
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RunnerInfo {
    pub name: Option<String>,
    pub version: Option<String>,
    pub revision: Option<String>,
    pub platform: Option<String>,
    pub architecture: Option<String>,
}

impl RegisterRunnerRequest {
    pub fn new(token: impl Into<String>) -> Self {
        Self {
            token: token.into(),
            description: None,
            info: None,
            run_untagged: false,
            locked: false,
            tag_list: Vec::new(),
            access_level: None,
            maximum_timeout: None,
        }
    }

    pub fn description(mut self, desc: impl Into<String>) -> Self {
        self.description = Some(desc.into());
        self
    }

    pub fn info(mut self, info: RunnerInfo) -> Self {
        self.info = Some(info);
        self
    }

    pub fn run_untagged(mut self, enabled: bool) -> Self {
        self.run_untagged = enabled;
        self
    }

    pub fn locked(mut self, locked: bool) -> Self {
        self.locked = locked;
        self
    }

    pub fn tags(mut self, tags: Vec<String>) -> Self {
        self.tag_list = tags;
        self
    }

    pub fn add_tag(mut self, tag: impl Into<String>) -> Self {
        self.tag_list.push(tag.into());
        self
    }

    pub fn protected_only(mut self) -> Self {
        self.access_level = Some("ref_protected".to_string());
        self
    }

    pub fn timeout(mut self, seconds: u64) -> Self {
        self.maximum_timeout = Some(seconds);
        self
    }
}

/// Response from runner registration
#[derive(Debug, Clone, Deserialize)]
pub struct RegisterRunnerResponse {
    pub id: u64,
    pub token: String,
    #[serde(default)]
    pub token_expires_at: Option<DateTime<Utc>>,
}

/// Request to update runner settings
#[derive(Debug, Clone, Serialize, Default)]
pub struct UpdateRunnerRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub active: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub paused: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tag_list: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub run_untagged: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub locked: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub access_level: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub maximum_timeout: Option<u64>,
}

impl UpdateRunnerRequest {
    pub fn pause() -> Self {
        Self {
            paused: Some(true),
            ..Default::default()
        }
    }

    pub fn unpause() -> Self {
        Self {
            paused: Some(false),
            ..Default::default()
        }
    }

    pub fn deactivate() -> Self {
        Self {
            active: Some(false),
            ..Default::default()
        }
    }
}
