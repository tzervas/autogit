//! Project management types and operations

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// GitLab project representation
#[derive(Debug, Clone, Deserialize)]
pub struct Project {
    pub id: u64,
    pub name: String,
    pub path: String,
    pub path_with_namespace: String,
    pub description: Option<String>,
    pub visibility: Visibility,
    pub created_at: DateTime<Utc>,
    pub default_branch: Option<String>,
    pub ssh_url_to_repo: String,
    pub http_url_to_repo: String,
    pub web_url: String,
    #[serde(default)]
    pub namespace: Option<ProjectNamespace>,
    #[serde(default)]
    pub mirror: bool,
    #[serde(default)]
    pub import_status: Option<String>,
}

/// Project namespace info
#[derive(Debug, Clone, Deserialize)]
pub struct ProjectNamespace {
    pub id: u64,
    pub name: String,
    pub path: String,
    pub kind: String,
    pub full_path: String,
}

/// Project visibility level
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Visibility {
    Private,
    Internal,
    Public,
}

impl Default for Visibility {
    fn default() -> Self {
        Self::Private
    }
}

/// Request to create a new project
#[derive(Debug, Clone, Serialize)]
pub struct CreateProjectRequest {
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub path: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub namespace_id: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    pub visibility: Visibility,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub import_url: Option<String>,
    #[serde(default)]
    pub mirror: bool,
    #[serde(default)]
    pub initialize_with_readme: bool,
}

impl CreateProjectRequest {
    /// Create a new project request
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            path: None,
            namespace_id: None,
            description: None,
            visibility: Visibility::Private,
            import_url: None,
            mirror: false,
            initialize_with_readme: false,
        }
    }

    /// Set custom path (defaults to slugified name)
    pub fn path(mut self, path: impl Into<String>) -> Self {
        self.path = Some(path.into());
        self
    }

    /// Set target namespace/group
    pub fn namespace_id(mut self, id: u64) -> Self {
        self.namespace_id = Some(id);
        self
    }

    /// Set project description
    pub fn description(mut self, desc: impl Into<String>) -> Self {
        self.description = Some(desc.into());
        self
    }

    /// Set visibility level
    pub fn visibility(mut self, vis: Visibility) -> Self {
        self.visibility = vis;
        self
    }

    /// Set import URL (for mirroring)
    pub fn import_url(mut self, url: impl Into<String>) -> Self {
        self.import_url = Some(url.into());
        self
    }

    /// Enable as mirror
    pub fn mirror(mut self, enabled: bool) -> Self {
        self.mirror = enabled;
        self
    }

    /// Initialize with README
    pub fn with_readme(mut self) -> Self {
        self.initialize_with_readme = true;
        self
    }
}

/// Mirror configuration for a project
#[derive(Debug, Clone, Serialize)]
pub struct MirrorConfig {
    /// Mirror URL (source for pull, target for push)
    pub url: String,
    /// Enable the mirror
    pub enabled: bool,
    /// Only for protected branches
    #[serde(default)]
    pub only_protected_branches: bool,
    /// Keep divergent refs (push mirrors)
    #[serde(default)]
    pub keep_divergent_refs: bool,
}

/// Pull mirror settings update
#[derive(Debug, Clone, Serialize)]
pub struct UpdatePullMirrorRequest {
    pub mirror: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub import_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mirror_user_id: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mirror_trigger_builds: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub only_mirror_protected_branches: Option<bool>,
}

impl UpdatePullMirrorRequest {
    pub fn enable(import_url: impl Into<String>) -> Self {
        Self {
            mirror: true,
            import_url: Some(import_url.into()),
            mirror_user_id: None,
            mirror_trigger_builds: Some(true),
            only_mirror_protected_branches: Some(false),
        }
    }

    pub fn disable() -> Self {
        Self {
            mirror: false,
            import_url: None,
            mirror_user_id: None,
            mirror_trigger_builds: None,
            only_mirror_protected_branches: None,
        }
    }
}

/// Namespace/Group info
#[derive(Debug, Clone, Deserialize)]
pub struct Namespace {
    pub id: u64,
    pub name: String,
    pub path: String,
    pub kind: String,
    pub full_path: String,
    #[serde(default)]
    pub parent_id: Option<u64>,
}

/// Request to create a group
#[derive(Debug, Clone, Serialize)]
pub struct CreateGroupRequest {
    pub name: String,
    pub path: String,
    pub visibility: Visibility,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parent_id: Option<u64>,
}

impl CreateGroupRequest {
    pub fn new(name: impl Into<String>, path: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            path: path.into(),
            visibility: Visibility::Private,
            description: None,
            parent_id: None,
        }
    }

    pub fn visibility(mut self, vis: Visibility) -> Self {
        self.visibility = vis;
        self
    }

    pub fn description(mut self, desc: impl Into<String>) -> Self {
        self.description = Some(desc.into());
        self
    }

    pub fn parent(mut self, parent_id: u64) -> Self {
        self.parent_id = Some(parent_id);
        self
    }
}
