//! Status command - show GitLab instance status

use super::output::{OutputFormat, ProjectStats, RunnerStats, StatusOutput, UserInfo};
use autogit_core::gitlab::RunnerStatus;
use autogit_core::Result;
use tracing::info;

pub async fn run(_config_path: &str, format: OutputFormat) -> Result<()> {
    // Load config and create client
    let config = autogit_core::config::Config::from_env()?;

    let auth = match config.auth() {
        Ok(auth) => auth,
        Err(_) => {
            let output = StatusOutput {
                connected: false,
                gitlab_url: config.gitlab_url.clone(),
                gitlab_version: None,
                current_user: None,
                users: Vec::new(),
                projects: ProjectStats {
                    total: 0,
                    mirrors: 0,
                },
                runners: RunnerStats {
                    total: 0,
                    online: 0,
                    offline: 0,
                    paused: 0,
                },
            };
            format.print(&output);
            return Ok(());
        }
    };

    let client = autogit_core::gitlab::GitLabClient::builder()
        .base_url(&config.gitlab_url)?
        .auth(auth)
        .allow_insecure_localhost()
        .build()?;

    // Test connection and get current user
    let current_user = match client.current_user().await {
        Ok(user) => Some(UserInfo {
            id: user.id,
            username: user.username.clone(),
            name: Some(user.name.clone()),
            email: user.email.clone(),
            admin: user.is_admin,
            state: format!("{:?}", user.state),
        }),
        Err(e) => {
            if !format.is_json() {
                info!("❌ Connection failed: {}", e);
            }
            let output = StatusOutput {
                connected: false,
                gitlab_url: config.gitlab_url.clone(),
                gitlab_version: None,
                current_user: None,
                users: Vec::new(),
                projects: ProjectStats {
                    total: 0,
                    mirrors: 0,
                },
                runners: RunnerStats {
                    total: 0,
                    online: 0,
                    offline: 0,
                    paused: 0,
                },
            };
            format.print(&output);
            return Ok(());
        }
    };

    // Get users
    let users = client.list_users().await.unwrap_or_default();
    let user_infos: Vec<UserInfo> = users
        .iter()
        .map(|u| UserInfo {
            id: u.id,
            username: u.username.clone(),
            name: Some(u.name.clone()),
            email: u.email.clone(),
            admin: u.is_admin,
            state: format!("{:?}", u.state),
        })
        .collect();

    // Get projects
    let projects = client.list_projects().await.unwrap_or_default();
    let mirror_count = projects.iter().filter(|p| p.mirror).count();

    // Get runners
    let runners = client.list_runners().await.unwrap_or_default();
    let runner_stats = RunnerStats {
        total: runners.len(),
        online: runners
            .iter()
            .filter(|r| matches!(r.status, RunnerStatus::Online))
            .count(),
        offline: runners
            .iter()
            .filter(|r| matches!(r.status, RunnerStatus::Offline))
            .count(),
        paused: runners.iter().filter(|r| r.paused).count(),
    };

    let output = StatusOutput {
        connected: true,
        gitlab_url: config.gitlab_url.clone(),
        gitlab_version: None, // Would need version endpoint
        current_user,
        users: user_infos,
        projects: ProjectStats {
            total: projects.len(),
            mirrors: mirror_count,
        },
        runners: runner_stats,
    };

    format.print(&output);
    Ok(())
}
