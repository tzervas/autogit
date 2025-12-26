//! Output formatting utilities

use serde::Serialize;
use tracing::info;

/// Output format for CLI commands
#[derive(Clone, Copy, Default, clap::ValueEnum)]
pub enum OutputFormat {
    #[default]
    Text,
    Json,
    Quiet,
}

impl OutputFormat {
    /// Output data in the configured format
    pub fn print<T: Serialize + TextOutput>(&self, data: &T) {
        match self {
            OutputFormat::Text => data.print_text(),
            OutputFormat::Json => {
                if let Ok(json) = serde_json::to_string_pretty(data) {
                    println!("{}", json);
                }
            }
            OutputFormat::Quiet => {
                // Only output errors (via Result), not data
            }
        }
    }

    /// Check if this is quiet mode
    pub fn is_quiet(&self) -> bool {
        matches!(self, OutputFormat::Quiet)
    }

    /// Check if this is JSON mode
    pub fn is_json(&self) -> bool {
        matches!(self, OutputFormat::Json)
    }
}

/// Trait for types that can be output as text
pub trait TextOutput {
    fn print_text(&self);
}

// ─────────────────────────────────────────────────────────────────────────────
// Status output types
// ─────────────────────────────────────────────────────────────────────────────

/// GitLab instance status
#[derive(Debug, Serialize)]
pub struct StatusOutput {
    pub connected: bool,
    pub gitlab_url: String,
    pub gitlab_version: Option<String>,
    pub current_user: Option<UserInfo>,
    pub users: Vec<UserInfo>,
    pub projects: ProjectStats,
    pub runners: RunnerStats,
}

#[derive(Debug, Serialize)]
pub struct UserInfo {
    pub id: u64,
    pub username: String,
    pub name: Option<String>,
    pub email: Option<String>,
    pub admin: bool,
    pub state: String,
}

#[derive(Debug, Serialize)]
pub struct ProjectStats {
    pub total: usize,
    pub mirrors: usize,
}

#[derive(Debug, Serialize)]
pub struct RunnerStats {
    pub total: usize,
    pub online: usize,
    pub offline: usize,
    pub paused: usize,
}

impl TextOutput for StatusOutput {
    fn print_text(&self) {
        if self.connected {
            info!("✅ Connected to GitLab: {}", self.gitlab_url);
        } else {
            info!("❌ Failed to connect to GitLab: {}", self.gitlab_url);
            return;
        }

        if let Some(user) = &self.current_user {
            info!("   Authenticated as: {} ({})", user.username, if user.admin { "admin" } else { "user" });
        }

        info!("");
        info!("👥 Users: {}", self.users.len());
        for user in &self.users {
            let role = if user.admin { "👑" } else { "👤" };
            info!("   {} {} ({})", role, user.username, user.state);
        }

        info!("");
        info!("📦 Projects: {} ({} mirrors)", self.projects.total, self.projects.mirrors);

        info!("");
        info!("🏃 Runners: {} total", self.runners.total);
        info!("   🟢 Online: {}", self.runners.online);
        info!("   🔴 Offline: {}", self.runners.offline);
        info!("   ⏸️  Paused: {}", self.runners.paused);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mirror output types
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Serialize)]
pub struct MirrorListOutput {
    pub mirrors: Vec<MirrorInfo>,
}

#[derive(Debug, Serialize)]
pub struct MirrorInfo {
    pub id: u64,
    pub name: String,
    pub path: String,
    pub url: String,
    pub mirror_url: Option<String>,
    pub import_status: Option<String>,
}

impl TextOutput for MirrorListOutput {
    fn print_text(&self) {
        if self.mirrors.is_empty() {
            info!("  No mirrors configured");
            return;
        }

        info!("Found {} mirror(s):\n", self.mirrors.len());
        for mirror in &self.mirrors {
            info!("  📦 {}", mirror.path);
            info!("     ID: {}", mirror.id);
            info!("     URL: {}", mirror.url);
            if let Some(status) = &mirror.import_status {
                info!("     Import Status: {}", status);
            }
            info!("");
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Runner output types
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Debug, Serialize)]
pub struct RunnerListOutput {
    pub runners: Vec<RunnerInfo>,
}

#[derive(Debug, Serialize)]
pub struct RunnerInfo {
    pub id: u64,
    pub description: Option<String>,
    pub status: String,
    pub runner_type: String,
    pub tags: Vec<String>,
    pub paused: bool,
    pub online: bool,
}

impl TextOutput for RunnerListOutput {
    fn print_text(&self) {
        if self.runners.is_empty() {
            info!("  No runners found");
            return;
        }

        info!("Found {} runner(s):\n", self.runners.len());
        for runner in &self.runners {
            let status_icon = if runner.online {
                "🟢"
            } else {
                "🔴"
            };

            info!(
                "  {} {} (ID: {})",
                status_icon,
                runner.description.as_deref().unwrap_or("unnamed"),
                runner.id
            );
            info!("     Type: {}", runner.runner_type);
            if !runner.tags.is_empty() {
                info!("     Tags: {}", runner.tags.join(", "));
            }
            if runner.paused {
                info!("     ⏸️  PAUSED");
            }
            info!("");
        }
    }
}
